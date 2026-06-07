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

// ── Module color shortcuts ────────────────────────────────────────────────────
const _mc  = AndroidTheme.assetsPrimary;
const _mcl = AndroidTheme.assetsPrimaryLight;

// ── Screen ─────────────────────────────────────────────────────────────────────
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  final List<AssetFolder> _trail = [];

  AssetFolder? get _current => _trail.isEmpty ? null : _trail.last;

  void _enterFolder(AssetFolder folder) {
    setState(() => _trail.add(folder));
    ref.read(selectedFolderProvider.notifier).state = folder;
  }

  void _navigateTo(int trailIndex) {
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
      backgroundColor: Theme.of(context).colorScheme.surface,      appBar: AppBar(
        title: Text('Assets',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20)),
        leading: _current == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _navigateTo(_trail.length - 2),
              ),
        actions: [
          // Show delete folder button when inside a folder
          if (_current != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete this folder',
              onPressed: () => _confirmDeleteFolder(context, _current!),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showAddOptions(context),
          backgroundColor: _mc,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_trail.isNotEmpty)
            _BreadcrumbBar(
              trail: _trail,
              onTap: (i) => _navigateTo(i),
              onRoot: () => _navigateTo(-1),
            ),
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
                            onDelete: () =>
                                _confirmDeleteFolder(context, f),
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

  // ── Folder delete with tree preview ────────────────────────────────────────
  Future<void> _confirmDeleteFolder(
      BuildContext context, AssetFolder folder) async {
    // Load folder contents for preview
    final db = await ref.read(assetActionsProvider.future);
    // We need children — read directly from providers
    final allFolders =
        ref.read(folderListProvider).valueOrNull ?? [];
    final allAssets =
        ref.read(assetListProvider).valueOrNull ?? [];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => _DeleteFolderDialog(
        folder: folder,
        allFolders: allFolders,
        allAssets: allAssets,
        onConfirm: () async {
          Navigator.of(dialogCtx).pop();
          await _deleteFolderCascade(folder, allFolders, allAssets);
          // If we deleted the current folder, pop trail
          if (_current?.id == folder.id) {
            _navigateTo(_trail.length - 2);
          }
        },
      ),
    );
  }

  /// Recursively deletes folder records and asset references
  /// from the database only. Original device files are NOT touched.
  Future<void> _deleteFolderCascade(
    AssetFolder folder,
    List<AssetFolder> allFolders,
    List<Asset> allAssets,
  ) async {
    final actions = await ref.read(assetActionsProvider.future);

    // Delete direct assets in this folder
    final directAssets =
        allAssets.where((a) => a.folderId == folder.id).toList();
    for (final a in directAssets) {
      await actions.deleteAsset(a);
    }

    // Recurse into child folders
    final children =
        allFolders.where((f) => f.parentId == folder.id).toList();
    for (final child in children) {
      await _deleteFolderCascade(child, allFolders, allAssets);
    }

    // Delete the folder record itself
    await actions.deleteFolder(folder);
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark ? _mc.withValues(alpha: 0.16) : _mcl),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      const Icon(Icons.create_new_folder_outlined, color: _mc),
                ),
                title: Text('Create Folder',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showFolderDialog(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark ? _mc.withValues(alpha: 0.16) : _mcl),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.upload_file_rounded, color: _mc),
                ),
                title: Text('Upload File',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600)),
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
          decoration:
              const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _mc),
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
            child: const Text('Create'),
          ),
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

    // Store original path only — no file duplication
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
    if (['pdf', 'doc', 'docx', 'txt', 'csv'].contains(ext))
      return 'document';
    return 'other';
  }
}

// ── Delete folder confirmation dialog with tree ────────────────────────────────
class _DeleteFolderDialog extends StatelessWidget {
  final AssetFolder folder;
  final List<AssetFolder> allFolders;
  final List<Asset> allAssets;
  final VoidCallback onConfirm;

  const _DeleteFolderDialog({
    required this.folder,
    required this.allFolders,
    required this.allAssets,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Folder?'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'Folder: '),
                    TextSpan(
                      text: folder.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only app references are deleted. Your original device files are kept.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              Text('Contents:',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              _FolderTree(
                  folder: folder,
                  allFolders: allFolders,
                  allAssets: allAssets,
                  depth: 0),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: onConfirm,
          child: const Text('Delete Folder'),
        ),
      ],
    );
  }
}

// ── Tree widget for folder preview ────────────────────────────────────────────
class _FolderTree extends StatelessWidget {
  final AssetFolder folder;
  final List<AssetFolder> allFolders;
  final List<Asset> allAssets;
  final int depth;

  const _FolderTree({
    required this.folder,
    required this.allFolders,
    required this.allAssets,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final indent = depth * 16.0;
    final children =
        allFolders.where((f) => f.parentId == folder.id).toList();
    final assets =
        allAssets.where((a) => a.folderId == folder.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder row
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(children: [
            const Icon(Icons.folder_rounded,
                size: 16, color: _mc),
            const SizedBox(width: 6),
            Text(folder.name,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
        // Assets
        ...assets.map((a) => Padding(
              padding: EdgeInsets.only(left: indent + 20.0, top: 4),
              child: Row(children: [
                Icon(_iconFor(a), size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(a.title,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            )),
        // Child folders (recursive)
        ...children.map((c) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _FolderTree(
                  folder: c,
                  allFolders: allFolders,
                  allAssets: allAssets,
                  depth: depth + 1),
            )),
      ],
    );
  }

  static IconData _iconFor(Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    if (e.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (e.endsWith('.jpg') ||
        e.endsWith('.jpeg') ||
        e.endsWith('.png')) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

// ── Breadcrumb bar ─────────────────────────────────────────────────────────────
class _BreadcrumbBar extends StatelessWidget {
  final List<AssetFolder> trail;
  final void Function(int) onTap;
  final VoidCallback onRoot;

  const _BreadcrumbBar(
      {required this.trail, required this.onTap, required this.onRoot});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardTheme.color!,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: onRoot,
              child: Row(children: [
                const Icon(Icons.folder_open_rounded,
                    size: 16, color: _mc),
                const SizedBox(width: 4),
                Text('Assets',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _mc)),
              ]),
            ),
            ...List.generate(trail.length, (i) {
              final f = trail[i];
              final isLast = i == trail.length - 1;
              return Row(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 16, color: Theme.of(context).hintColor),
                ),
                GestureDetector(
                  onTap: isLast ? null : () => onTap(i),
                  child: Text(f.name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isLast
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isLast
                              ? Theme.of(context).colorScheme.onSurface
                              : _mc)),
                ),
              ]);
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
        child: Column(children: [
          Icon(Icons.folder_open_rounded,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No files or folders here yet',
              style: GoogleFonts.inter(
                  color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

// ── Folder tile ────────────────────────────────────────────────────────────────
class _FolderTile extends ConsumerWidget {
  final AssetFolder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _FolderTile(
      {required this.folder,
      required this.onTap,
      required this.onDelete});

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
              color: (Theme.of(context).brightness == Brightness.dark ? _mc.withValues(alpha: 0.16) : _mcl),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.folder_rounded, color: _mc, size: 22),
        ),
        title: Text(folder.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: folder.description != null
            ? Text(folder.description!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: Theme.of(context).hintColor),
              tooltip: 'Delete folder',
              onPressed: onDelete,
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor),
          ],
        ),
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
              color: _bgColor(context, asset),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(_iconFor(asset),
              color: _iconColor(context, asset), size: 22),
        ),
        title: Text(asset.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          asset.filePath?.split('/').last ?? asset.type,
          style: GoogleFonts.inter(
              fontSize: 12, color: Theme.of(context).hintColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'delete') {
              final ok = await _confirmDelete(context, asset);
              if (ok == true) {
                final a =
                    await ref.read(assetActionsProvider.future);
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
    if (e.endsWith('.jpg') || e.endsWith('.jpeg') || e.endsWith('.png'))
      return Icons.image_rounded;
    if (e.endsWith('.doc') || e.endsWith('.docx'))
      return Icons.description_rounded;
    if (e.endsWith('.xls') || e.endsWith('.xlsx'))
      return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  static Color _iconColor(BuildContext context, Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    if (e.endsWith('.pdf')) return Colors.red.shade700;
    if (e.endsWith('.jpg') || e.endsWith('.jpeg') || e.endsWith('.png'))
      return Colors.blue.shade700;
    if (e.endsWith('.doc') || e.endsWith('.docx'))
      return Colors.blue.shade600;
    if (e.endsWith('.xls') || e.endsWith('.xlsx'))
      return Colors.green.shade700;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color _bgColor(BuildContext context, Asset a) {
    final e = (a.filePath ?? a.title).toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color tint(Color color) => isDark
        ? color.withValues(alpha: 0.16)
        : color.withValues(alpha: 0.10);
    if (e.endsWith('.pdf')) return tint(Colors.red);
    if (e.endsWith('.jpg') || e.endsWith('.jpeg') || e.endsWith('.png'))
      return tint(Colors.blue);
    if (e.endsWith('.doc') || e.endsWith('.docx')) return tint(Colors.blue);
    if (e.endsWith('.xls') || e.endsWith('.xlsx')) return tint(Colors.green);
    return Theme.of(context).colorScheme.surface;
  }

  /// Open file — never produce a blank/black screen.
  void _openFile(BuildContext context, Asset a) {
    final path = a.filePath;

    // Guard: no path stored
    if (path == null || path.isEmpty) {
      _snack(context, 'No file path stored for this asset.');
      return;
    }

    // Guard: file missing from device
    try {
      if (!File(path).existsSync()) {
        _snack(context,
            'This file was moved or removed from device',
            warn: true);
        return;
      }
    } catch (_) {
      _snack(context, 'Unable to open this file', warn: true);
      return;
    }

    final lower = path.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    final isImg = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (isPdf || isImg) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              _FileViewerPage(path: path, name: a.title),
        ),
      );
    } else {
      _launchExternal(context, path);
    }
  }

  Future<void> _launchExternal(BuildContext context, String path) async {
    try {
      final uri = Uri.file(path);
      final ok  = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(context,
            'Cannot preview this file. Open with another application?');
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Unable to open this file', warn: true);
      }
    }
  }

  void _snack(BuildContext context, String msg, {bool warn = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: warn ? Colors.orange : null));
  }

  Future<bool?> _confirmDelete(BuildContext context, Asset a) =>
      showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete file reference?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${a.title}"',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Only the app reference is deleted. The original file on your device is not affected.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red),
                child: const Text('Delete Reference')),
          ],
        ),
      );
}

// ── File viewer ────────────────────────────────────────────────────────────────
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

    Widget body;
    if (isPdf) {
      body = SfPdfViewer.file(File(path));
    } else if (isImage) {
      body = InteractiveViewer(
          child: Center(
              child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _broken(context),
      )));
    } else {
      body = _broken(context);
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(name,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: body,
    );
  }

  Widget _broken(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('File not available or moved',
              style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}