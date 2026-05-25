import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backup_service.dart';

// Singleton service instance
final backupServiceProvider = Provider<BackupService>((ref) {
  final service = BackupService();
  ref.onDispose(service.signOut);
  return service;
});

// Backup state
class BackupState {
  final bool isLoading;
  final bool isSignedIn;
  final BackupResult? lastResult;
  final List<BackupLogEntry> log;

  const BackupState({
    this.isLoading = false,
    this.isSignedIn = false,
    this.lastResult = null,
    this.log = const [],
  });

  BackupState copyWith({
    bool? isLoading,
    bool? isSignedIn,
    BackupResult? lastResult,
    List<BackupLogEntry>? log,
  }) =>
      BackupState(
        isLoading: isLoading ?? this.isLoading,
        isSignedIn: isSignedIn ?? this.isSignedIn,
        lastResult: lastResult ?? this.lastResult,
        log: log ?? this.log,
      );
}

class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _service;

  BackupNotifier(this._service) : super(const BackupState()) {
    _loadLog();
  }

  Future<void> _loadLog() async {
    final log = await _service.readLog();
    state = state.copyWith(log: log);
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true);
    final success = await _service.signIn();
    state = state.copyWith(isLoading: false, isSignedIn: success);
  }

  void signOut() {
    _service.signOut();
    state = state.copyWith(isSignedIn: false);
  }

  Future<void> backup() async {
    state = state.copyWith(isLoading: true);
    final result = await _service.backup();
    final log = await _service.readLog();
    state = state.copyWith(
      isLoading: false,
      isSignedIn: _service.isSignedIn,
      lastResult: result,
      log: log,
    );
  }

  Future<void> restore() async {
    state = state.copyWith(isLoading: true);
    final result = await _service.restore();
    final log = await _service.readLog();
    state = state.copyWith(
      isLoading: false,
      isSignedIn: _service.isSignedIn,
      lastResult: result,
      log: log,
    );
  }

  Future<void> clearLog() async {
    await _service.clearLog();
    state = state.copyWith(log: []);
  }
}

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final service = ref.watch(backupServiceProvider);
  return BackupNotifier(service);
});