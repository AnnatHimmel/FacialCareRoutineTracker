import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/product_thumb.dart';
import '../setup/add_custom_product_sheet.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final morningSelections =
        ref.watch(selectionsProvider(Slot.morning)).valueOrNull ?? [];
    final eveningSelections =
        ref.watch(selectionsProvider(Slot.evening)).valueOrNull ?? [];
    final masterAsync = ref.watch(masterContentProvider);
    final allProductsList = ref.watch(allProductsProvider).valueOrNull ?? const <MasterProduct>[];

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
        final allDisplayProducts = allProductsList
            .where((p) => !p.isDeprecated &&
                (selectedIds.contains(p.id) || p.editable))
            .toList();

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
              // ── Week Glance entry card (always visible) ──────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: WeekGlanceEntryCard(),
                ),
              ),
              _FreeProductSliver(
                products: allDisplayProducts,
                l: l,
                categoryLabel: categoryLabel,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
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
                  isUserProduct: product.editable,
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
      onTap: () => context.push('/week-glance?from=collection'),
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