import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backup/backup_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);
    final notifier = ref.read(backupProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Google Account section ──────────────────────────────────────
          const _SectionHeader('Google Drive Backup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.isSignedIn
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: state.isSignedIn
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isSignedIn
                            ? 'Connected to Google Drive'
                            : 'Not connected',
                        style: TextStyle(
                          color: state.isSignedIn
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!state.isSignedIn)
                    FilledButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Connect Google Account'),
                      onPressed: state.isLoading
                          ? null
                          : () => notifier.signIn(),
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Disconnect',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => notifier.signOut(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.backup),
                          label: const Text('Backup Now'),
                          onPressed: state.isLoading
                              ? null
                              : () => notifier.backup(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore'),
                          onPressed: state.isLoading
                              ? null
                              : () => _confirmRestore(context, notifier),
                        ),
                      ),
                    ],
                  ),
                  if (state.isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (state.lastResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: state.lastResult!.success
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.lastResult!.success
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: state.lastResult!.success
                                ? Colors.green
                                : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.lastResult!.message,
                              style: TextStyle(
                                color: state.lastResult!.success
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Backup log section ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader('Backup Log'),
              if (state.log.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearLog(context, notifier),
                  child: const Text('Clear log',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          state.log.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No backup history yet.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.log.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final entry = state.log[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.action == 'backup'
                              ? Icons.backup
                              : Icons.restore,
                          color: entry.success
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        title: Text(
                          '${entry.action[0].toUpperCase()}${entry.action.substring(1)} — ${entry.success ? 'Success' : 'Failed'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '${_formatDate(entry.timestamp)}  •  ${entry.message}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmRestore(BuildContext context, BackupNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text(
            'This will replace your current local data with the backup from Google Drive. This cannot be undone.\n\nThe app will need to be restarted after restore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.restore();
            },
            child: const Text('Restore',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearLog(BuildContext context, BackupNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear backup log?'),
        content: const Text('All log entries will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.clearLog();
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}