import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/wishlist_item.dart';
import 'wishlist_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredWishlistProvider);
    final filter = ref.watch(wishlistFilterProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            onPressed: () => _showItemForm(context, ref),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterBar(current: filter),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items here yet',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _WishlistCard(
                      item: items[i],
                      onEdit: (item) => _showItemForm(context, ref, existing: item),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, WidgetRef ref, {WishlistItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WishlistFormSheet(ref: ref, existing: existing),
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final WishlistFilter current;
  const _FilterBar({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: WishlistFilter.values.map((f) {
          final label = switch (f) {
            WishlistFilter.all         => 'All',
            WishlistFilter.unpurchased => 'Unpurchased',
            WishlistFilter.purchased   => 'Purchased',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: current == f,
              onSelected: (_) =>
                  ref.read(wishlistFilterProvider.notifier).state = f,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Grid card ──────────────────────────────────────────────────────────────────
class _WishlistCard extends ConsumerWidget {
  final WishlistItem item;
  final void Function(WishlistItem) onEdit;
  const _WishlistCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onEdit(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area — local file first, URL fallback, placeholder last
            Expanded(
              child: _ItemImage(item: item),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '₹${item.price!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Bottom row: purchased toggle + delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final actions =
                              await ref.read(wishlistActionsProvider.future);
                          await actions.togglePurchased(item);
                        },
                        child: Icon(
                          item.isPurchased
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: item.isPurchased
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, ref),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final actions =
                  await ref.read(wishlistActionsProvider.future);
              await actions.deleteItem(item);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Image renderer ─────────────────────────────────────────────────────────────
class _ItemImage extends StatelessWidget {
  final WishlistItem item;
  const _ItemImage({required this.item});

  @override
  Widget build(BuildContext context) {
    // Priority: local file → network URL → placeholder
    final localPath = item.imageUrl;

    if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('http')) {
      final file = File(localPath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (localPath != null && localPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: localPath,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined,
          size: 40, color: Colors.grey.shade300),
    );
  }
}

// ── Add / Edit form ────────────────────────────────────────────────────────────
class _WishlistFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final WishlistItem? existing;
  const _WishlistFormSheet({required this.ref, this.existing});

  @override
  State<_WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends State<_WishlistFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _productUrl;
  late final TextEditingController _imageUrl;
  String? _localImagePath;
  bool _isPurchased = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _name       = TextEditingController(text: item?.name ?? '');
    _price      = TextEditingController(
        text: item?.price != null ? item!.price!.toStringAsFixed(0) : '');
    _category   = TextEditingController(text: item?.category ?? '');
    _productUrl = TextEditingController(text: item?.productUrl ?? '');
    _imageUrl   = TextEditingController(
        text: (item?.imageUrl != null &&
                item!.imageUrl!.startsWith('http'))
            ? item.imageUrl!
            : '');
    _localImagePath =
        (item?.imageUrl != null && !item!.imageUrl!.startsWith('http'))
            ? item.imageUrl
            : null;
    _isPurchased = item?.isPurchased ?? false;
  }

  @override
  void dispose() {
    _name.dispose(); _price.dispose();
    _category.dispose(); _productUrl.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      setState(() {
        _localImagePath = file.path;
        _imageUrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);

    // Resolve image source: local file wins over URL
    String? imageValue = _localImagePath?.isNotEmpty == true
        ? _localImagePath
        : _imageUrl.text.trim().isNotEmpty
            ? _imageUrl.text.trim()
            : null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = widget.existing;

    final item = WishlistItem(
      id:          existing?.id ?? const Uuid().v4(),
      name:        _name.text.trim(),
      price:       double.tryParse(_price.text.trim()),
      imageUrl:    imageValue,
      category:    _category.text.trim().isEmpty ? null : _category.text.trim(),
      productUrl:  _productUrl.text.trim().isEmpty ? null : _productUrl.text.trim(),
      isPurchased: _isPurchased,
      createdAt:   existing?.createdAt ?? now,
    );

    final actions = await widget.ref.read(wishlistActionsProvider.future);
    if (existing == null) {
      await actions.addItem(item);
    } else {
      await actions.updateItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Item' : 'Add Item',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Image preview + picker
            _ImagePickerSection(
              localPath: _localImagePath,
              urlText: _imageUrl.text,
              onPickImage: _pickImage,
              onClearLocal: () => setState(() => _localImagePath = null),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g. Electronics, Clothing',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() => _localImagePath = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productUrl,
              decoration: const InputDecoration(
                labelText: 'Product URL (optional)',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Already purchased'),
              value: _isPurchased,
              onChanged: (v) => setState(() => _isPurchased = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : isEdit
                      ? 'Save Changes'
                      : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image picker section widget ────────────────────────────────────────────────
class _ImagePickerSection extends StatelessWidget {
  final String? localPath;
  final String urlText;
  final VoidCallback onPickImage;
  final VoidCallback onClearLocal;

  const _ImagePickerSection({
    required this.localPath,
    required this.urlText,
    required this.onPickImage,
    required this.onClearLocal,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && localPath!.isNotEmpty;

    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: hasLocal
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(localPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onClearLocal,
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
                      size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to pick image from gallery',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}