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

// ── Module color shortcuts ────────────────────────────────────────────────────
const _mc  = AndroidTheme.wishlistPrimary;
const _mcl = AndroidTheme.wishlistPrimaryLight;

// ── Screen ─────────────────────────────────────────────────────────────────────
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items  = ref.watch(filteredWishlistProvider);
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
          backgroundColor: _mc,
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
                            color:
                                AndroidTheme.textTertiary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No items here yet',
                            style: GoogleFonts.inter(
                                color: AndroidTheme.textTertiary, fontSize: 15)),
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
                        final size = isWide
                            ? 150.0 + (i % 3) * 18
                            : 132.0 + (i % 4) * 12;
                        return SizedBox(
                          width: size,
                          height: size + 42,
                          child: _WishlistCard(
                            item: items[i],
                            // Pass the index within the current filtered list
                            filteredIndex: i,
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
              selectedColor: _mcl,
              checkmarkColor: _mc,
              side: BorderSide(
                  color: current == f ? _mc : AndroidTheme.divider),
              labelStyle: GoogleFonts.inter(
                fontWeight: current == f ? FontWeight.w700 : FontWeight.w500,
                color: current == f ? _mc : AndroidTheme.textSecondary,
              ),
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
  final int filteredIndex;
  final void Function(WishlistItem) onEdit;
  const _WishlistCard(
      {required this.item,
      required this.filteredIndex,
      required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      // Navigate using item.id — never rely on index
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
                Text(item.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (item.price != null) ...[
                  const SizedBox(height: 2),
                  Text('₹${item.price!.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: _mc,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
                if (item.category != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AndroidTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AndroidTheme.divider),
                    ),
                    child: Text(item.category!,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AndroidTheme.textSecondary)),
                  ),
                ],
                const SizedBox(height: 6),
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final actions =
                    await ref.read(wishlistActionsProvider.future);
                await actions.deleteItem(item);
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
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
            size: 40,
            color: AndroidTheme.textTertiary.withValues(alpha: 0.4)),
      );
}

// ── Add / Edit form ────────────────────────────────────────────────────────────
class _WishlistFormSheet extends ConsumerStatefulWidget {
  final WishlistItem? existing;
  const _WishlistFormSheet({this.existing});

  @override
  ConsumerState<_WishlistFormSheet> createState() =>
      _WishlistFormSheetState();
}

class _WishlistFormSheetState extends ConsumerState<_WishlistFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _productUrl;
  // Extra fields for gift linking
  late final TextEditingController _giftFor;
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
    _giftFor    = TextEditingController(text: item?.giftFor ?? '');
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
    _giftFor.dispose();
    super.dispose();
  }

  // Store original file path — no copying
  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) setState(() => _localImagePath = file.path);
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
      final now = DateTime.now().millisecondsSinceEpoch;
      final existing = widget.existing;
      final item = WishlistItem(
        id:               existing?.id ?? const Uuid().v4(),
        name:             _name.text.trim(),
        price:            double.tryParse(_price.text.trim()),
        imageUrl:         _localImagePath?.isNotEmpty == true
            ? _localImagePath
            : null,
        category:         _category.text.trim().isEmpty
            ? null
            : _category.text.trim(),
        productUrl:       _productUrl.text.trim().isEmpty
            ? null
            : _productUrl.text.trim(),
        targetPurchaseAt: _targetPurchaseDate?.millisecondsSinceEpoch,
        isPurchased:      _isPurchased,
        purchasedAt:      _isPurchased
            ? (existing?.purchasedAt ?? now)
            : null,
        createdAt:        existing?.createdAt ?? now,
        giftFor:          _giftFor.text.trim().isEmpty
            ? null
            : _giftFor.text.trim(),
        giftDate:         existing?.giftDate,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isGift = _category.text.toLowerCase().contains('gift') ||
        widget.existing?.giftFor != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit Item' : 'Add Item',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
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
                    ? Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(_localImagePath!),
                              fit: BoxFit.cover),
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
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ])
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
                  hintText: 'e.g. Electronics, Gift'),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            // Gift for field — visible when category contains "gift"
            if (isGift) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _giftFor,
                decoration: const InputDecoration(
                    labelText: 'Gift for (person name)',
                    hintText: 'e.g. John',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickTargetPurchaseDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AndroidTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AndroidTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined,
                        size: 18, color: AndroidTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _targetPurchaseDate == null
                            ? 'Target purchase date'
                            : 'Target: ${_fmtDate(_targetPurchaseDate!)}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _targetPurchaseDate == null
                                ? AndroidTheme.textTertiary
                                : AndroidTheme.textPrimary),
                      ),
                    ),
                    if (_targetPurchaseDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _targetPurchaseDate = null),
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
                  hintText: 'https://...'),
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
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                value: _isPurchased,
                activeColor: _mc,
                onChanged: (v) => setState(() => _isPurchased = v),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: _mc),
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

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Wishlist Details Screen ───────────────────────────────────────────────────
class WishlistDetailsScreen extends ConsumerStatefulWidget {
  final String itemId;
  final WishlistItem? initialItem;
  const WishlistDetailsScreen(
      {super.key, required this.itemId, this.initialItem});

  @override
  ConsumerState<WishlistDetailsScreen> createState() =>
      _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState
    extends ConsumerState<WishlistDetailsScreen> {
  late PageController _controller;
  int _currentPage = 0;
  bool _initialPageSet = false;

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
    // Use the current filter's list so swipe stays within filter context
    final pageItems = ref.watch(filteredWishlistProvider);

    // Always resolve by ID — never by index
    final targetIndex =
        pageItems.indexWhere((i) => i.id == widget.itemId);
    final resolvedIndex = targetIndex >= 0 ? targetIndex : 0;

    // Set the page once when the list first loads
    if (!_initialPageSet && pageItems.isNotEmpty) {
      _initialPageSet = true;
      _currentPage = resolvedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(resolvedIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: pageItems.isNotEmpty
            ? Text(pageItems[_currentPage.clamp(0, pageItems.length - 1)].name,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
            : const Text('Wishlist Details'),
      ),
      body: pageItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _controller,
              itemCount: pageItems.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, index) =>
                  _WishlistDetailPage(item: pageItems[index]),
            ),
    );
  }
}

// ── Detail page ───────────────────────────────────────────────────────────────
class _WishlistDetailPage extends ConsumerWidget {
  final WishlistItem item;
  const _WishlistDetailPage({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Image card
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(height: 300, child: _ItemImage(item: item)),
          ),
        ),
        const SizedBox(height: 16),

        // Info card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + price row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AndroidTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          item.price == null
                              ? 'No price set'
                              : '₹${item.price!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              color: _mc,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dates right-aligned
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _InfoChip(
                          label: 'Target',
                          value: _fmtDate(item.targetPurchaseAt)),
                    ],
                  ),
                ],
              ),

              // Gift relation — shown only when giftFor is set
              if (item.giftFor != null && item.giftFor!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gift for ${item.giftFor}',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(0xFFD97706))),
                            if (item.giftDate != null)
                              Text(
                                'Date: ${_fmtDate(item.giftDate)}',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF92400E)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (item.category != null) ...[
                const SizedBox(height: 14),
                _DetailRow(
                    icon: Icons.label_outline_rounded,
                    label: 'Category',
                    value: item.category!),
              ],

              const SizedBox(height: 14),

              // Purchase status
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
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
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

              const SizedBox(height: 16),

              if (item.productUrl != null && item.productUrl!.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Product Link'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _mc,
                      side: const BorderSide(color: _mc)),
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
                style: FilledButton.styleFrom(backgroundColor: _mc),
                onPressed: () async {
                  final actions =
                      await ref.read(wishlistActionsProvider.future);
                  await actions.togglePurchased(item);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Edit + Delete
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _mc,
                  side: const BorderSide(color: _mc)),
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

  static String _fmtDate(int? ms) {
    if (ms == null) return 'Not set';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _launch(String value) async {
    final uri = Uri.tryParse(
        value.startsWith('http') ? value : 'https://$value');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, WishlistItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final actions =
                    await ref.read(wishlistActionsProvider.future);
                await actions.deleteItem(item);
                if (context.mounted) context.pop();
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ── Detail row widget ──────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AndroidTheme.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AndroidTheme.textTertiary)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AndroidTheme.textPrimary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// ── Info chip (right-aligned date label) ──────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: AndroidTheme.textTertiary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AndroidTheme.textPrimary),
            maxLines: 1),
      ],
    );
  }
}