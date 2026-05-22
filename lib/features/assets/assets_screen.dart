import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_folder.dart';
import 'asset_provider.dart';

// ── Type metadata ──────────────────────────────────────────────────────────────
const _kTypes = ['document', 'image', 'credential', 'license', 'other'];
const _kTypeLabels = {
  'document':   '📄 Document',
  'image':      '🖼 Image',
  'credential': '🔑 Credential',
  'license':    '📜 License',
  'other':      '📦 Other',
};
const _kTypeColors = {
  'document':   Color(0xFF1E88E5),
  'image':      Color(0xFF43A047),
  'credential': Color(0xFFE53935),
  'license':    Color(0xFF8E24AA),
  'other':      Color(0xFF757575),
};

const _kFolderIcons = {
  'work':     '💼',
  'personal': '🏠',
  'finance':  '💰',
  'legal':    '⚖️',
  'other':    '📁',
};

// ── Screen ─────────────────────────────────────────────────────────────────────
class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            onPressed: () => _showFolderForm(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Asset',
            onPressed: () => _showAssetForm(context, ref),
          ),
        ],
      ),
      body: isWide
          ? _WideLayout(
              onEditAsset: (a) => _showAssetForm(context, ref, existing: a),
              onEditFolder: (f) => _showFolderForm(context, ref, existing: f),
            )
          : _NarrowLayout(
              onEditAsset: (a) => _showAssetForm(context, ref, existing: a),
              onEditFolder: (f) => _showFolderForm(context, ref, existing: f),
            ),
    );
  }

  void _showFolderForm(BuildContext context, WidgetRef ref,
      {AssetFolder? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FolderFormSheet(ref: ref, existing: existing),
    );
  }

  void _showAssetForm(BuildContext context, WidgetRef ref,
      {Asset? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AssetFormSheet(ref: ref, existing: existing),
    );
  }
}

// ── Wide layout ────────────────────────────────────────────────────────────────
class _WideLayout extends ConsumerWidget {
  final void Function(Asset) onEditAsset;
  final void Function(AssetFolder) onEditFolder;
  const _WideLayout({required this.onEditAsset, required this.onEditFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: _FolderPanel(onEditFolder: onEditFolder),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _AssetPanel(onEditAsset: onEditAsset),
        ),
      ],
    );
  }
}

// ── Narrow layout ──────────────────────────────────────────────────────────────
class _NarrowLayout extends ConsumerStatefulWidget {
  final void Function(Asset) onEditAsset;
  final void Function(AssetFolder) onEditFolder;
  const _NarrowLayout(
      {required this.onEditAsset, required this.onEditFolder});

  @override
  ConsumerState<_NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends ConsumerState<_NarrowLayout> {
  bool _showFolders = true;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedFolderProvider);
    final query = ref.watch(assetSearchQueryProvider);

    return Column(
      children: [
        if (_showFolders || (selected == null && query.isEmpty))
          SizedBox(
            height: 200,
            child: _FolderPanel(onEditFolder: widget.onEditFolder),
          ),
        if (selected != null || query.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Folders'),
                  onPressed: () {
                    ref.read(selectedFolderProvider.notifier).state = null;
                    ref.read(assetSearchQueryProvider.notifier).state = '';
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _AssetPanel(onEditAsset: widget.onEditAsset)),
        ],
      ],
    );
  }
}

// ── Folder panel ───────────────────────────────────────────────────────────────
class _FolderPanel extends ConsumerWidget {
  final void Function(AssetFolder) onEditFolder;
  const _FolderPanel({required this.onEditFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderListProvider);
    final selected = ref.watch(selectedFolderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search assets…',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) {
              ref.read(assetSearchQueryProvider.notifier).state = v;
              if (v.isNotEmpty) {
                ref.read(selectedFolderProvider.notifier).state = null;
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text('FOLDERS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.8)),
        ),
        Expanded(
          child: foldersAsync.when(
            data: (folders) => folders.isEmpty
                ? const Center(
                    child: Text('No folders yet',
                        style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (_, i) {
                      final f = folders[i];
                      final isSelected = selected?.id == f.id;
                      return ListTile(
                        dense: true,
                        leading: Text(
                          _kFolderIcons[f.icon] ?? '📁',
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(f.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            )),
                        selected: isSelected,
                        selectedTileColor:
                            AppTheme.primary.withValues(alpha: 0.08),
                        onTap: () {
                          ref.read(selectedFolderProvider.notifier).state = f;
                          ref.read(assetSearchQueryProvider.notifier).state = '';
                          ref.read(selectedTagProvider.notifier).state = null;
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, size: 16),
                          onPressed: () => _folderMenu(context, ref, f),
                        ),
                      );
                    },
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _folderMenu(BuildContext context, WidgetRef ref, AssetFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename folder'),
              onTap: () {
                Navigator.of(ctx).pop();
                onEditFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete folder',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteFolder(context, ref, folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFolder(
      BuildContext context, WidgetRef ref, AssetFolder folder) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
            'Delete "${folder.name}"? All assets inside will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final actions = await ref.read(assetActionsProvider.future);
              await actions.deleteFolder(folder);
              ref.read(selectedFolderProvider.notifier).state = null;
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Asset panel ────────────────────────────────────────────────────────────────
class _AssetPanel extends ConsumerWidget {
  final void Function(Asset) onEditAsset;
  const _AssetPanel({required this.onEditAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(filteredAssetListProvider);
    final query = ref.watch(assetSearchQueryProvider);
    final folder = ref.watch(selectedFolderProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    if (folder == null && query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Select a folder or search',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tag filter chips
        tagsAsync.when(
          data: (tags) => tags.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedTag == null,
                          onSelected: (_) => ref
                              .read(selectedTagProvider.notifier)
                              .state = null,
                        ),
                      ),
                      ...tags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: selectedTag == tag,
                              onSelected: (_) => ref
                                  .read(selectedTagProvider.notifier)
                                  .state = selectedTag == tag ? null : tag,
                            ),
                          )),
                    ],
                  ),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Asset list
        Expanded(
          child: assets.isEmpty
              ? const Center(
                  child: Text('No assets found',
                      style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AssetCard(
                    asset: assets[i],
                    onEdit: onEditAsset,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Asset card ─────────────────────────────────────────────────────────────────
class _AssetCard extends ConsumerWidget {
  final Asset asset;
  final void Function(Asset) onEdit;
  const _AssetCard({required this.asset, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _kTypeColors[asset.type] ?? const Color(0xFF757575);
    final hasImage = asset.imagePath != null && asset.imagePath!.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onEdit(asset),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail or type icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.file(
                        File(asset.imagePath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _typeIcon(color),
                      )
                    : _typeIcon(color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      _kTypeLabels[asset.type] ?? asset.type,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        asset.notes!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (asset.tagList.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: asset.tagList
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primary)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.grey.shade400,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.insert_drive_file_outlined, color: color, size: 28),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete asset?'),
        content: Text('Remove "${asset.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final actions = await ref.read(assetActionsProvider.future);
              await actions.deleteAsset(asset);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Folder form ────────────────────────────────────────────────────────────────
class _FolderFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final AssetFolder? existing;
  const _FolderFormSheet({required this.ref, this.existing});

  @override
  State<_FolderFormSheet> createState() => _FolderFormSheetState();
}

class _FolderFormSheetState extends State<_FolderFormSheet> {
  late final TextEditingController _name;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _icon = widget.existing?.icon ?? 'other';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final actions = await widget.ref.read(assetActionsProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;
    final folder = AssetFolder(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      icon: _icon,
      createdAt: widget.existing?.createdAt ?? now,
    );
    if (widget.existing == null) {
      await actions.addFolder(folder);
    } else {
      await actions.updateFolder(folder);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? 'New Folder' : 'Rename Folder',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Folder name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _kFolderIcons.entries.map((e) {
              final selected = _icon == e.key;
              return GestureDetector(
                onTap: () => setState(() => _icon = e.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: AppTheme.primary)
                        : null,
                  ),
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existing == null ? 'Create Folder' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ── Asset form ─────────────────────────────────────────────────────────────────
class _AssetFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final Asset? existing;
  const _AssetFormSheet({required this.ref, this.existing});

  @override
  State<_AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<_AssetFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _newTag;
  late String _type;
  late Set<String> _tags;
  String? _imagePath;
  String? _folderId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title    = TextEditingController(text: a?.title ?? '');
    _notes    = TextEditingController(text: a?.notes ?? '');
    _newTag   = TextEditingController();
    _type     = a?.type ?? 'document';
    _tags     = Set.from(a?.tagList ?? []);
    _imagePath = a?.imagePath;
    _folderId  = a?.folderId ??
        widget.ref.read(selectedFolderProvider)?.id;
  }

  @override
  void dispose() {
    _title.dispose(); _notes.dispose(); _newTag.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    if (_folderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a folder first')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = widget.existing;
    final asset = Asset(
      id:        existing?.id ?? const Uuid().v4(),
      folderId:  _folderId!,
      title:     _title.text.trim(),
      type:      _type,
      notes:     _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      imagePath: _imagePath,
      tags:      _tags.isEmpty ? null : _tags.join(','),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final actions = await widget.ref.read(assetActionsProvider.future);
    if (existing == null) {
      await actions.addAsset(asset);
    } else {
      await actions.updateAsset(asset);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final foldersAsync = widget.ref.watch(folderListProvider);
    final allTagsAsync = widget.ref.watch(allTagsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit Asset' : 'New Asset',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Folder picker
            foldersAsync.when(
              data: (folders) => DropdownButtonFormField<String>(
                value: _folderId,
                decoration: const InputDecoration(
                  labelText: 'Folder *',
                  border: OutlineInputBorder(),
                ),
                items: folders
                    .map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(
                              '${_kFolderIcons[f.icon] ?? '📁'} ${f.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _folderId = v),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _kTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_kTypeLabels[t]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes / Details',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imagePath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _imagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 28, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text('Attach image (optional)',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Tags
            const Text('Tags',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Existing tags from DB as suggestions
            allTagsAsync.when(
              data: (allTags) {
                final suggestions = allTags
                    .where((t) => !_tags.contains(t))
                    .toList();
                return suggestions.isEmpty
                    ? const SizedBox.shrink()
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: suggestions
                            .map((tag) => ActionChip(
                                  label: Text(tag),
                                  avatar: const Icon(Icons.add, size: 14),
                                  onPressed: () =>
                                      setState(() => _tags.add(tag)),
                                ))
                            .toList(),
                      );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            // Selected tags
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          backgroundColor: AppTheme.primary
                              .withValues(alpha: 0.1),
                          labelStyle:
                              TextStyle(color: AppTheme.primary),
                        ))
                    .toList(),
              ),
            // Add new tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTag,
                    decoration: const InputDecoration(
                      hintText: 'Add new tag…',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setState(() {
                          _tags.add(v.trim().toLowerCase());
                          _newTag.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    if (_newTag.text.trim().isNotEmpty) {
                      setState(() {
                        _tags.add(_newTag.text.trim().toLowerCase());
                        _newTag.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : isEdit
                      ? 'Save Changes'
                      : 'Add Asset'),
            ),
          ],
        ),
      ),
    );
  }
}