import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';
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
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text('Wishlist',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (!Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showItemForm(context, ref),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64), // clears the nav bar
        child: FloatingActionButton(
          onPressed: () => _showItemForm(context, ref),
          backgroundColor: AndroidTheme.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _FilterBar(current: filter),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border_rounded,
                            size: 48,
                            color: AndroidTheme.textTertiary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No items here yet',
                            style: GoogleFonts.inter(
                                color: AndroidTheme.textTertiary,
                                fontSize: 15)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _WishlistCard(
                      item: items[i],
                      onEdit: (item) =>
                          _showItemForm(context, ref, existing: item),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, WidgetRef ref,
      {WishlistItem? existing}) {
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
    return AppCard(
      onTap: () => context.push('/wishlist/${item.id}', extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _ItemImage(item: item)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.price != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.price!.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                        color: AndroidTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
                if (item.category != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AndroidTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AndroidTheme.divider),
                    ),
                    child: Text(
                      item.category!,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AndroidTheme.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final actions = await ref
                            .read(wishlistActionsProvider.future);
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
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WishlistPreviewSheet(item: item, onEdit: onEdit),
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
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Wishlist preview sheet ─────────────────────────────────────────────────────
class _WishlistPreviewSheet extends StatelessWidget {
  final WishlistItem item;
  final void Function(WishlistItem) onEdit;
  const _WishlistPreviewSheet({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AndroidTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AndroidTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Image
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: item.imageUrl!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 220,
                                color: AndroidTheme.surface,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                            )
                          : Image.file(
                              File(item.imageUrl!),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AndroidTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AndroidTheme.divider),
                      ),
                      child: Icon(Icons.image_outlined,
                          size: 48,
                          color: AndroidTheme.textTertiary
                              .withValues(alpha: 0.4)),
                    ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AndroidTheme.textPrimary,
                    ),
                  ),

                  // Price
                  if (item.price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '₹${item.price!.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: AndroidTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Details
                  if (item.category != null)
                    _WishlistDetailRow(
                        label: 'Category', value: item.category!),

                  if (item.productUrl != null &&
                      item.productUrl!.isNotEmpty)
                    _WishlistDetailRow(
                      label: 'Product URL',
                      value: item.productUrl!,
                      valueColor: AndroidTheme.primary,
                    ),

                  // Purchased status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: item.isPurchased
                          ? Colors.green.shade50
                          : AndroidTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isPurchased
                            ? Colors.green.shade200
                            : AndroidTheme.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isPurchased
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: item.isPurchased
                              ? Colors.green
                              : AndroidTheme.textTertiary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.isPurchased
                              ? 'Already purchased'
                              : 'Not yet purchased',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.isPurchased
                                ? Colors.green.shade700
                                : AndroidTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Edit button
                  FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Item'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit(item);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wishlist detail row ────────────────────────────────────────────────────────
class _WishlistDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _WishlistDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: AndroidTheme.textTertiary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: valueColor ?? AndroidTheme.textPrimary,
                fontWeight: FontWeight.w500),
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
    final localPath = item.imageUrl;
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http')) {
      return Image.file(File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    if (localPath != null && localPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: localPath,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AndroidTheme.surface,
        child: Icon(Icons.image_outlined,
            size: 40, color: AndroidTheme.textTertiary.withValues(alpha: 0.4)),
      );
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
  DateTime? _targetPurchaseDate;
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
        text: (item?.imageUrl != null && item!.imageUrl!.startsWith('http'))
            ? item.imageUrl!
            : '');
    _localImagePath =
        (item?.imageUrl != null && !item!.imageUrl!.startsWith('http'))
            ? item.imageUrl
            : null;
    _targetPurchaseDate = item?.targetPurchaseAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(item!.targetPurchaseAt!);
    _isPurchased = item?.isPurchased ?? false;
  }

  @override
  void dispose() {
    _name.dispose(); _price.dispose(); _category.dispose();
    _productUrl.dispose(); _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _localImagePath = file.path;
        _imageUrl.clear();
      });
    }
  }

  Future<void> _pickTargetPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _targetPurchaseDate = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);

    String? imageValue = _localImagePath?.isNotEmpty == true
        ? _localImagePath
        : _imageUrl.text.trim().isNotEmpty
            ? _imageUrl.text.trim()
            : null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = widget.existing;

    final item = WishlistItem(
      id:         existing?.id ?? const Uuid().v4(),
      name:       _name.text.trim(),
      price:      double.tryParse(_price.text.trim()),
      imageUrl:   imageValue,
      category:   _category.text.trim().isEmpty ? null : _category.text.trim(),
      productUrl: _productUrl.text.trim().isEmpty ? null : _productUrl.text.trim(),
      targetPurchaseAt: _targetPurchaseDate?.millisecondsSinceEpoch,
      isPurchased: _isPurchased,
      purchasedAt: _isPurchased ? (existing?.purchasedAt ?? now) : null,
      createdAt:  existing?.createdAt ?? now,
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
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AndroidTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AndroidTheme.divider),
                ),
                child: _localImagePath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_localImagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _localImagePath = null),
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
                              size: 32,
                              color: AndroidTheme.textTertiary
                                  .withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('Tap to pick image from gallery',
                              style: GoogleFonts.inter(
                                  color: AndroidTheme.textTertiary,
                                  fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              decoration: const InputDecoration(
                  labelText: 'Price (₹)', prefixText: '₹ '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Electronics, Clothing'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() => _localImagePath = null),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickTargetPurchaseDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AndroidTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AndroidTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined, size: 18, color: AndroidTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _targetPurchaseDate == null
                            ? 'Target purchase date'
                            : 'Target: ${_targetPurchaseDate!.day}/${_targetPurchaseDate!.month}/${_targetPurchaseDate!.year}',
                        style: GoogleFonts.inter(fontSize: 14, color: _targetPurchaseDate == null ? AndroidTheme.textTertiary : AndroidTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productUrl,
              decoration: const InputDecoration(
                labelText: 'Product URL (optional)',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AndroidTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AndroidTheme.divider),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                title: Text('Already purchased',
                    style:
                        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                value: _isPurchased,
                activeColor: AndroidTheme.primary,
                onChanged: (v) => setState(() => _isPurchased = v),
              ),
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
// ── Dedicated wishlist details page ───────────────────────────────────────────
class WishlistDetailsScreen extends ConsumerWidget {
  final String itemId;
  final WishlistItem? initialItem;
  const WishlistDetailsScreen({super.key, required this.itemId, this.initialItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(wishlistItemByIdProvider(itemId));
    final item = asyncItem.valueOrNull ?? initialItem;
    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(title: const Text('Wishlist Details')),
      body: item == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(height: 320, child: _ItemImage(item: item)),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(item.price == null ? 'No price set' : '₹${item.price!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 20, color: AndroidTheme.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text('Target Purchase Date: ${_formatDate(item.targetPurchaseAt)}',
                          style: GoogleFonts.inter(color: AndroidTheme.textSecondary)),
                      if (item.purchasedAt != null) ...[
                        const SizedBox(height: 6),
                        Text('Purchased: ${_formatDate(item.purchasedAt)}',
                            style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 18),
                      if (item.productUrl != null && item.productUrl!.isNotEmpty)
                        FilledButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open Product Link'),
                          onPressed: () => _launch(item.productUrl!),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: Icon(item.isPurchased ? Icons.undo_rounded : Icons.check_circle_outline_rounded),
                        label: Text(item.isPurchased ? 'Mark as Not Purchased' : 'Mark as Purchased'),
                        onPressed: () async {
                          final actions = await ref.read(wishlistActionsProvider.future);
                          await actions.togglePurchased(item);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _formatDate(int? ms) {
    if (ms == null) return 'Not set';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value.startsWith('http') ? value : 'https://$value');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}