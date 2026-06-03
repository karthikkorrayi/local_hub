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
              onPressed: () => _showItemForm(context),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showItemForm(context),
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: List.generate(items.length, (i) {
                        final size = isWide ? 150.0 + (i % 3) * 18 : 132.0 + (i % 4) * 12;
                        return SizedBox(
                          width: size,
                          height: size + 42,
                          child: _WishlistCard(
                            item: items[i],
                            onEdit: (item) => _showItemForm(context, existing: item),
                          ),
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, {WishlistItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WishlistFormSheet(existing: existing),
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
            WishlistFilter.ordered => 'Ordered',
            WishlistFilter.target  => 'Target',
            WishlistFilter.gifts   => 'Gifts',
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
class _WishlistFormSheet extends ConsumerStatefulWidget {
  final WishlistItem? existing;
  const _WishlistFormSheet({this.existing});

  @override
  ConsumerState<_WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends ConsumerState<_WishlistFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _productUrl;
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
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _productUrl.dispose();
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
    try {
      final String? imageValue =
          _localImagePath?.isNotEmpty == true ? _localImagePath : null;
      final now = DateTime.now().millisecondsSinceEpoch;
      final existing = widget.existing;
      final item = WishlistItem(
        id:               existing?.id ?? const Uuid().v4(),
        name:             _name.text.trim(),
        price:            double.tryParse(_price.text.trim()),
        imageUrl:         imageValue,
        category:         _category.text.trim().isEmpty ? null : _category.text.trim(),
        productUrl:       _productUrl.text.trim().isEmpty ? null : _productUrl.text.trim(),
        targetPurchaseAt: _targetPurchaseDate?.millisecondsSinceEpoch,
        isPurchased:      _isPurchased,
        purchasedAt:      _isPurchased ? (existing?.purchasedAt ?? now) : null,
        createdAt:        existing?.createdAt ?? now,
      );
      final actions = await ref.read(wishlistActionsProvider.future);
      if (existing == null) {
        await actions.addItem(item);
      } else {
        await actions.updateItem(item);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                            : 'Target: ${_targetPurchaseDate!.day.toString().padLeft(2, '0')}/${_targetPurchaseDate!.month.toString().padLeft(2, '0')}/${_targetPurchaseDate!.year}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _targetPurchaseDate == null
                                ? AndroidTheme.textTertiary
                                : AndroidTheme.textPrimary),
                      ),
                    ),
                    if (_targetPurchaseDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetPurchaseDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AndroidTheme.textTertiary),
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
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
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
class WishlistDetailsScreen extends ConsumerStatefulWidget {
  final String itemId;
  final WishlistItem? initialItem;
  const WishlistDetailsScreen({super.key, required this.itemId, this.initialItem});

  @override
  ConsumerState<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends ConsumerState<WishlistDetailsScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(filteredWishlistProvider);
    final asyncItem = ref.watch(wishlistItemByIdProvider(widget.itemId));
    final current = asyncItem.when(
      data: (item) => item ?? widget.initialItem,
      loading: () => widget.initialItem,
      error: (_, __) => widget.initialItem,
    );
    final pageItems = items.isNotEmpty ? items : [if (current != null) current];
    final foundIndex = current == null ? 0 : pageItems.indexWhere((i) => i.id == current.id);
    final initialIndex = foundIndex < 0 ? 0 : foundIndex.clamp(0, pageItems.length - 1) as int;
    if (_controller.hasClients && _controller.page?.round() != initialIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(initialIndex);
      });
    }

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(title: const Text('Wishlist Details')),
      body: pageItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _controller,
              itemCount: pageItems.length,
              itemBuilder: (_, index) => _WishlistDetailPage(item: pageItems[index]),
            ),
    );
  }
}

class _WishlistDetailPage extends ConsumerWidget {
  final WishlistItem item;
  const _WishlistDetailPage({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          item.price == null ? 'No price set' : '₹${item.price!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 20, color: AndroidTheme.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Target Date',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(fontSize: 11, color: AndroidTheme.textTertiary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.targetPurchaseAt),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (item.productUrl != null && item.productUrl!.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Product Link'),
                  onPressed: () => _launch(item.productUrl!),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: Icon(item.isPurchased
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded),
                label: Text(item.isPurchased
                    ? 'Mark as Not Purchased'
                    : 'Mark as Purchased'),
                onPressed: () async {
                  final actions = await ref.read(wishlistActionsProvider.future);
                  await actions.togglePurchased(item);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              onPressed: () => _showEditForm(context, item),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDelete(context, ref, item),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditForm(BuildContext context, WishlistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WishlistFormSheet(existing: item),
    );
  }

  static String _formatDate(int? ms) {
    if (ms == null) return 'Not set';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value.startsWith('http') ? value : 'https://$value');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WishlistItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final actions = await ref.read(wishlistActionsProvider.future);
              await actions.deleteItem(item);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}