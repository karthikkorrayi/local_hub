import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_credentials.dart';

const _kBackupFileName = 'local_hub_backup.db';
const _kLogFileName    = 'local_hub_backup.log';
const _kFolderName     = 'LocalHubBackup';
const _kScopes         = [drive.DriveApi.driveFileScope];

class BackupResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  const BackupResult({required this.success, required this.message, required this.timestamp});
}

class BackupLogEntry {
  final DateTime timestamp;
  final String action;
  final bool success;
  final String message;

  const BackupLogEntry({
    required this.timestamp, required this.action,
    required this.success, required this.message,
  });

  String toLogLine() {
    final ts = timestamp.toIso8601String();
    final status = success ? 'SUCCESS' : 'FAILED';
    return '[$ts] $status | $action | $message';
  }

  static BackupLogEntry fromLogLine(String line) {
    try {
      final tsEnd = line.indexOf(']');
      final ts = line.substring(1, tsEnd);
      final rest = line.substring(tsEnd + 2);
      final parts = rest.split(' | ');
      return BackupLogEntry(
        timestamp: DateTime.parse(ts),
        action: parts.length > 1 ? parts[1].trim() : 'unknown',
        success: parts[0].trim() == 'SUCCESS',
        message: parts.length > 2 ? parts[2].trim() : '',
      );
    } catch (_) {
      return BackupLogEntry(
        timestamp: DateTime.now(), action: 'unknown',
        success: false, message: line,
      );
    }
  }
}

class BackupService {
  AutoRefreshingAuthClient? _desktopClient;

  // Android: NO clientId — reads from google-services.json automatically
  final _googleSignIn = GoogleSignIn(scopes: _kScopes);
  GoogleSignInAccount? _androidAccount;

  bool get isSignedIn => Platform.isAndroid
      ? _androidAccount != null
      : _desktopClient != null;

  Future<bool> signIn() async {
    if (Platform.isAndroid) return _signInAndroid();
    return _signInDesktop();
  }

  Future<bool> _signInAndroid() async {
    try {
      _androidAccount = await _googleSignIn.signIn();
      return _androidAccount != null;
    } catch (e) {
      debugPrint('Android sign-in error: $e');
      return false;
    }
  }

  Future<bool> _signInDesktop() async {
    try {
      final id = ClientId(kGoogleClientId, kGoogleClientSecret);
      _desktopClient = await clientViaUserConsent(id, _kScopes, (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      });
      return true;
    } catch (e) {
      debugPrint('Desktop sign-in error: $e');
      return false;
    }
  }

  void signOut() {
    if (Platform.isAndroid) {
      _googleSignIn.signOut();
      _androidAccount = null;
    } else {
      _desktopClient?.close();
      _desktopClient = null;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (Platform.isAndroid) {
      if (_androidAccount == null) return null;
      final headers = await _androidAccount!.authHeaders;
      return drive.DriveApi(_GoogleAuthClient(headers));
    } else {
      if (_desktopClient == null) return null;
      return drive.DriveApi(_desktopClient!);
    }
  }

  Future<String?> _getOrCreateFolder(drive.DriveApi api) async {
    try {
      final response = await api.files.list(
        q: "name='$_kFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive', $fields: 'files(id,name)',
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }
      final folder = drive.File()
        ..name = _kFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await api.files.create(folder);
      return created.id;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _findFile(drive.DriveApi api, String folderId, String fileName) async {
    try {
      final response = await api.files.list(
        q: "name='$fileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive', $fields: 'files(id,name)',
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDbPath() async {
    if (Platform.isAndroid) {
      final dir = await getApplicationSupportDirectory();
      return p.join(dir.parent.path, 'databases', 'local_hub.db');
    }
    final containerHome = Platform.environment['HOME'] ?? '';
    return p.join(containerHome, '.dart_tool', 'sqflite_common_ffi', 'databases', 'local_hub.db');
  }

  Future<BackupResult> backup() async {
    if (!isSignedIn) {
      final ok = await signIn();
      if (!ok) return BackupResult(success: false, message: 'Sign-in failed or was cancelled', timestamp: DateTime.now());
    }
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Could not get Drive API');
      final folderId = await _getOrCreateFolder(api);
      if (folderId == null) throw Exception('Could not create Drive folder');
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) throw Exception('Database file not found at $dbPath');
      final existingId = await _findFile(api, folderId, _kBackupFileName);
      final meta = drive.File()
        ..name = _kBackupFileName
        ..parents = existingId == null ? [folderId] : null;
      final media = drive.Media(dbFile.openRead(), await dbFile.length(), contentType: 'application/octet-stream');
      if (existingId != null) {
        await api.files.update(meta, existingId, uploadMedia: media);
      } else {
        await api.files.create(meta, uploadMedia: media);
      }
      final kb = (await dbFile.length() / 1024).toStringAsFixed(1);
      final result = BackupResult(success: true, message: 'Backed up ${kb}KB', timestamp: DateTime.now());
      await _appendLog(result, 'backup');
      return result;
    } catch (e) {
      final result = BackupResult(success: false, message: e.toString(), timestamp: DateTime.now());
      await _appendLog(result, 'backup');
      return result;
    }
  }

  Future<BackupResult> restore() async {
    if (!isSignedIn) {
      final ok = await signIn();
      if (!ok) return BackupResult(success: false, message: 'Sign-in failed or was cancelled', timestamp: DateTime.now());
    }
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Could not get Drive API');
      final folderId = await _getOrCreateFolder(api);
      if (folderId == null) throw Exception('Could not access Drive folder');
      final fileId = await _findFile(api, folderId, _kBackupFileName);
      if (fileId == null) throw Exception('No backup found on Drive');
      final response = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final dbPath = await _getDbPath();
      final sink = File(dbPath).openWrite();
      await response.stream.pipe(sink);
      await sink.close();
      final result = BackupResult(success: true, message: 'Restored successfully — restart the app', timestamp: DateTime.now());
      await _appendLog(result, 'restore');
      return result;
    } catch (e) {
      final result = BackupResult(success: false, message: e.toString(), timestamp: DateTime.now());
      await _appendLog(result, 'restore');
      return result;
    }
  }

  Future<void> _appendLog(BackupResult result, String action) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      final entry = BackupLogEntry(timestamp: result.timestamp, action: action, success: result.success, message: result.message);
      await logFile.writeAsString('${entry.toLogLine()}\n', mode: FileMode.append);
    } catch (_) {}
  }

  Future<List<BackupLogEntry>> readLog() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      if (!await logFile.exists()) return [];
      final lines = await logFile.readAsLines();
      return lines.where((l) => l.trim().isNotEmpty).map(BackupLogEntry.fromLogLine).toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearLog() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      if (await logFile.exists()) await logFile.delete();
    } catch (_) {}
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}