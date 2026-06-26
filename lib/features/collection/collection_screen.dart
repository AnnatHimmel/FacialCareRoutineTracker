import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/collection_status.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/pao_calculator.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/pao_meter.dart';
import '../../shared/widgets/pro_tag.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/upgrade_sheet.dart';
import '../../core/config/feature_flags.dart';
import '../setup/add_custom_product_sheet.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  int _selectedTab = 0; // 0=inUse, 1=sealed, 2=archive

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPro = ref.watch(isProDemoProvider);

    final morningSelections =
        ref.watch(selectionsProvider(Slot.morning)).valueOrNull ?? [];
    final eveningSelections =
        ref.watch(selectionsProvider(Slot.evening)).valueOrNull ?? [];
    final masterAsync = ref.watch(masterContentProvider);
    final customProducts = ref.watch(customProductsProvider).valueOrNull ?? [];
    final collectionItems =
        ref.watch(collectionItemsProvider).valueOrNull ?? [];
    final paoCalc = ref.watch(paoCalculatorProvider);

    final selectedIds = {
      ...morningSelections.where((s) => s.isSelected).map((s) => s.productId),
      ...eveningSelections.where((s) => s.isSelected).map((s) => s.productId),
    };

    return masterAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: GlowAppBar(title: l.navCollection),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: GlowAppBar(title: l.navCollection),
        body: Center(child: Text(l.genericError(e.toString()))),
      ),
      data: (master) {
        final selectedMasterProducts = master.products
            .where((p) => selectedIds.contains(p.id) && !p.isDeprecated)
            .toList();

        final customAsMaster = customProducts
            .map((c) => c.toMasterProduct())
            .toList();
        final allDisplayProducts = [
          ...selectedMasterProducts,
          ...customAsMaster,
        ];

        // Resolves a product's "Category · Sub-category" chip label (or just the
        // category when there is no sub-category). Returns null when neither is
        // known.
        final catById = {for (final c in master.categories) c.id: c};
        final subById = {for (final s in master.subcategories) s.id: s};
        String? categoryLabel(MasterProduct p) {
          final catName = catById[p.categoryId]?.localizedName(l.localeName);
          final subName = p.subCategoryId == null
              ? null
              : subById[p.subCategoryId]?.localizedName(l.localeName);
          final cn = (catName != null && catName.isNotEmpty) ? catName : null;
          final sn = (subName != null && subName.isNotEmpty) ? subName : null;
          if (cn == null) return sn;
          if (sn == null) return cn;
          return '$cn · $sn';
        }

        // Build a fast lookup map: productId -> CollectionItem
        final itemsByProductId = <String, CollectionItem>{
          for (final item in collectionItems) item.productId: item,
        };

        // Compute effective status for each product
        CollectionStatus effectiveStatus(MasterProduct p) {
          final item = itemsByProductId[p.id];
          return item?.status ?? CollectionStatus.inUse;
        }

        final inUseProducts = allDisplayProducts
            .where((p) => effectiveStatus(p) == CollectionStatus.inUse)
            .toList();
        final sealedProducts = allDisplayProducts
            .where((p) => effectiveStatus(p) == CollectionStatus.sealed)
            .toList();
        final archiveProducts = allDisplayProducts
            .where((p) => effectiveStatus(p) == CollectionStatus.archive)
            .toList();

        // Count attention items: in-use products with warn or bad PAO tone
        final now = DateTime.now();
        int attentionCount = 0;
        for (final p in inUseProducts) {
          final item = itemsByProductId[p.id];
          final progress = paoCalc.compute(
            openedDate: item?.openedDate,
            paoMonths: item?.paoMonths ?? defaultPaoMonths(p.categoryId),
            now: now,
          );
          if (progress.isOpened &&
              (progress.tone == PaoTone.warn || progress.tone == PaoTone.bad)) {
            attentionCount++;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: GlowAppBar(title: l.navCollection),
          floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => context.push('/products'),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    l.collectionAddRemoveProduct,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: CustomScrollView(
            slivers: [
              // ── Week Glance entry card (always visible, free feature) ────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: WeekGlanceEntryCard(),
                ),
              ),
              if (kProFeaturesEnabled) ...[
                if (isPro) ...[
                  // ── Health card (PRO) ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _HealthCardPro(
                        totalCount: allDisplayProducts.length,
                        attentionCount: attentionCount,
                        l: l,
                        onAttentionTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                  ),
                  // ── Segmented tab control ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _SegmentedTabs(
                        selectedIndex: _selectedTab,
                        inUseCount: inUseProducts.length,
                        sealedCount: sealedProducts.length,
                        archiveCount: archiveProducts.length,
                        l: l,
                        onTabSelected: (i) => setState(() => _selectedTab = i),
                      ),
                    ),
                  ),
                  // ── Tab body ──────────────────────────────────────────────
                  if (_selectedTab == 0)
                    _InUseSliver(
                      products: inUseProducts,
                      itemsByProductId: itemsByProductId,
                      paoCalc: paoCalc,
                      l: l,
                      now: now,
                      categoryLabel: categoryLabel,
                    )
                  else if (_selectedTab == 1)
                    _SealedSliver(
                      products: sealedProducts,
                      l: l,
                      categoryLabel: categoryLabel,
                    )
                  else
                    _ArchiveSliver(
                      products: archiveProducts,
                      l: l,
                      categoryLabel: categoryLabel,
                    ),
                ] else ...[
                  // ── Health card (FREE) ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _HealthCardFree(
                        totalCount: allDisplayProducts.length,
                        inRoutineCount: inUseProducts.length,
                        l: l,
                      ),
                    ),
                  ),
                  // ── Free product list ─────────────────────────────────────
                  _FreeProductSliver(
                    products: allDisplayProducts,
                    l: l,
                    categoryLabel: categoryLabel,
                  ),
                ],
              ] else ...[
                // ── Pro features disabled: show flat product list ─────────────
                _FreeProductSliver(
                  products: allDisplayProducts,
                  l: l,
                  categoryLabel: categoryLabel,
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

// ── Health Card (PRO) ─────────────────────────────────────────────────────────

class _HealthCardPro extends StatelessWidget {
  final int totalCount;
  final int attentionCount;
  final AppLocalizations l;
  final VoidCallback onAttentionTap;

  const _HealthCardPro({
    required this.totalCount,
    required this.attentionCount,
    required this.l,
    required this.onAttentionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xfffdf8ec)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffeddfb8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.collectionHealthCard,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ProTag(),
                ],
              ),
              Text(
                '$totalCount ${l.collectionCountSuffix}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant.withAlpha(204),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Attention strip
          GestureDetector(
            onTap: attentionCount > 0 ? onAttentionTap : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfffcf3df),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    attentionCount > 0
                        ? Icons.schedule_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: attentionCount > 0
                        ? const Color(0xff8a5a17)
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attentionCount > 0
                          ? l.collectionAttentionCount(attentionCount)
                          : l.collectionHealthOk,
                      style: GoogleFonts.quicksand(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: attentionCount > 0
                            ? const Color(0xff6b4a12)
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (attentionCount > 0)
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      textDirection: TextDirection.ltr,
                      size: 18,
                      color: Color(0xff8a5a17),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented Tab Control ─────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final int inUseCount;
  final int sealedCount;
  final int archiveCount;
  final AppLocalizations l;
  final ValueChanged<int> onTabSelected;

  const _SegmentedTabs({
    required this.selectedIndex,
    required this.inUseCount,
    required this.sealedCount,
    required this.archiveCount,
    required this.l,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      '${l.collectionTabInUse} ($inUseCount)',
      '${l.collectionTabSealed} ($sealedCount)',
      '${l.collectionTabArchive} ($archiveCount)',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withAlpha(178), // ~70%
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: isActive ? AppColors.glowSm : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── In-Use Sliver ─────────────────────────────────────────────────────────────

class _InUseSliver extends StatelessWidget {
  final List<MasterProduct> products;
  final Map<String, CollectionItem> itemsByProductId;
  final PaoCalculator paoCalc;
  final AppLocalizations l;
  final DateTime now;
  final String? Function(MasterProduct) categoryLabel;

  const _InUseSliver({
    required this.products,
    required this.itemsByProductId,
    required this.paoCalc,
    required this.l,
    required this.now,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Text(
              l.productSelNoProducts,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          final item = itemsByProductId[product.id];
          final progress = paoCalc.compute(
            openedDate: item?.openedDate,
            paoMonths: item?.paoMonths ?? defaultPaoMonths(product.categoryId),
            now: now,
          );
          final isLast = index == products.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _CollectionRow(
              product: product,
              progress: progress,
              l: l,
              categoryLabel: categoryLabel(product),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCustomProductSheet(
                  viewProduct: product,
                  isUserProduct: product.addedInVersion == 'custom',
                ),
              ),
            ),
          );
        }, childCount: products.length),
      ),
    );
  }
}

// ── Collection Row (in-use) ───────────────────────────────────────────────────

class _CollectionRow extends StatelessWidget {
  final MasterProduct product;
  final PaoProgress progress;
  final AppLocalizations l;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _CollectionRow({
    required this.product,
    required this.progress,
    required this.l,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.glowSm,
          border: Border.all(color: AppColors.outlineVariant.withAlpha(51)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductThumb(imageAsset: product.imageAsset, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (categoryLabel != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _CategoryChip(label: categoryLabel!),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (progress.isOpened) ...[
                    PaoMeter(
                      value: progress.fraction.clamp(0.0, 1.0),
                      tone: progress.tone,
                      height: 5,
                    ),
                    if (progress.tone == PaoTone.warn ||
                        progress.tone == PaoTone.bad)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: progress.tone == PaoTone.bad
                                    ? AppColors.error
                                    : const Color(0xff8a5a17),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                progress.tone == PaoTone.bad
                                    ? l.lifecycleExpired
                                    : l.lifecycleMonthsLeft(
                                        progress.monthsRemaining,
                                      ),
                                style: GoogleFonts.quicksand(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: progress.tone == PaoTone.bad
                                      ? AppColors.error
                                      : const Color(0xff8a5a17),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else
                    Text(
                      l.lifecycleNotOpened,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant.withAlpha(153),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              textDirection: TextDirection.ltr,
              size: 22,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sealed Sliver ─────────────────────────────────────────────────────────────

class _SealedSliver extends StatelessWidget {
  final List<MasterProduct> products;
  final AppLocalizations l;
  final String? Function(MasterProduct) categoryLabel;

  const _SealedSliver({
    required this.products,
    required this.l,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Text(
              l.collectionSealedEmpty,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          final isLast = index == products.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _SealedRow(
              product: product,
              l: l,
              categoryLabel: categoryLabel(product),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCustomProductSheet(
                  viewProduct: product,
                  isUserProduct: product.addedInVersion == 'custom',
                ),
              ),
            ),
          );
        }, childCount: products.length),
      ),
    );
  }
}

// ── Sealed Row ────────────────────────────────────────────────────────────────

class _SealedRow extends StatelessWidget {
  final MasterProduct product;
  final AppLocalizations l;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _SealedRow({
    required this.product,
    required this.l,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(178), // white/70
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withAlpha(128), // /50
            style: BorderStyle.solid,
            // Dashed border approximation via a custom painter would be ideal;
            // using solid with reduced opacity as a lightweight alternative.
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductThumb(imageAsset: product.imageAsset, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (categoryLabel != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _CategoryChip(label: categoryLabel!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                l.collectionSealedBadge,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Archive Sliver ────────────────────────────────────────────────────────────

class _ArchiveSliver extends StatelessWidget {
  final List<MasterProduct> products;
  final AppLocalizations l;
  final String? Function(MasterProduct) categoryLabel;

  const _ArchiveSliver({
    required this.products,
    required this.l,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Text(
              l.collectionArchiveEmpty,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          final isLast = index == products.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _ArchiveRow(
              product: product,
              l: l,
              categoryLabel: categoryLabel(product),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCustomProductSheet(
                  viewProduct: product,
                  isUserProduct: product.addedInVersion == 'custom',
                ),
              ),
            ),
          );
        }, childCount: products.length),
      ),
    );
  }
}

// ── Health Card (FREE) ────────────────────────────────────────────────────────

class _HealthCardFree extends StatelessWidget {
  final int totalCount;
  final int inRoutineCount;
  final AppLocalizations l;

  const _HealthCardFree({
    required this.totalCount,
    required this.inRoutineCount,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfffdfaf2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffe3d3a6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.collectionHealthCard,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ProTag(),
                ],
              ),
              Text(
                '$totalCount ${l.collectionCountSuffix}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant.withAlpha(204),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3 stat cells
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: l.collectionOnShelf,
                  value: '$totalCount',
                  valueColor: AppColors.primary,
                  bgColor: Colors.white,
                  borderColor: AppColors.outlineVariant.withAlpha(51),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCell(
                  label: l.collectionInRoutines,
                  value: '$inRoutineCount',
                  valueColor: AppColors.onSurfaceVariant,
                  bgColor: Colors.white,
                  borderColor: AppColors.outlineVariant.withAlpha(51),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCell(
                  label: l.collectionToCheck,
                  value: '0',
                  valueColor: const Color(0xff8a5a17),
                  bgColor: const Color(0xfffcf3df),
                  borderColor: const Color(0xffecd9a8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Locked banner
          GestureDetector(
            onTap: () => showUpgradeSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfffcf3df),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Color(0xffa8821f),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.collectionProBanner,
                      style: GoogleFonts.quicksand(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff6b4a12),
                      ),
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    textDirection: TextDirection.ltr,
                    size: 18,
                    color: Color(0xffa8821f),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Cell (used inside HealthCardFree) ────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;
  final Color borderColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Category · Sub-category chip ──────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withAlpha(90),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Free Product Sliver ───────────────────────────────────────────────────────

class _FreeProductSliver extends StatelessWidget {
  final List<MasterProduct> products;
  final AppLocalizations l;
  final String? Function(MasterProduct) categoryLabel;

  const _FreeProductSliver({
    required this.products,
    required this.l,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              l.collectionAllProducts,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          // Product rows
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  l.productSelNoProducts,
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final isLast = index == products.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: _FreeRow(
                  product: product,
                  categoryLabel: categoryLabel(product),
                  onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCustomProductSheet(
                  viewProduct: product,
                  isUserProduct: product.addedInVersion == 'custom',
                ),
              ),
                ),
              );
            }),
        ]),
      ),
    );
  }
}

// ── Free Row ──────────────────────────────────────────────────────────────────

class _FreeRow extends StatelessWidget {
  final MasterProduct product;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _FreeRow({
    required this.product,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.glowSm,
          border: Border.all(color: AppColors.outlineVariant.withAlpha(51)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductThumb(imageAsset: product.imageAsset, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (categoryLabel != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _CategoryChip(label: categoryLabel!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              textDirection: TextDirection.ltr,
              size: 22,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Glance Entry Card ────────────────────────────────────────────────────

/// Tappable entry card that opens the "שגרת השבוע שלי" screen.
/// Placed in the collection screen between the health card and tab content.
class WeekGlanceEntryCard extends StatelessWidget {
  const WeekGlanceEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/week-glance'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.glowSm,
          border: Border.all(
            color: AppColors.outlineVariant.withAlpha(51), // /20 opacity
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withAlpha(127),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_view_week,
                size: 26,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.weekGlanceTitle,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.onSurface,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.weekGlanceEntrySubtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              textDirection: TextDirection.ltr,
              size: 20,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Archive Row ───────────────────────────────────────────────────────────────

class _ArchiveRow extends StatelessWidget {
  final MasterProduct product;
  final AppLocalizations l;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _ArchiveRow({
    required this.product,
    required this.l,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.glowSm,
          border: Border.all(color: AppColors.outlineVariant.withAlpha(51)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.7,
              child: ProductThumb(imageAsset: product.imageAsset, size: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface.withAlpha(178),
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant.withAlpha(153),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (categoryLabel != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _CategoryChip(label: categoryLabel!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l.collectionArchiveBadge,
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
