import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_folder.dart';
import 'asset_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  // Breadcrumb trail: list of folders from root to current
  final List<AssetFolder> _trail = [];

  AssetFolder? get _current => _trail.isEmpty ? null : _trail.last;

  void _enterFolder(AssetFolder folder) {
    setState(() => _trail.add(folder));
    ref.read(selectedFolderProvider.notifier).state = folder;
  }

  void _navigateTo(int trailIndex) {
    // trailIndex == -1 means root
    setState(() {
      if (trailIndex < 0) {
        _trail.clear();
      } else {
        _trail.removeRange(trailIndex + 1, _trail.length);
      }
    });
    ref.read(selectedFolderProvider.notifier).state =
        _trail.isEmpty ? null : _trail.last;
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(childFolderListProvider).valueOrNull ?? [];
    final assets  = ref.watch(filteredAssetListProvider);

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text('Assets',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20)),
        leading: _current == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _navigateTo(_trail.length - 2),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showAddOptions(context),
          backgroundColor: AndroidTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb navigation ─────────────────────────────────────
          if (_trail.isNotEmpty)
            _BreadcrumbBar(
              trail: _trail,
              onTap: (index) => _navigateTo(index),
              onRoot: () => _navigateTo(-1),
            ),
          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: folders.isEmpty && assets.isEmpty
                ? const _EmptyAssets()
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      ...folders.map((f) => _FolderTile(
                            folder: f,
                            onTap: () => _enterFolder(f),
                          )),
                      ...assets
                          .map((a) => _AssetTile(asset: a)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined,
                    color: AndroidTheme.primary),
                title: Text('Create Folder',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showFolderDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_rounded,
                    color: AndroidTheme.primary),
                title: Text('Upload File',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFile(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderDialog(BuildContext context) {
    final name = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final a = await ref.read(assetActionsProvider.future);
                await a.addFolder(AssetFolder(
                  id:        const Uuid().v4(),
                  name:      name.text.trim(),
                  icon:      'folder',
                  parentId:  _current?.id,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                ));
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _uploadFile(BuildContext context) async {
    const group = XTypeGroup(label: 'Files', extensions: [
      'jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx',
      'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv',
    ]);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;

    final ext = file.name.split('.').last.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch;
    final a   = await ref.read(assetActionsProvider.future);

    // Store original file path — no duplication
    await a.addAsset(Asset(
      id:        const Uuid().v4(),
      folderId:  _current?.id ?? 'root',
      title:     file.name,
      type:      _typeOf(ext),
      filePath:  file.path,
      createdAt: now,
      updatedAt: now,
    ));
  }

  static String _typeOf(String ext) {
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return 'image';
    if (['pdf', 'doc', 'docx', 'txt', 'csv'].contains(ext)) return 'document';
    return 'other';
  }
}

// ── Breadcrumb bar ─────────────────────────────────────────────────────────────
class _BreadcrumbBar extends StatelessWidget {
  final List<AssetFolder> trail;
  final void Function(int index) onTap;
  final VoidCallback onRoot;

  const _BreadcrumbBar(
      {required this.trail, required this.onTap, required this.onRoot});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AndroidTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Root crumb
            GestureDetector(
              onTap: onRoot,
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded,
                      size: 16, color: AndroidTheme.primary),
                  const SizedBox(width: 4),
                  Text('Assets',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AndroidTheme.primary)),
                ],
              ),
            ),
            ...List.generate(trail.length, (i) {
              final folder = trail[i];
              final isLast = i == trail.length - 1;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 16, color: AndroidTheme.textTertiary),
                  ),
                  GestureDetector(
                    onTap: isLast ? null : () => onTap(i),
                    child: Text(
                      folder.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isLast
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isLast
                            ? AndroidTheme.textPrimary
                            : AndroidTheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyAssets extends StatelessWidget {
  const _EmptyAssets();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 90),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No files or folders here yet',
                style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ── Folder tile ────────────────────────────────────────────────────────────────
class _FolderTile extends ConsumerWidget {
  final AssetFolder folder;
  final VoidCallback onTap;
  const _FolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: onTap,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AndroidTheme.primaryLight,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.folder_rounded,
              color: AndroidTheme.primary, size: 22),
        ),
        title: Text(folder.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: folder.description != null
            ? Text(folder.description!,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AndroidTheme.textTertiary))
            : null,
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AndroidTheme.textTertiary),
      ),
    );
  }
}

// ── Asset tile ─────────────────────────────────────────────────────────────────
class _AssetTile extends ConsumerWidget {
  final Asset asset;
  const _AssetTile({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => _openFile(context, asset),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: _bgColor(asset),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(_iconFor(asset), color: _iconColor(asset), size: 22),
        ),
        title: Text(asset.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          asset.filePath?.split('/').last ?? asset.type,
          style: GoogleFonts.inter(
              fontSize: 12, color: AndroidTheme.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'delete') {
              final ok = await _confirmDelete(context, asset);
              if (ok == true) {
                final a = await ref.read(assetActionsProvider.future);
                await a.deleteAsset(asset);
              }
            } else {
              _openFile(context, asset);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    if (e.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (e.endsWith('.jpg') ||
        e.endsWith('.jpeg') ||
        e.endsWith('.png') ||
        e.endsWith('.webp')) return Icons.image_rounded;
    if (e.endsWith('.doc') || e.endsWith('.docx'))
      return Icons.description_rounded;
    if (e.endsWith('.xls') || e.endsWith('.xlsx'))
      return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  static Color _iconColor(Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    if (e.endsWith('.pdf')) return Colors.red.shade700;
    if (e.endsWith('.jpg') ||
        e.endsWith('.jpeg') ||
        e.endsWith('.png')) return Colors.blue.shade700;
    if (e.endsWith('.doc') || e.endsWith('.docx')) return Colors.blue.shade600;
    if (e.endsWith('.xls') || e.endsWith('.xlsx')) return Colors.green.shade700;
    return AndroidTheme.textSecondary;
  }

  static Color _bgColor(Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    if (e.endsWith('.pdf')) return Colors.red.shade50;
    if (e.endsWith('.jpg') ||
        e.endsWith('.jpeg') ||
        e.endsWith('.png')) return Colors.blue.shade50;
    if (e.endsWith('.doc') || e.endsWith('.docx')) return Colors.blue.shade50;
    if (e.endsWith('.xls') || e.endsWith('.xlsx')) return Colors.green.shade50;
    return AndroidTheme.surface;
  }

  void _openFile(BuildContext context, Asset a) {
    final path = a.filePath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No file path stored for this asset.')));
      return;
    }
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File not available or moved'),
          backgroundColor: Colors.orange));
      return;
    }

    final lower = path.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (isPdf || isImage) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _FileViewerPage(path: path, name: a.title)));
    } else {
      // Hand off to external app — never show blank screen
      _launchExternal(context, path);
    }
  }

  Future<void> _launchExternal(BuildContext context, String path) async {
    try {
      final uri  = Uri.file(path);
      final ok   = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Cannot preview this file. Open with another application?')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('File not available or moved'),
            backgroundColor: Colors.orange));
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, Asset a) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete file?'),
          content: Text('Remove "${a.title}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
}

// ── File viewer (PDF + image) ──────────────────────────────────────────────────
class _FileViewerPage extends StatelessWidget {
  final String path;
  final String name;
  const _FileViewerPage({required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final lower  = path.toLowerCase();
    final isPdf  = lower.endsWith('.pdf');
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    return Scaffold(
      appBar: AppBar(title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: isPdf
          ? SfPdfViewer.file(File(path))
          : isImage
              ? InteractiveViewer(
                  child: Center(
                      child: Image.file(File(path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _missingFile(context))))
              : _missingFile(context),
    );
  }

  Widget _missingFile(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('File not available or moved',
              style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}