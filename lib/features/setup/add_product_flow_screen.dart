import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/weekday_picker.dart';
import 'barcode_scan_sheet.dart';

const _uuid = Uuid();

// Hebrew abbreviated day labels (Sunday-first, 0-indexed).
const _heAbbrLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];

enum _Step { search, category, slot, days, placement, success }

/// Multi-step "add product" wizard for returning users.
/// Accessed via route `/add-product`.
class AddProductFlowScreen extends ConsumerStatefulWidget {
  const AddProductFlowScreen({super.key});

  @override
  ConsumerState<AddProductFlowScreen> createState() =>
      _AddProductFlowScreenState();
}

class _AddProductFlowScreenState extends ConsumerState<AddProductFlowScreen> {
  _Step _step = _Step.search;

  // Step 1 state
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Chosen product (set after step 1)
  MasterProduct? _product;

  // Step 2: category override (ephemeral)
  String? _catIdOverride;

  // Step 3: slot selection
  // null = not yet chosen
  Set<Slot>? _chosenSlots;

  // Step 4: days
  Set<int> _chosenDays = {0, 1, 2, 3, 4, 5, 6};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _effectiveCatId =>
      _catIdOverride ?? _product?.categoryId ?? '';

  // Determine default slots for a product.
  Set<Slot> _defaultSlots(MasterProduct p) {
    if (p.morningConfig != null && p.eveningConfig != null) {
      return {Slot.morning, Slot.evening};
    }
    if (p.morningConfig != null) return {Slot.morning};
    return {Slot.evening};
  }

  void _pickProduct(MasterProduct p) {
    setState(() {
      _product = p;
      _catIdOverride = null;
      _chosenSlots = _defaultSlots(p);
      _chosenDays = {0, 1, 2, 3, 4, 5, 6};
      _step = _Step.category;
    });
  }

  void _advance() {
    final next = switch (_step) {
      _Step.search => _Step.category,
      _Step.category => _Step.slot,
      _Step.slot => _Step.days,
      _Step.days => _Step.placement,
      _Step.placement => _Step.success,
      _Step.success => _Step.success,
    };

    // Skip slot step if the product only supports one slot
    if (next == _Step.slot) {
      final p = _product!;
      final hasBoth = p.morningConfig != null && p.eveningConfig != null;
      if (!hasBoth) {
        // preselect the single available slot and skip straight to days
        _chosenSlots = _defaultSlots(p);
        setState(() => _step = _Step.days);
        return;
      }
    }

    if (next == _Step.success) {
      _save();
      return;
    }

    setState(() => _step = next);
  }

  void _goBack() {
    if (_step == _Step.search) {
      context.pop();
      return;
    }
    final prev = switch (_step) {
      _Step.category => _Step.search,
      _Step.slot => _Step.category,
      _Step.days => _Step.slot,
      _Step.placement => _Step.days,
      _Step.success => _Step.placement,
      _Step.search => _Step.search,
    };
    // If slot step was skipped coming forward, skip backward too
    if (prev == _Step.slot) {
      final p = _product!;
      final hasBoth = p.morningConfig != null && p.eveningConfig != null;
      if (!hasBoth) {
        setState(() => _step = _Step.category);
        return;
      }
    }
    setState(() => _step = prev);
  }

  Future<void> _save() async {
    final p = _product;
    if (p == null) return;
    final repo = ref.read(userDataRepositoryProvider);
    final slots = _chosenSlots ?? _defaultSlots(p);
    final now = DateTime.now();
    for (final slot in slots) {
      await repo.upsertSelection(
        ProductSelection(
          id: _uuid.v4(),
          productId: p.id,
          slot: slot,
          isSelected: true,
          lastModified: now,
        ),
      );
      await repo.upsertSchedule(
        WeekdaySchedule(
          id: _uuid.v4(),
          productId: p.id,
          slot: slot,
          weekdays: _chosenDays,
          lastModified: now,
        ),
      );
    }
    setState(() => _step = _Step.success);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_step == _Step.success) {
      return _SuccessScreen(
        product: _product!,
        chosenSlots: _chosenSlots ?? _defaultSlots(_product!),
        chosenDays: _chosenDays,
        l: l,
        onDone: () => context.pop(),
      );
    }

    final masterAsync = ref.watch(masterContentProvider);
    final customAsync = ref.watch(customProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        showBack: true,
        onBack: _goBack,
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final customProds = customAsync.valueOrNull ?? [];
          final allProducts = [
            ...master.products,
            ...customProds.map((p) => p.toMasterProduct()),
          ];

          return switch (_step) {
            _Step.search => _SearchStep(
                controller: _searchCtrl,
                query: _query,
                allProducts: allProducts,
                l: l,
                onPickProduct: _pickProduct,
                onScan: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BarcodeScanSheet(),
                ),
              ),
            _Step.category => _CategoryStep(
                product: _product!,
                categories: master.categories,
                effectiveCatId: _effectiveCatId,
                locale: l.localeName,
                l: l,
                onPickCategory: (catId) =>
                    setState(() => _catIdOverride = catId),
                onNext: _advance,
              ),
            _Step.slot => _SlotStep(
                product: _product!,
                chosenSlots: _chosenSlots ?? _defaultSlots(_product!),
                l: l,
                onChanged: (slots) => setState(() => _chosenSlots = slots),
                onNext: _advance,
              ),
            _Step.days => _DaysStep(
                chosenDays: _chosenDays,
                l: l,
                onChanged: (days) => setState(() => _chosenDays = days),
                onNext: _advance,
              ),
            _Step.placement => _PlacementStep(
                product: _product!,
                effectiveCatId: _effectiveCatId,
                chosenSlots: _chosenSlots ?? _defaultSlots(_product!),
                allProducts: allProducts,
                categories: master.categories,
                morningSelections:
                    ref.watch(selectionsProvider(Slot.morning)).valueOrNull ??
                        [],
                eveningSelections:
                    ref.watch(selectionsProvider(Slot.evening)).valueOrNull ??
                        [],
                l: l,
                onAdd: _advance,
              ),
            _Step.success => const SizedBox.shrink(), // handled above
          };
        },
      ),
    );
  }
}

// ── Step 1: Search ─────────────────────────────────────────────────────────────

class _SearchStep extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final List<MasterProduct> allProducts;
  final AppLocalizations l;
  final void Function(MasterProduct) onPickProduct;
  final VoidCallback onScan;

  const _SearchStep({
    required this.controller,
    required this.query,
    required this.allProducts,
    required this.l,
    required this.onPickProduct,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase().trim();
    final filtered = allProducts
        .where((p) {
          if (p.isDeprecated) return false;
          if (q.isEmpty) return true;
          return p.name.toLowerCase().contains(q) ||
              (p.brand?.toLowerCase().contains(q) ?? false);
        })
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              // Search field
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: TextField(
                  controller: controller,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.productSelV3SearchHint,
                    hintStyle: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline.withAlpha(153),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.onSurfaceVariant, size: 20),
                    suffixIcon: controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: controller.clear,
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.onSurfaceVariant),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 4),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Scan button
              GestureDetector(
                onTap: onScan,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 18, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        l.productSelV3ScanTab,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l.productSelNoProducts,
                    style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductPickRow(
                        key: Key('add_flow_row_${p.id}'),
                        product: p,
                        onTap: () => onPickProduct(p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductPickRow extends StatelessWidget {
  final MasterProduct product;
  final VoidCallback onTap;

  const _ProductPickRow({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.glowSm,
        ),
        child: Row(
          children: [
            ProductThumb(imageAsset: product.imageAsset, size: 50),
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
                  if (product.brand != null && product.brand!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Confirm category ──────────────────────────────────────────────────

class _CategoryStep extends StatelessWidget {
  final MasterProduct product;
  final List<Category> categories;
  final String effectiveCatId;
  final String locale;
  final AppLocalizations l;
  final ValueChanged<String> onPickCategory;
  final VoidCallback onNext;

  const _CategoryStep({
    required this.product,
    required this.categories,
    required this.effectiveCatId,
    required this.locale,
    required this.l,
    required this.onPickCategory,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.addProductConfirmCategory,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                // Product preview card
                _ProductPreviewCard(product: product, locale: locale),
                const SizedBox(height: 20),
                // Category chip picker
                _InlineCategoryPicker(
                  categories: categories,
                  selected: effectiveCatId,
                  locale: locale,
                  onPick: onPickCategory,
                ),
              ],
            ),
          ),
        ),
        _BottomCta(label: 'המשך', onTap: onNext),
      ],
    );
  }
}

// ── Step 3: Choose slot ────────────────────────────────────────────────────────

class _SlotStep extends StatelessWidget {
  final MasterProduct product;
  final Set<Slot> chosenSlots;
  final AppLocalizations l;
  final ValueChanged<Set<Slot>> onChanged;
  final VoidCallback onNext;

  const _SlotStep({
    required this.product,
    required this.chosenSlots,
    required this.l,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasMorning = product.morningConfig != null;
    final hasEvening = product.eveningConfig != null;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.addProductChooseSlot,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                // Both option (only when product supports both)
                if (hasMorning && hasEvening)
                  _SlotOption(
                    label: l.addProductSlotBoth,
                    icon: Icons.brightness_auto_rounded,
                    isSelected: chosenSlots.length == 2,
                    onTap: () => onChanged({Slot.morning, Slot.evening}),
                  ),
                if (hasMorning) ...[
                  const SizedBox(height: 10),
                  _SlotOption(
                    label: l.addProductSlotMorning,
                    icon: Icons.wb_sunny_rounded,
                    isSelected: chosenSlots.length == 1 &&
                        chosenSlots.contains(Slot.morning),
                    onTap: () => onChanged({Slot.morning}),
                  ),
                ],
                if (hasEvening) ...[
                  const SizedBox(height: 10),
                  _SlotOption(
                    label: l.addProductSlotEvening,
                    icon: Icons.dark_mode_rounded,
                    isSelected: chosenSlots.length == 1 &&
                        chosenSlots.contains(Slot.evening),
                    onTap: () => onChanged({Slot.evening}),
                  ),
                ],
              ],
            ),
          ),
        ),
        _BottomCta(label: 'המשך', onTap: chosenSlots.isNotEmpty ? onNext : () {}),
      ],
    );
  }
}

class _SlotOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withAlpha(200)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.glowSm,
          border: isSelected
              ? Border.all(color: AppColors.primary.withAlpha(80))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Choose days ────────────────────────────────────────────────────────

class _DaysStep extends StatelessWidget {
  final Set<int> chosenDays;
  final AppLocalizations l;
  final ValueChanged<Set<int>> onChanged;
  final VoidCallback onNext;

  const _DaysStep({
    required this.chosenDays,
    required this.l,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.addProductChooseDays,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                WeekdayPicker(
                  selectedDays: chosenDays,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        _BottomCta(
          label: 'המשך',
          onTap: chosenDays.isNotEmpty ? onNext : () {},
        ),
      ],
    );
  }
}

// ── Step 5: Suggested placement ───────────────────────────────────────────────

class _PlacementStep extends StatelessWidget {
  final MasterProduct product;
  final String effectiveCatId;
  final Set<Slot> chosenSlots;
  final List<MasterProduct> allProducts;
  final List<Category> categories;
  final List<ProductSelection> morningSelections;
  final List<ProductSelection> eveningSelections;
  final AppLocalizations l;
  final VoidCallback onAdd;

  const _PlacementStep({
    required this.product,
    required this.effectiveCatId,
    required this.chosenSlots,
    required this.allProducts,
    required this.categories,
    required this.morningSelections,
    required this.eveningSelections,
    required this.l,
    required this.onAdd,
  });

  // Returns the placement description text for the primary slot.
  String _placementText() {
    final primarySlot =
        chosenSlots.contains(Slot.morning) ? Slot.morning : Slot.evening;
    final selections =
        primarySlot == Slot.morning ? morningSelections : eveningSelections;

    final selectedIds = selections
        .where((s) => s.isSelected && s.productId != product.id)
        .map((s) => s.productId)
        .toSet();

    final catOrderById = {for (final c in categories) c.id: c.order};

    // Products already selected in this slot, sorted by category order
    final slotProducts = allProducts
        .where((p) =>
            selectedIds.contains(p.id) &&
            !p.isDeprecated &&
            p.configForSlot(primarySlot) != null)
        .toList()
      ..sort((a, b) {
        final ao = (catOrderById[a.categoryId] ?? 99) * 1000 +
            (a.configForSlot(primarySlot)?.order ?? 999);
        final bo = (catOrderById[b.categoryId] ?? 99) * 1000 +
            (b.configForSlot(primarySlot)?.order ?? 999);
        return ao.compareTo(bo);
      });

    final newCatOrder = catOrderById[effectiveCatId] ?? 99;

    // Find immediately before / after based on category order
    MasterProduct? before;
    MasterProduct? after;

    for (final p in slotProducts) {
      final pCatOrder = catOrderById[p.categoryId] ?? 99;
      if (pCatOrder <= newCatOrder) {
        before = p;
      } else {
        after ??= p;
      }
    }

    if (before != null && after != null) {
      return l.addProductPlacement(before.name, after.name);
    }
    if (before != null) {
      return l.addProductPlacementAfter(before.name);
    }
    return l.addProductPlacementGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final placement = _placementText();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.addProductPlacementTitle,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppColors.glowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProductThumb(
                              imageAsset: product.imageAsset, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              placement,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 13,
                                height: 1.5,
                              ),
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
        ),
        _BottomCta(label: l.addProductCta, onTap: onAdd),
      ],
    );
  }
}

// ── Success screen ─────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final MasterProduct product;
  final Set<Slot> chosenSlots;
  final Set<int> chosenDays;
  final AppLocalizations l;
  final VoidCallback onDone;

  const _SuccessScreen({
    required this.product,
    required this.chosenSlots,
    required this.chosenDays,
    required this.l,
    required this.onDone,
  });

  String _daysLabel() {
    final sorted = chosenDays.toList()..sort();
    return sorted.map((d) => _heAbbrLabels[d]).join(', ');
  }

  String _subtext() {
    final days = _daysLabel();
    if (chosenSlots.contains(Slot.morning) &&
        chosenSlots.contains(Slot.evening)) {
      return l.addProductSuccessSubBoth(days);
    }
    if (chosenSlots.contains(Slot.morning)) {
      return l.addProductSuccessSubMorning(days);
    }
    return l.addProductSuccessSubEvening(days);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.addProductSuccess,
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtext(),
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            PrimaryButton(
              label: 'סיום',
              trailingIcon: Icons.arrow_forward,
              onTap: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared private widgets ────────────────────────────────────────────────────

class _ProductPreviewCard extends StatelessWidget {
  final MasterProduct product;
  final String locale;

  const _ProductPreviewCard({required this.product, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Row(
        children: [
          ProductThumb(imageAsset: product.imageAsset, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cat.id == selected
                    ? AppColors.primary
                    : AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                cat.localizedName(locale),
                style: AppTypography.labelSm.copyWith(
                  color: cat.id == selected ? Colors.white : AppColors.primary,
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

class _BottomCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomCta({required this.label, required this.onTap});

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
      child: PrimaryButton(
        label: label,
        trailingIcon: Icons.arrow_forward,
        onTap: onTap,
      ),
    );
  }
}
