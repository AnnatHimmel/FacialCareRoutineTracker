import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_override.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/sub_category.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/product_sorter.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import 'add_custom_product_sheet.dart';

class CategoryReviewScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const CategoryReviewScreen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  @override
  ConsumerState<CategoryReviewScreen> createState() =>
      _CategoryReviewScreenState();
}

class _CategoryReviewScreenState extends ConsumerState<CategoryReviewScreen> {
  // Persisted overrides (category and subcategory) per productId
  final Map<String, String> _categoryOverrides = {};
  final Map<String, String?> _subCategoryOverrides = {};

  // Currently open edit card
  String? _editingProductId;

  // Draft state while editing (valid only when _editingProductId != null)
  String? _editDraftCatId;
  String? _editDraftSubCatId;

  // Original values captured when edit opened — used to restore subcat
  // when the user picks back the original category
  String? _editOrigCatId;
  String? _editOrigSubCatId;

  bool _overridesLoaded = false;

  String _effectiveCatId(MasterProduct p) =>
      _categoryOverrides[p.id] ?? p.categoryId;

  String? _effectiveSubCatId(MasterProduct p) =>
      _subCategoryOverrides.containsKey(p.id)
          ? _subCategoryOverrides[p.id]
          : p.subCategoryId;

  void _openEdit(MasterProduct p) {
    final origCat = _effectiveCatId(p);
    final origSubCat = _effectiveSubCatId(p);
    setState(() {
      _editingProductId = p.id;
      _editOrigCatId = origCat;
      _editOrigSubCatId = origSubCat;
      _editDraftCatId = origCat;
      _editDraftSubCatId = origSubCat;
    });
  }

  void _closeEdit() => setState(() => _editingProductId = null);

  void _draftPickCategory(String catId) {
    setState(() {
      _editDraftCatId = catId;
      // Restore original subcat when the user picks back the original category;
      // reset to null when a different category is chosen.
      if (catId == _editOrigCatId) {
        _editDraftSubCatId = _editOrigSubCatId;
      } else {
        _editDraftSubCatId = null;
      }
    });
  }

  void _draftPickSubCategory(String? subCatId) {
    setState(() => _editDraftSubCatId = subCatId);
  }

  void _saveEdit(String productId) {
    final catId = _editDraftCatId!;
    final subCatId = _editDraftSubCatId;
    setState(() {
      _categoryOverrides[productId] = catId;
      _subCategoryOverrides[productId] = subCatId;
      _editingProductId = null;
    });
    // Persist — fire and forget
    ref.read(userDataRepositoryProvider).upsertCategoryOverride(
          CategoryOverride(
            id: 'cat-override-$productId',
            productId: productId,
            categoryId: catId,
            subCategoryId: subCatId,
            lastModified: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final savedOverridesAsync = ref.watch(categoryOverridesProvider);

    // Seed local maps from DB once on first successful load.
    if (!_overridesLoaded) {
      savedOverridesAsync.whenData((saved) {
        _overridesLoaded = true;
        for (final o in saved) {
          _categoryOverrides[o.productId] = o.categoryId;
          _subCategoryOverrides[o.productId] = o.subCategoryId;
        }
      });
    }

    return masterAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(l.genericError(e)))),
      data: (master) {
        final morning = morningAsync.valueOrNull ?? [];
        final evening = eveningAsync.valueOrNull ?? [];

        final selectedIds = {
          for (final s in morning.where((s) => s.isSelected)) s.productId,
          for (final s in evening.where((s) => s.isSelected)) s.productId,
        };

        final products = master.products
            .where((p) => !p.isDeprecated && selectedIds.contains(p.id))
            .toList()
          ..sort(ProductSorter.adminComparator(
            categories: master.categories,
            subcategories: master.subcategories,
            slot: Slot.morning,
            categoryOverrides: _categoryOverrides,
            subCategoryOverrides: {
              for (final e in _subCategoryOverrides.entries)
                if (e.value != null) e.key: e.value!,
            },
          ));

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: widget.onBack,
                  title: l.categoryReviewTitle,
                  subtitle: l.categoryReviewSubtitle,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    children: [
                      if (products.isEmpty)
                        _EmptyState(message: l.categoryReviewEmpty)
                      else
                        for (final product in products)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProductReviewCard(
                              key: Key('review_card_${product.id}'),
                              product: product,
                              categories: master.categories,
                              subcategories: master.subcategories,
                              effectiveCatId: _effectiveCatId(product),
                              effectiveSubCatId: _effectiveSubCatId(product),
                              isEditing: _editingProductId == product.id,
                              draftCatId: _editingProductId == product.id
                                  ? _editDraftCatId
                                  : null,
                              draftSubCatId: _editingProductId == product.id
                                  ? _editDraftSubCatId
                                  : null,
                              locale: l.localeName,
                              onEditToggle: () {
                                if (_editingProductId == product.id) {
                                  _closeEdit();
                                } else {
                                  _openEdit(product);
                                }
                              },
                              onPickCategory: _draftPickCategory,
                              onPickSubCategory: _draftPickSubCategory,
                              onSave: () => _saveEdit(product.id),
                              onOpenDetail: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddCustomProductSheet(
                                  viewProduct: product,
                                  isUserProduct:
                                      product.addedInVersion == 'custom',
                                ),
                              ),
                            ),
                          ),
                      _AddMoreButton(
                        label: l.categoryReviewAddMore,
                        onTap: widget.onBack,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                _BottomCTA(
                  label: l.categoryReviewCTA,
                  onTap: widget.onNext,
                  enabled: products.isNotEmpty,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;

  const _Header({
    required this.onBack,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.onSurface, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product review card ─────────────────────────────────────────────────────────

class _ProductReviewCard extends StatelessWidget {
  final MasterProduct product;
  final List<Category> categories;
  final List<SubCategory> subcategories;
  final String effectiveCatId;
  final String? effectiveSubCatId;
  final bool isEditing;
  final String? draftCatId;
  final String? draftSubCatId;
  final String locale;
  final VoidCallback onEditToggle;
  final ValueChanged<String> onPickCategory;
  final ValueChanged<String?> onPickSubCategory;
  final VoidCallback onSave;
  final VoidCallback? onOpenDetail;

  const _ProductReviewCard({
    super.key,
    required this.product,
    required this.categories,
    required this.subcategories,
    required this.effectiveCatId,
    required this.effectiveSubCatId,
    required this.isEditing,
    required this.draftCatId,
    required this.draftSubCatId,
    required this.locale,
    required this.onEditToggle,
    required this.onPickCategory,
    required this.onPickSubCategory,
    required this.onSave,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // While editing, show the live draft values in the header so the user sees
    // a preview of what they're selecting before tapping Save.
    final displayCatId =
        isEditing ? (draftCatId ?? effectiveCatId) : effectiveCatId;
    final displaySubCatId =
        isEditing ? draftSubCatId : effectiveSubCatId;

    final catName = categories
            .cast<Category?>()
            .firstWhere((c) => c?.id == displayCatId, orElse: () => null)
            ?.localizedName(locale) ??
        displayCatId;

    final subCatName = displaySubCatId == null
        ? null
        : subcategories
            .cast<SubCategory?>()
            .firstWhere((s) => s?.id == displaySubCatId,
                orElse: () => null)
            ?.localizedName(locale);

    // Subcategories that belong to the current draft category (for the picker)
    final activeDraftCat = draftCatId ?? effectiveCatId;
    final subcatsForDraftCat = subcategories
        .where((s) => s.categoryId == activeDraftCat)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.glowSm,
        border: isEditing
            ? Border.all(color: AppColors.primary.withAlpha(102))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  ProductThumb(imageAsset: product.imageAsset, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _CalmChip(label: catName),
                            if (subCatName != null)
                              _CalmChip(
                                label: subCatName,
                                isSubCategory: true,
                              ),
                            _ChangeCategoryButton(
                              isEditing: isEditing,
                              onTap: onEditToggle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Inline edit panel
          if (isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),

                  // Category picker
                  _InlineCategoryPicker(
                    categories: categories,
                    selected: draftCatId ?? effectiveCatId,
                    locale: locale,
                    onPick: onPickCategory,
                  ),

                  // Subcategory picker (only when the active category has subcategories)
                  if (subcatsForDraftCat.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InlineSubCategoryPicker(
                      subcategories: subcatsForDraftCat,
                      selected: draftSubCatId,
                      locale: locale,
                      onPick: onPickSubCategory,
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: onSave,
                      child: Text(l.saveAction),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Change-category toggle button ──────────────────────────────────────────────

class _ChangeCategoryButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onTap;

  const _ChangeCategoryButton({
    required this.isEditing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isEditing ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Icon(
          Icons.edit_rounded,
          size: 14,
          color: isEditing ? Colors.white : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Calm chip (category or sub-category display) ───────────────────────────────

class _CalmChip extends StatelessWidget {
  final String label;
  final bool isSubCategory;

  const _CalmChip({required this.label, this.isSubCategory = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSubCategory
            ? AppColors.surfaceLow.withAlpha(180)
            : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
        border: isSubCategory
            ? Border.all(
                color: AppColors.outlineVariant.withAlpha(120), width: 1)
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: isSubCategory ? FontWeight.w500 : FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Inline category picker ─────────────────────────────────────────────────────

class _InlineCategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String selected;
  final String locale;
  final ValueChanged<String> onPick;

  const _InlineCategoryPicker({
    required this.categories,
    required this.selected,
    required this.locale,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categories)
          GestureDetector(
            onTap: () => onPick(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cat.id == selected
                    ? AppColors.primary
                    : AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                cat.localizedName(locale),
                style: AppTypography.labelSm.copyWith(
                  color:
                      cat.id == selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Inline sub-category picker ─────────────────────────────────────────────────

class _InlineSubCategoryPicker extends StatelessWidget {
  final List<SubCategory> subcategories;
  final String? selected;
  final String locale;
  final ValueChanged<String?> onPick;

  const _InlineSubCategoryPicker({
    required this.subcategories,
    required this.selected,
    required this.locale,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "None" option
        GestureDetector(
          onTap: () => onPick(null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected == null
                  ? AppColors.secondary
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              l.customProductSubCategoryNone,
              style: AppTypography.labelSm.copyWith(
                color: selected == null
                    ? Colors.white
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        for (final sub in subcategories)
          GestureDetector(
            onTap: () => onPick(sub.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sub.id == selected
                    ? AppColors.secondary
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                sub.localizedName(locale),
                style: AppTypography.labelSm.copyWith(
                  color: sub.id == selected
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add more products button ────────────────────────────────────────────────────

class _AddMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddMoreButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow.withAlpha(128),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: AppColors.outlineVariant.withAlpha(153),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded,
                size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky bottom CTA ─────────────────────────────────────────────────────────

class _BottomCTA extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _BottomCTA({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(242),
        boxShadow: AppColors.navGlow,
        border: const Border(
            top: BorderSide(color: AppColors.primaryFixed, width: 0.5)),
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: IgnorePointer(
          ignoring: !enabled,
          child: PrimaryButton(
            label: label,
            trailingIcon: Icons.arrow_forward,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
