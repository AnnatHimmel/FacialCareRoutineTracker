import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/entities/master_product.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/product_thumb.dart' show userPhotoProvider;
import '../setup/add_custom_product_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  CollectionItem? _originalItem;
  CollectionItem? _draftItem;
  bool _initialized = false;

  // Compare meaningful fields only — ignore lastModified (always updated on any change).
  bool get _hasChanges {
    final d = _draftItem;
    final o = _originalItem;
    if (d == null && o == null) return false;
    if (d == null || o == null) return true;
    return d.openedDate != o.openedDate ||
        d.notificationsEnabled != o.notificationsEnabled ||
        d.status != o.status ||
        d.paoMonths != o.paoMonths;
  }

  void _initDraft(CollectionItem? item) {
    if (_initialized) return;
    _initialized = true;
    _originalItem = item;
    _draftItem = item;
  }

  Future<void> _save() async {
    final draft = _draftItem;
    if (draft == null) return;
    await ref.read(userDataRepositoryProvider).upsertCollectionItem(draft);
    if (mounted) setState(() => _originalItem = draft);
  }

  // Returns 'save', 'discard', or null (cancelled — stay on screen).
  Future<String?> _showSaveDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.unsavedChangesTitle),
        content: Text(l.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text(
              l.discardChangesAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: Text(l.saveAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final allProductsAsync = ref.watch(allProductsProvider);
    final collectionAsync = ref.watch(collectionItemsProvider);
    // Show loading until both master content and the merged product list are ready.
    if (masterAsync.isLoading || allProductsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        appBar: GlowAppBar(showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (masterAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const GlowAppBar(showBack: true),
        body: Center(child: Text(masterAsync.error.toString())),
      );
    }
    if (allProductsAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const GlowAppBar(showBack: true),
        body: Center(child: Text(allProductsAsync.error.toString())),
      );
    }

    final master = masterAsync.value!;
    final allProducts = allProductsAsync.value!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        final action = await _showSaveDialog(context);
        if (!context.mounted) return;
        if (action == 'save') await _save();
        if (!context.mounted) return;
        if (action == 'save' || action == 'discard') Navigator.of(context).pop();
        // null = stay on screen
      },
      child: Builder(
        builder: (context) {
          // Look up product from the merged list (master + custom).
          final MasterProduct? product = allProducts.cast<MasterProduct?>()
              .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

          if (product == null) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: const GlowAppBar(showBack: true),
              body: Center(child: Text(l.genericError('Product not found'))),
            );
          }

          // Resolve category name — requires master categories.
          Category? category;
          try {
            category = master.categories
                .firstWhere((c) => c.id == product.categoryId);
          } catch (_) {
            category = null;
          }
          final categoryName = category?.name ?? '';

          // Initialize draft from collection items on first data arrival.
          CollectionItem? collectionItem;
          collectionAsync.whenData((items) {
            collectionItem = items.cast<CollectionItem?>().firstWhere(
              (i) => i?.productId == widget.productId,
              orElse: () => null,
            );
          });
          _initDraft(collectionItem);

          final appBarAction = _hasChanges
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await _save();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.saveAction),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      l.saveAction,
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : null;

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: GlowAppBar(showBack: true, action: appBarAction),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHero(
                    product: product,
                    categoryName: categoryName,
                    ref: ref,
                  ),

                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(44),
                          topRight: Radius.circular(44),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeaderBlock(
                            categoryName: categoryName,
                            productName: product.name,
                            brand: product.brand,
                          ),

                          // Product description / usage comment
                          if (product
                              .localizedComment(l.localeName)
                              .isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              product.localizedComment(l.localeName),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                color: AppColors.onSurfaceVariant,
                                height: 1.65,
                              ),
                            ),
                          ],

                          // Custom product edit shortcut
                          if (product.editable) ...[
                            const SizedBox(height: 12),
                            _EditCustomProductButton(
                              productId: widget.productId,
                            ),
                          ],

                          const SizedBox(height: 20),

                          _RoutineInfoGrid(product: product),

                          if (product.ingredients.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _IngredientsSection(
                                ingredients: product.ingredients),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Edit custom product shortcut ───────────────────────────────────────────────

class _EditCustomProductButton extends ConsumerWidget {
  final String productId;
  const _EditCustomProductButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        final customProduct =
            await ref.read(routineServiceProvider).getCustomProduct(productId);
        if (customProduct == null) return;
        if (!context.mounted) return;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddCustomProductSheet(initialProduct: customProduct),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withAlpha(102),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              l.customProductEditButton,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail hero ────────────────────────────────────────────────────────────────

class _DetailHero extends StatelessWidget {
  final MasterProduct product;
  final String categoryName;
  final WidgetRef ref;

  const _DetailHero({
    required this.product,
    required this.categoryName,
    required this.ref,
  });

  static const _heroFallback = Icon(
    Icons.spa_rounded,
    size: 80,
    color: Color(0xffe58b73),
  );

  static const _heroGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xfff3d8c2), Color(0xffe7c9b0)],
    ),
  );

  Widget _buildImage(String? imageAsset) {
    final asset = imageAsset;
    if (asset == null) {
      return const Center(child: _heroFallback);
    }

    if (asset.startsWith('user_photo:')) {
      final key = asset.substring('user_photo:'.length);
      final photoAsync = ref.watch(userPhotoProvider(key));
      return photoAsync.when(
        data: (bytes) => bytes != null
            ? Image.memory(
                bytes,
                width: double.infinity,
                height: 210,
                fit: BoxFit.contain,
              )
            : const Center(child: _heroFallback),
        loading: () => const Center(child: _heroFallback),
        error: (err, st) => const Center(child: _heroFallback),
      );
    }

    if (asset.startsWith('https://') || asset.startsWith('http://')) {
      final localFilename = asset.split('/').last;
      final localAsset = 'assets/images/products/$localFilename';
      return CachedNetworkImage(
        imageUrl: asset,
        width: double.infinity,
        height: 210,
        fit: BoxFit.contain,
        placeholder: (ctx, url) => Image.asset(
          localAsset,
          width: double.infinity,
          height: 210,
          fit: BoxFit.contain,
          errorBuilder: (ctx2, err, st) => const Center(child: _heroFallback),
        ),
        errorWidget: (ctx, url, err) => const Center(child: _heroFallback),
      );
    }

    return Image.asset(
      asset,
      width: double.infinity,
      height: 210,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, st) => const Center(child: _heroFallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          Positioned.fill(child: Container(decoration: _heroGradient)),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildImage(product.imageAsset),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header block ───────────────────────────────────────────────────────────────

class _HeaderBlock extends StatelessWidget {
  final String categoryName;
  final String productName;
  final String? brand;

  const _HeaderBlock({
    required this.categoryName,
    required this.productName,
    this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (categoryName.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                categoryName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            productName,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),

        if (brand != null && brand!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              brand!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Ingredients section ────────────────────────────────────────────────────────

class _IngredientsSection extends StatelessWidget {
  final List<String> ingredients;
  const _IngredientsSection({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.detailIngredients,
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ingredients
              .map(
                (ingredient) => Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ingredient,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Routine info grid ──────────────────────────────────────────────────────────

class _RoutineInfoGrid extends StatelessWidget {
  final MasterProduct product;
  const _RoutineInfoGrid({required this.product});

  bool get _hasMorning => product.morningConfig != null;
  bool get _hasEvening => product.eveningConfig != null;

  String get _slotName {
    if (_hasMorning && _hasEvening) return 'בוקר + ערב';
    if (_hasMorning) return 'בוקר';
    if (_hasEvening) return 'ערב';
    return '';
  }

  IconData get _slotIcon {
    if (_hasMorning && _hasEvening) return Icons.wb_sunny;
    if (_hasMorning) return Icons.wb_sunny;
    return Icons.dark_mode;
  }

  String get _freqValue {
    final config = product.morningConfig ?? product.eveningConfig;
    if (config == null) return '';
    final rule = config.frequencyRule;
    if (rule is DailyRule) return 'יומי';
    if (rule is WeeklyMaxRule) return 'עד ${rule.maxPerWeek} בשבוע';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: _slotIcon,
            label: 'שגרה',
            value: _slotName,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.event,
            label: 'תדירות',
            value: _freqValue,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withAlpha(102),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
