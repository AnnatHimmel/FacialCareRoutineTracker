import 'dart:math' show min;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/l10n/hebrew_date_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/collection_status.dart';
import '../../domain/services/pao_calculator.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/pao_meter.dart';
import '../../shared/widgets/pro_tag.dart';
import '../../shared/widgets/product_thumb.dart' show userPhotoProvider;
import '../../shared/widgets/upgrade_sheet.dart';
import '../../core/config/feature_flags.dart';
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

  void _updateDraft(CollectionItem updated) {
    setState(() => _draftItem = updated);
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
    final collectionAsync = ref.watch(collectionItemsProvider);
    final customAsync = ref.watch(customProductsProvider);
    final isPro = ref.watch(isProDemoProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        final action = await _showSaveDialog(context);
        if (!mounted) return;
        if (action == 'save') {
          await _save();
          if (mounted) Navigator.of(context).pop();
        } else if (action == 'discard') {
          Navigator.of(context).pop();
        }
        // null = stay on screen
      },
      child: masterAsync.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const GlowAppBar(showBack: true),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const GlowAppBar(showBack: true),
          body: Center(child: Text(e.toString())),
        ),
        data: (master) {
          // Look up product — master first, then custom.
          MasterProduct? product = master.products.cast<MasterProduct?>()
              .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

          bool isCustom = false;
          UserCustomProduct? customProduct;
          if (product == null) {
            final customs = customAsync.valueOrNull ?? [];
            customProduct = customs.cast<UserCustomProduct?>().firstWhere(
              (c) => c?.id == widget.productId,
              orElse: () => null,
            );
            if (customProduct != null) {
              product = customProduct.toMasterProduct();
              isCustom = true;
            }
          }

          if (product == null) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: const GlowAppBar(showBack: true),
              body: Center(child: Text(l.genericError('Product not found'))),
            );
          }

          // Resolve category name.
          Category? category;
          try {
            category = master.categories
                .firstWhere((c) => c.id == product!.categoryId);
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.saveAction),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
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
                          if (isCustom && customProduct != null) ...[
                            const SizedBox(height: 12),
                            _EditCustomProductButton(
                              customProduct: customProduct,
                            ),
                          ],

                          // Lifecycle card — PRO gated
                          if (kProFeaturesEnabled) ...[
                            if (isPro)
                              _LifecycleCard(
                                productId: widget.productId,
                                product: product,
                                draft: _draftItem,
                                onDraftChanged: _updateDraft,
                              )
                            else
                              _LifecycleCardLocked(product: product),
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
  final UserCustomProduct customProduct;
  const _EditCustomProductButton({required this.customProduct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddCustomProductSheet(initialProduct: customProduct),
      ),
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

// ── Lifecycle card (functional PRO) ───────────────────────────────────────────

class _LifecycleCard extends ConsumerWidget {
  final String productId;
  final MasterProduct product;
  final CollectionItem? draft;
  final ValueChanged<CollectionItem> onDraftChanged;

  const _LifecycleCard({
    required this.productId,
    required this.product,
    required this.draft,
    required this.onDraftChanged,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      return '${EnglishDateStrings.months[date.month - 1]} ${date.day}';
    }
    return '${date.day} ב${HebrewDateStrings.months[date.month - 1]}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft?.openedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
    );
    if (picked == null) return;
    final item = draft;
    final updated = item == null
        ? CollectionItem(
            id: const Uuid().v4(),
            productId: productId,
            status: CollectionStatus.inUse,
            openedDate: picked,
            paoMonths: defaultPaoMonths(product.categoryId),
            notificationsEnabled: true,
            lastModified: DateTime.now(),
          )
        : item.copyWith(
            openedDate: picked,
            status: CollectionStatus.inUse,
            lastModified: DateTime.now(),
          );
    onDraftChanged(updated);
  }

  void _toggleNotify(bool value) {
    final item = draft;
    if (item == null) return;
    onDraftChanged(
        item.copyWith(notificationsEnabled: value, lastModified: DateTime.now()));
  }

  void _setStatus(CollectionStatus status) {
    final item = draft;
    if (item == null) return;
    onDraftChanged(item.copyWith(status: status, lastModified: DateTime.now()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final item = draft;
    final hasOpenedDate = item != null && item.openedDate != null;

    final paoMonths = item?.paoMonths ?? defaultPaoMonths(product.categoryId);
    final progress = ref.read(paoCalculatorProvider).compute(
          openedDate: item?.openedDate,
          paoMonths: paoMonths,
          now: DateTime.now(),
        );
    final isExpired = progress.tone == PaoTone.bad;

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xfffdf8ec)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xffeddfb8),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title row ──────────────────────────────────────────────────
          Row(
            children: [
              Text(
                l.lifecycleTitle,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              const ProTag(),
              if (hasOpenedDate) ...[
                const Spacer(),
                Text(
                  l.lifecycleInUse,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── Opened date row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.lifecycleOpenedDate,
                style: GoogleFonts.quicksand(
                  fontSize: 13.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (hasOpenedDate)
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(context, item.openedDate!),
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit,
                          size: 14, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                )
              else
                Text(
                  l.lifecycleNotOpened,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          // ── PAO meter ─────────────────────────────────────────────────
          const SizedBox(height: 10),
          PaoMeter(
            value: progress.fraction.clamp(0.0, 1.0),
            tone: progress.tone,
            height: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.lifecyclePao(paoMonths.toString()),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                isExpired
                    ? l.lifecycleExpired
                    : l.lifecycleMonthsLeft(
                        progress.monthsRemaining.toString()),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isExpired ? AppColors.error : AppColors.primary,
                ),
              ),
            ],
          ),

          // ── Not-opened CTA ────────────────────────────────────────────
          if (!hasOpenedDate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => _pickDate(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(
                  l.lifecycleSetOpenedDate,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],

          // ── In-use: notify + actions ───────────────────────────────────
          if (hasOpenedDate) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.lifecycleNotify,
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    color: AppColors.onSurface,
                  ),
                ),
                Switch(
                  value: item.notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleNotify,
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Divider(height: 1, color: Color(0xffeddfb8)),
            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _setStatus(CollectionStatus.archive),
                    icon: const Icon(Icons.task_alt,
                        size: 16, color: AppColors.onSurfaceVariant),
                    label: Text(
                      l.lifecycleFinished,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: Color(0xffeddfb8),
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _setStatus(CollectionStatus.archive),
                    icon: const Icon(Icons.delete,
                        size: 16, color: AppColors.onSurfaceVariant),
                    label: Text(
                      l.lifecycleDiscarded,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Lifecycle card (locked / non-PRO teaser) ──────────────────────────────────

class _LifecycleCardLocked extends StatelessWidget {
  final MasterProduct product;
  const _LifecycleCardLocked({required this.product});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CustomPaint(
      painter: _DashedRoundedBorderPainter(),
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfffdfaf2),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l.lifecycleTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const ProTag(),
                const Spacer(),
                const Icon(Icons.lock_rounded,
                    size: 18, color: Color(0xffa8821f)),
              ],
            ),

            const SizedBox(height: 12),

            Opacity(
              opacity: 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.lifecycleOpenedDate,
                    style: GoogleFonts.quicksand(
                      fontSize: 13.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '· · ·',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            const Opacity(
              opacity: 0.5,
              child: PaoMeter(value: 0, tone: PaoTone.ok, height: 8),
            ),

            const SizedBox(height: 16),

            Text(
              'מתי נפתח? כמה זמן נשאר? עקבי אחרי חיי מדף, תוקף והתראות, עם Glow PRO.',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffb3892a), Color(0xff8f6a15)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextButton.icon(
                  onPressed: () => showUpgradeSheet(context),
                  icon: const Icon(Icons.workspace_premium,
                      size: 18, color: Colors.white),
                  label: Text(
                    'נסי את PRO',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  static const _color = Color(0xffe3d3a6);
  static const _radius = 26.0;
  static const _dashLen = 6.0;
  static const _gapLen = 4.0;
  static const _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    const half = _strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          half, half, size.width - _strokeWidth, size.height - _strokeWidth),
      const Radius.circular(_radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segLen = draw ? _dashLen : _gapLen;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(
                distance, min(distance + segLen, metric.length)),
            paint,
          );
        }
        distance += segLen;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) => false;
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
