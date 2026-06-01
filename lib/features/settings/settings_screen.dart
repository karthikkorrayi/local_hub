import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/backup/backup_provider.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);
    final notifier = ref.read(backupProvider.notifier);

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text('Settings & Backup',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('GOOGLE DRIVE BACKUP',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AndroidTheme.textTertiary, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(state.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                        color: state.isSignedIn ? AndroidTheme.primary : AndroidTheme.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      state.isSignedIn ? 'Connected to Google Drive' : 'Not connected',
                      style: GoogleFonts.inter(
                        color: state.isSignedIn ? AndroidTheme.primary : AndroidTheme.textTertiary,
                        fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!state.isSignedIn)
                  FilledButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Connect Google Account'),
                    onPressed: state.isLoading ? null : () => notifier.signIn(),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Disconnect', style: TextStyle(color: Colors.red)),
                    onPressed: () => notifier.signOut(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.backup),
                        label: const Text('Backup Now'),
                        onPressed: state.isLoading ? null : () => notifier.backup(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore'),
                        onPressed: state.isLoading ? null : () => _confirmRestore(context, notifier),
                      ),
                    ),
                  ],
                ),
                if (state.isLoading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(color: AndroidTheme.primary,
                      backgroundColor: AndroidTheme.primaryLight),
                ],
                if (state.lastResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: state.lastResult!.success ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.lastResult!.success ? Icons.check_circle_outline : Icons.error_outline,
                          color: state.lastResult!.success ? Colors.green : Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.lastResult!.message,
                              style: GoogleFonts.inter(
                                color: state.lastResult!.success ? Colors.green.shade800 : Colors.red.shade800,
                                fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BACKUP LOG',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AndroidTheme.textTertiary, letterSpacing: 0.8)),
              if (state.log.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearLog(context, notifier),
                  child: Text('Clear log',
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          state.log.isEmpty
              ? AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Text('No backup history yet.',
                      style: GoogleFonts.inter(color: AndroidTheme.textTertiary)))
              : AppCard(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.log.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final entry = state.log[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.action == 'backup' ? Icons.backup : Icons.restore,
                          color: entry.success ? AndroidTheme.primary : Colors.red, size: 20),
                        title: Text(
                          '${entry.action[0].toUpperCase()}${entry.action.substring(1)} — ${entry.success ? 'Success' : 'Failed'}',
                          style: GoogleFonts.inter(fontSize: 13)),
                        subtitle: Text(
                          '${_formatDate(entry.timestamp)}  •  ${entry.message}',
                          style: GoogleFonts.inter(fontSize: 11),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _confirmRestore(BuildContext context, BackupNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text('This will replace your local data with the Drive backup. Restart the app after restore.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.of(dialogContext).pop(); notifier.restore(); },
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
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
        content: const Text('All log entries will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.of(dialogContext).pop(); notifier.clearLog(); },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}