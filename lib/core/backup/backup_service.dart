import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_credentials.dart';

// ── Scopes ─────────────────────────────────────────────────────────────────────
const _kScopes = [drive.DriveApi.driveFileScope];
const _kBackupFileName = 'local_hub_backup.db';
const _kLogFileName = 'local_hub_backup.log';
const _kFolderName = 'LocalHubBackup';

// ── Result type ────────────────────────────────────────────────────────────────
class BackupResult {
  final bool success;
  final String message;
  final DateTime timestamp;

  const BackupResult({
    required this.success,
    required this.message,
    required this.timestamp,
  });
}

// ── Backup log entry ───────────────────────────────────────────────────────────
class BackupLogEntry {
  final DateTime timestamp;
  final String action; // 'backup' | 'restore'
  final bool success;
  final String message;

  const BackupLogEntry({
    required this.timestamp,
    required this.action,
    required this.success,
    required this.message,
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
      // Format: [timestamp] SUCCESS | action | message
      final rest = line.substring(tsEnd + 2); // skip '] '
      final parts = rest.split(' | ');
      return BackupLogEntry(
        timestamp: DateTime.parse(ts),
        action: parts.length > 1 ? parts[1].trim() : 'unknown',
        success: parts[0].trim() == 'SUCCESS',
        message: parts.length > 2 ? parts[2].trim() : '',
      );
    } catch (_) {
      return BackupLogEntry(
        timestamp: DateTime.now(),
        action: 'unknown',
        success: false,
        message: line,
      );
    }
  }
}

// ── Backup Service ─────────────────────────────────────────────────────────────
class BackupService {
  AutoRefreshingAuthClient? _authClient;

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<bool> signIn() async {
    try {
      final id = ClientId(kGoogleClientId, kGoogleClientSecret);
      _authClient = await clientViaUserConsent(
        id,
        _kScopes,
        (url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('BackupService.signIn error: $e');
      return false;
    }
  }

  void signOut() {
    _authClient?.close();
    _authClient = null;
  }

  bool get isSignedIn => _authClient != null;

  // ── Get or create backup folder on Drive ──────────────────────────────────
  Future<String?> _getOrCreateFolder(drive.DriveApi driveApi) async {
    try {
      final response = await driveApi.files.list(
        q: "name='$_kFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }
      // Create folder
      final folder = drive.File()
        ..name = _kFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await driveApi.files.create(folder);
      return created.id;
    } catch (e) {
      debugPrint('BackupService._getOrCreateFolder error: $e');
      return null;
    }
  }

  // ── Find existing file in folder ──────────────────────────────────────────
  Future<String?> _findFile(
      drive.DriveApi driveApi, String folderId, String fileName) async {
    try {
      final response = await driveApi.files.list(
        q: "name='$fileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('BackupService._findFile error: $e');
      return null;
    }
  }

  // ── Get local DB path ─────────────────────────────────────────────────────
  Future<String> _getDbPath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'local_hub.db');
  }

  Future<String> getDatabasesPath() async {
    // Inside the macOS sandbox, HOME already points to the container root
    final containerHome = Platform.environment['HOME'] ?? '';
    return '$containerHome/.dart_tool/sqflite_common_ffi/databases';
  }

  // ── Backup ────────────────────────────────────────────────────────────────
  Future<BackupResult> backup() async {
    if (_authClient == null) {
      final signedIn = await signIn();
      if (!signedIn) {
        return BackupResult(
          success: false,
          message: 'Google sign-in failed or was cancelled',
          timestamp: DateTime.now(),
        );
      }
    }

    try {
      final driveApi = drive.DriveApi(_authClient!);
      final folderId = await _getOrCreateFolder(driveApi);
      if (folderId == null) throw Exception('Could not create Drive folder');

      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Local database file not found at $dbPath');
      }

      final existingId = await _findFile(driveApi, folderId, _kBackupFileName);
      final fileMetadata = drive.File()
        ..name = _kBackupFileName
        ..parents = existingId == null ? [folderId] : null;

      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
        contentType: 'application/octet-stream',
      );

      if (existingId != null) {
        await driveApi.files.update(fileMetadata, existingId, uploadMedia: media);
      } else {
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }

      final result = BackupResult(
        success: true,
        message: 'Backed up ${(await dbFile.length() / 1024).toStringAsFixed(1)} KB',
        timestamp: DateTime.now(),
      );
      await _appendLog(result, 'backup');
      return result;
    } catch (e) {
      final result = BackupResult(
        success: false,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      await _appendLog(result, 'backup');
      return result;
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────
  Future<BackupResult> restore() async {
    if (_authClient == null) {
      final signedIn = await signIn();
      if (!signedIn) {
        return BackupResult(
          success: false,
          message: 'Google sign-in failed or was cancelled',
          timestamp: DateTime.now(),
        );
      }
    }

    try {
      final driveApi = drive.DriveApi(_authClient!);
      final folderId = await _getOrCreateFolder(driveApi);
      if (folderId == null) throw Exception('Could not access Drive folder');

      final fileId = await _findFile(driveApi, folderId, _kBackupFileName);
      if (fileId == null) throw Exception('No backup found on Drive');

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      final sink = dbFile.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      final result = BackupResult(
        success: true,
        message: 'Restored from Drive successfully — restart the app',
        timestamp: DateTime.now(),
      );
      await _appendLog(result, 'restore');
      return result;
    } catch (e) {
      final result = BackupResult(
        success: false,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      await _appendLog(result, 'restore');
      return result;
    }
  }

  // ── Log ───────────────────────────────────────────────────────────────────
  Future<void> _appendLog(BackupResult result, String action) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      final entry = BackupLogEntry(
        timestamp: result.timestamp,
        action: action,
        success: result.success,
        message: result.message,
      );
      await logFile.writeAsString(
        '${entry.toLogLine()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('BackupService._appendLog error: $e');
    }
  }

  Future<List<BackupLogEntry>> readLog() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      if (!await logFile.exists()) return [];
      final lines = await logFile.readAsLines();
      return lines
          .where((l) => l.trim().isNotEmpty)
          .map(BackupLogEntry.fromLogLine)
          .toList()
          .reversed
          .toList(); // newest first
    } catch (e) {
      debugPrint('BackupService.readLog error: $e');
      return [];
    }
  }

  Future<void> clearLog() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File(p.join(dir.path, _kLogFileName));
      if (await logFile.exists()) await logFile.delete();
    } catch (e) {
      debugPrint('BackupService.clearLog error: $e');
    }
  }
}