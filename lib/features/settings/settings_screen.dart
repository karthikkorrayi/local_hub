import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/backup/backup_provider.dart';
import '../../core/theme/android_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState    = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);
    final themeMode      = ref.watch(themeProvider);
    final themeNotifier  = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── THEME SECTION ────────────────────────────────────────────────────
          _SectionLabel('APPEARANCE'),
          AppCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final selected = themeMode == mode;
                return RadioListTile<AppThemeMode>(
                  value: mode,
                  groupValue: themeMode,
                  activeColor: AndroidTheme.primary,
                  title: Row(children: [
                    Icon(mode.icon,
                        size: 18,
                        color: selected
                            ? AndroidTheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text(mode.label,
                        style: GoogleFonts.inter(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 15,
                        )),
                  ]),
                  onChanged: (v) {
                    if (v != null) themeNotifier.set(v);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── BACKUP SECTION ───────────────────────────────────────────────────
          _SectionLabel('GOOGLE DRIVE BACKUP'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(
                    backupState.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                    color: backupState.isSignedIn
                        ? AndroidTheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    backupState.isSignedIn
                        ? 'Connected to Google Drive'
                        : 'Not connected',
                    style: GoogleFonts.inter(
                      color: backupState.isSignedIn
                          ? AndroidTheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500, fontSize: 14)),
                ]),
                const SizedBox(height: 16),
                if (!backupState.isSignedIn)
                  FilledButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Connect Google Account'),
                    onPressed: backupState.isLoading
                        ? null
                        : () => backupNotifier.signIn())
                else
                  TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Disconnect',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => backupNotifier.signOut()),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.backup),
                      label: const Text('Backup Now'),
                      onPressed: backupState.isLoading
                          ? null
                          : () => backupNotifier.backup())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                      onPressed: backupState.isLoading
                          ? null
                          : () => _confirmRestore(context, backupNotifier))),
                ]),
                if (backupState.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (backupState.lastResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: backupState.lastResult!.success
                          ? Colors.green.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10)
                          : Colors.red.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(
                        backupState.lastResult!.success
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: backupState.lastResult!.success
                            ? Colors.green
                            : Colors.red,
                        size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(backupState.lastResult!.message,
                            style: GoogleFonts.inter(
                              color: backupState.lastResult!.success
                                  ? Colors.green.shade700
                                  : Theme.of(context).colorScheme.error,
                              fontSize: 13))),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── BACKUP LOG ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel('BACKUP LOG'),
              if (backupState.log.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearLog(context, backupNotifier),
                  child: Text('Clear log',
                      style: GoogleFonts.inter(
                          color: Colors.red, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          backupState.log.isEmpty
              ? AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Text('No backup history yet.',
                      style: GoogleFonts.inter(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)))
              : AppCard(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: backupState.log.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final entry = backupState.log[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.action == 'backup'
                              ? Icons.backup
                              : Icons.restore,
                          color: entry.success
                              ? AndroidTheme.primary
                              : Colors.red,
                          size: 20),
                        title: Text(
                          '${entry.action[0].toUpperCase()}${entry.action.substring(1)} — ${entry.success ? 'Success' : 'Failed'}',
                          style: GoogleFonts.inter(fontSize: 13)),
                        subtitle: Text(
                          '${_fmtDate(entry.timestamp)}  •  ${entry.message}',
                          style: GoogleFonts.inter(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 32),
          Text('MyNest v1.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  void _confirmRestore(BuildContext context, BackupNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text(
            'This will replace your local data with the Drive backup. Restart the app after restore.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () { Navigator.of(ctx).pop(); notifier.restore(); },
              child: const Text('Restore',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _confirmClearLog(BuildContext context, BackupNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear backup log?'),
        content: const Text('All log entries will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () { Navigator.of(ctx).pop(); notifier.clearLog(); },
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8)),
      );
}