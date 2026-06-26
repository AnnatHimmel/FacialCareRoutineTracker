import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../domain/entities/sub_category.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/conflict_resolver.dart';
import '../../domain/services/routine_scheduler.dart';
import '../../domain/services/default_schedule.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../domain/services/product_sorter.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/fixed_slot_chip.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import 'add_custom_product_sheet.dart';
import 'barcode_scan_sheet.dart';

const _uuid = Uuid();

const _catIcon = <String, IconData>{
  'cat-cleanser': Icons.soap,
  'cat-retinoid': Icons.biotech,
  'cat-toner': Icons.water_drop,
  'cat-serum': Icons.science,
  'cat-moisturizer': Icons.spa,
  'cat-oil': Icons.opacity,
  'cat-spf': Icons.wb_sunny,
};


String? _getCatHint(String catId, AppLocalizations l) => switch (catId) {
  'cat-cleanser' => l.catHintCleanser,
  'cat-retinoid' => l.catHintRetinoid,
  'cat-toner' => l.catHintToner,
  'cat-serum' => l.catHintSerum,
  'cat-moisturizer' => l.catHintMoisturizer,
  'cat-oil' => l.catHintOil,
  'cat-spf' => l.catHintSpf,
  _ => null,
};

String _getCatUsage(String catId, AppLocalizations l) => switch (catId) {
  'cat-cleanser' => l.catUsageCleanser,
  'cat-retinoid' => l.catUsageRetinoid,
  'cat-toner' => l.catUsageToner,
  'cat-serum' => l.catUsageSerum,
  'cat-moisturizer' => l.catUsageMoisturizer,
  'cat-oil' => l.catUsageOil,
  'cat-spf' => l.catUsageSpf,
  _ => '',
};

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool isTabDestination;
  /// When provided the screen renders without its own Scaffold/AppBar and
  /// the summary CTA calls this instead of navigating to the schedule screen.
  final VoidCallback? onDone;

  const ProductSelectionScreen({
    super.key,
    this.fromSetup = false,
    this.isTabDestination = false,
    this.onDone,
  });

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  // V3 guided flow state
  String _v3Tab = 'search'; // 'search' | 'scan'
  bool _hasChanges = false;

  // Browse view state (also reused by V3 search pane)
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Slot? _slotFilter;

  // ── Write-drain guard ──────────────────────────────────────────────────────
  // Tracks every in-flight mutation future so the CTA can await them all
  // before navigating (prevents the write/read race on the summary screen).
  final Set<Future<void>> _pendingWrites = {};

  void _track(Future<void> op) {
    _pendingWrites.add(op);
    op.whenComplete(() => _pendingWrites.remove(op));
  }

  Future<void> _flushWrites() async {
    while (_pendingWrites.isNotEmpty) {
      await Future.wait(_pendingWrites.toList());
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    // Fire-and-forget background fetch; silently updates cache if network available.
    ref.read(masterContentRefreshProvider)();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToSchedule(BuildContext context) {
    if (widget.fromSetup) {
      context.push('/setup/schedule?from=setup');
    } else {
      context.push('/products/schedule');
    }
  }

  Map<String, Set<Slot>> _buildSelMap(
    List<ProductSelection> morning,
    List<ProductSelection> evening,
  ) {
    final map = <String, Set<Slot>>{};
    for (final s in morning.where((s) => s.isSelected)) {
      map.putIfAbsent(s.productId, () => {}).add(Slot.morning);
    }
    for (final s in evening.where((s) => s.isSelected)) {
      map.putIfAbsent(s.productId, () => {}).add(Slot.evening);
    }
    return map;
  }

  Future<void> _confirmBack(BuildContext context) async {
    if (!_hasChanges) {
      _doBack(context);
      return;
    }
    final l = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.unsavedChangesTitle),
        content: Text(l.productSelUnsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.productSelGoBackAnyway),
          ),
        ],
      ),
    );
    if ((leave ?? false) && context.mounted) _doBack(context);
  }

  void _doBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/today');
      }
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleProduct(
    MasterProduct product,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morningSelections,
    List<ProductSelection> eveningSelections, {
    Slot? filterSlot,
  }) async {
    _hasChanges = true;
    final isOn = selMap.containsKey(product.id);
    if (isOn) {
      await _setSlot(product, Slot.morning, false, morningSelections);
      await _setSlot(product, Slot.evening, false, eveningSelections);
    } else {
      if (filterSlot != null && product.configForSlot(filterSlot) != null) {
        final list = filterSlot == Slot.morning ? morningSelections : eveningSelections;
        await _setSlot(product, filterSlot, true, list);
      } else {
        if (product.morningConfig != null) {
          await _setSlot(product, Slot.morning, true, morningSelections);
        }
        if (product.eveningConfig != null) {
          await _setSlot(product, Slot.evening, true, eveningSelections);
        }
      }
    }
  }

  Future<void> _setTiming(
    MasterProduct product,
    Slot slot,
    bool enabled,
    List<ProductSelection> morningSelections,
    List<ProductSelection> eveningSelections,
  ) async {
    final list = slot == Slot.morning ? morningSelections : eveningSelections;
    await _setSlot(product, slot, enabled, list);
  }

  Future<void> _setSlot(
    MasterProduct product,
    Slot slot,
    bool isSelected,
    List<ProductSelection> existing,
  ) async {
    final scheduler = ref.read(routineSchedulerProvider);
    final matches = existing
        .where((s) => s.productId == product.id && s.slot == slot)
        .toList();
    if (matches.isNotEmpty) {
      for (final match in matches) {
        await scheduler.upsertSelection(
          match.copyWith(isSelected: isSelected, lastModified: DateTime.now()),
        );
      }
    } else if (isSelected) {
      await scheduler.upsertSelection(
        ProductSelection(
          id: _uuid.v4(),
          productId: product.id,
          slot: slot,
          isSelected: true,
          lastModified: DateTime.now(),
        ),
      );
    }

    // Guard: a capped (weekly-max) product must never end up selected with a
    // slot but no scheduled days. Seed an evenly-spread default for the slot
    // when it has no schedule yet (PRD §15.5).
    if (isSelected) {
      await _ensureCappedSchedule(scheduler, product, slot);
      // Immediately resolve any within-slot conflicts introduced by this
      // selection. conflictAutoFixProvider only runs at cold start — without
      // this call a product selected mid-session would show conflicts until
      // the next app restart.
      await _resolveSlotConflicts(scheduler, product.id, slot);
    }
  }

  /// Resolves within-slot incompatibility conflicts for [slot] after a product
  /// is newly selected. Mirrors the core logic of [conflictAutoFixProvider] but
  /// runs inline so the fix is applied in the same session as the selection.
  Future<void> _resolveSlotConflicts(
    RoutineScheduler scheduler,
    String newProductId,
    Slot slot,
  ) async {
    final master = ref.read(masterContentProvider).valueOrNull;
    if (master == null) return;

    final selections = ref.read(selectionsProvider(slot)).valueOrNull ?? [];
    // Include the newly-selected product explicitly — the stream may not have
    // updated yet since the DB write completes asynchronously.
    final selectedIds = {
      ...selections.where((s) => s.isSelected).map((s) => s.productId),
      newProductId,
    };

    final customProds = ref.read(customProductsProvider).valueOrNull ?? [];
    final allProducts = [
      ...master.products,
      ...customProds.map((p) => p.toMasterProduct()),
    ];

    final slotProducts = allProducts
        .where((p) => selectedIds.contains(p.id) && p.configForSlot(slot) != null)
        .toList();

    var schedules = ref.read(allSchedulesProvider).valueOrNull ?? const [];
    final mutedConflicts = ref.read(mutedConflictsProvider).valueOrNull ?? [];
    final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

    final checker = IncompatibilityChecker();
    final conflicts = checker.getConflictsForDay(
      morningProducts: slot == Slot.morning ? slotProducts : [],
      eveningProducts: slot == Slot.evening ? slotProducts : [],
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedRuleIds,
    );

    final seen = <String>{};
    final active = conflicts.where((c) {
      if (c.isMuted) return false;
      final key = ([c.productA.id, c.productB.id]..sort()).join('|');
      return seen.add(key);
    }).toList();

    if (active.isEmpty) return;

    const resolver = ConflictResolver();
    for (final conflict in active) {
      final resolution = resolver.resolve(
        productA: conflict.productA,
        productB: conflict.productB,
        slot: slot,
        schedules: schedules,
      );

      for (final m in resolution.mutations) {
        if (m.productId != newProductId) {
          // For existing products, only apply a slot-separation: clearing a
          // bi-slot product from this slot keeps it in its other slot with no
          // frequency loss, so it is always safe. Day-separation on existing
          // products is intentionally skipped — those remain advisory warnings.
          final otherSlot = slot == Slot.morning ? Slot.evening : Slot.morning;
          final movedProd =
              allProducts.where((p) => p.id == m.productId).firstOrNull;
          final isBiSlot = movedProd?.configForSlot(otherSlot) != null;
          if (!isBiSlot || m.days.isNotEmpty) continue;
        }

        final existing = schedules
            .where((s) => s.productId == m.productId && s.slot == m.slot)
            .firstOrNull;

        // Don't overwrite a schedule the user explicitly set.
        if (existing != null && existing.weekdays.isNotEmpty) continue;

        final updated = WeekdaySchedule(
          id: existing?.id ?? 'autofix-${m.productId}-${m.slot.name}',
          productId: m.productId,
          slot: m.slot,
          weekdays: m.days,
          lastModified: DateTime.now(),
        );
        await scheduler.upsertSchedule(updated);
        final idx = schedules
            .indexWhere((s) => s.productId == m.productId && s.slot == m.slot);
        if (idx >= 0) {
          schedules = [...schedules]..[idx] = updated;
        } else {
          schedules = [...schedules, updated];
        }
      }
    }
  }

  /// Seeds a spread [WeekdaySchedule] for a newly-selected capped product when
  /// the given slot has no schedule. No-op for daily products or when a schedule
  /// already exists.
  Future<void> _ensureCappedSchedule(
    RoutineScheduler scheduler,
    MasterProduct product,
    Slot slot,
  ) async {
    final config =
        slot == Slot.morning ? product.morningConfig : product.eveningConfig;
    final rule = config?.frequencyRule;
    if (rule is! WeeklyMaxRule) return;

    final schedules = ref.read(allSchedulesProvider).valueOrNull ?? const [];
    final hasSchedule =
        schedules.any((s) => s.productId == product.id && s.slot == slot);
    if (hasSchedule) return;

    final days = spreadWeekdays(rule.maxPerWeek);
    if (days.isEmpty) return;

    await scheduler.upsertSchedule(WeekdaySchedule(
      id: _uuid.v4(),
      productId: product.id,
      slot: slot,
      weekdays: days.toSet(),
      lastModified: DateTime.now(),
    ));
  }

  void _openProductDetail(BuildContext context, MasterProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomProductSheet(
        viewProduct: product,
        isUserProduct: product.addedInVersion == 'custom',
      ),
    );
  }

  void _editCustomProduct(BuildContext context, MasterProduct product) {
    final customProds = ref.read(customProductsProvider).valueOrNull ?? [];
    final UserCustomProduct? customProd = customProds
        .cast<UserCustomProduct?>()
        .firstWhere((p) => p?.id == product.id, orElse: () => null);
    if (customProd == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomProductSheet(initialProduct: customProd),
    );
  }

  void _showBarcodeScan(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScanSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final customAsync = ref.watch(customProductsProvider);

    final body = masterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.genericError(e))),
      data: (master) {
        final morning = morningAsync.valueOrNull ?? [];
        final evening = eveningAsync.valueOrNull ?? [];
        final selMap = _buildSelMap(morning, evening);
        final categories = [...master.categories]
          ..sort((a, b) => a.order.compareTo(b.order));
        final customProds = customAsync.valueOrNull ?? [];
        final allProducts = [
          ...master.products,
          ...customProds.map((p) => p.toMasterProduct()),
        ];

        if (widget.isTabDestination) {
          return _buildBrowse(context, allProducts, categories,
              master.subcategories, selMap, morning, evening, l);
        }
        return _buildGuided(context, allProducts, categories,
            master.subcategories, selMap, morning, evening, l);
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.isTabDestination
          ? const GlowAppBar()
          : GlowAppBar(
              showBack: true,
              onBack: () => _confirmBack(context),
            ),
      body: body,
      resizeToAvoidBottomInset: false,
      floatingActionButton: widget.isTabDestination && !kIsWeb
          ? _BarcodeFAB(onTap: () => _showBarcodeScan(context))
          : null,
    );
  }

  // ── Browse view (tab destination) ──────────────────────────────────────────

  Widget _buildBrowse(
    BuildContext context,
    List<MasterProduct> allProducts,
    List<Category> categories,
    List<SubCategory> subcategories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
    AppLocalizations l,
  ) {
    final query = _searchQuery.toLowerCase().trim();

    // Filter products
    final filtered = allProducts.where((p) {
      if (p.isDeprecated) return false;
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) {
        return false;
      }
      if (_slotFilter == Slot.morning && p.morningConfig == null) return false;
      if (_slotFilter == Slot.evening && p.eveningConfig == null) return false;
      return true;
    }).toList();

    // Group by category (preserving category order)
    final catProducts = <String, List<MasterProduct>>{};
    for (final product in filtered) {
      catProducts.putIfAbsent(product.categoryId, () => []).add(product);
    }
    // Sort within each category by slot order (slot filter applied above).
    // When no slot filter, use morning order with evening as fallback.
    final browseSlot = _slotFilter ?? Slot.morning;
    final browseCmp = ProductSorter.adminComparator(
      categories: categories,
      subcategories: subcategories,
      slot: browseSlot,
    );
    for (final list in catProducts.values) {
      list.sort(browseCmp);
    }

    final totalSelected = selMap.length;
    final orderedCategories =
        categories.where((c) => catProducts.containsKey(c.id)).toList();

    return Column(
      children: [
        // Sticky search + filter bar
        _BrowseFilterBar(
          controller: _searchController,
          slotFilter: _slotFilter,
          onSlotFilter: (s) => setState(() => _slotFilter = s),
          selectedCount: totalSelected,
          l: l,
        ),
        // Scrollable product list
        Expanded(
          child: orderedCategories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          l.productSelNoProducts,
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: orderedCategories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == orderedCategories.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _AddCustomProductCTA(
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddCustomProductSheet(
                              initialName: _searchQuery.trim().isEmpty
                                  ? null
                                  : _searchQuery.trim(),
                            ),
                          ),
                        ),
                      );
                    }
                    final cat = orderedCategories[index];
                    final products = catProducts[cat.id]!;
                    final selectedInCat =
                        products.where((p) => selMap.containsKey(p.id)).length;
                    return _CategorySection(
                      key: Key('cat_section_${cat.id}'),
                      cat: cat,
                      products: products,
                      selMap: selMap,
                      selectedInCat: selectedInCat,
                      catUsage: _getCatUsage(cat.id, l),
                      onToggle: (p) async {
                        _track(_toggleProduct(p, selMap, morning, evening));
                      },
                      onTimingChange: (p, slot, enabled) async {
                        _track(_setTiming(p, slot, enabled, morning, evening));
                      },
                      onEdit: (p) => _editCustomProduct(context, p),
                      onOpenDetail: (p) => _openProductDetail(context, p),
                      l: l,
                      locale: l.localeName,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Guided flow V3 (setup) ─────────────────────────────────────────────────

  Widget _buildGuided(
    BuildContext context,
    List<MasterProduct> allProducts,
    List<Category> categories,
    List<SubCategory> subcategories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
    AppLocalizations l,
  ) {
    final selectedCount = selMap.length;
    final selectedPids = selMap.keys.toList();

    // Popular products: all non-deprecated, sorted by canonical admin order.
    // Guided view has no active slot filter; morning order used as the primary key.
    final popularProducts = allProducts
        .where((p) => !p.isDeprecated)
        .toList()
      ..sort(ProductSorter.adminComparator(
        categories: categories,
        subcategories: subcategories,
        slot: Slot.morning,
      ));

    // Search-filtered products (name OR brand)
    final query = _searchQuery.toLowerCase().trim();
    final searchResults = query.isNotEmpty
        ? allProducts
            .where((p) =>
                !p.isDeprecated &&
                (p.name.toLowerCase().contains(query) ||
                    (p.brand?.toLowerCase().contains(query) ?? false)))
            .toList()
        : null;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.productSelV3Title,
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.productSelV3Subtitle,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Tab toggle: חיפוש | סריקה
              _V3TabToggle(
                value: _v3Tab,
                searchLabel: l.productSelV3SearchTab,
                scanLabel: l.productSelV3ScanTab,
                onChange: (t) {
                  setState(() {
                    _v3Tab = t;
                    if (t == 'search') _searchController.clear();
                  });
                },
              ),
            ],
          ),
        ),
        // ── Scrollable content ────────────────────────────────────────────
        Expanded(
          child: _v3Tab == 'search'
              ? _V3SearchPane(
                  controller: _searchController,
                  searchHint: l.productSelV3SearchHint,
                  popularLabel: l.productSelV3Popular,
                  products: searchResults ?? popularProducts,
                  isSearchResult: searchResults != null,
                  selMap: selMap,
                  onToggle: (p) async { _track(_toggleProduct(p, selMap, morning, evening)); },
                  onAddCustom: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddCustomProductSheet(
                      initialName: _searchQuery.trim().isEmpty
                          ? null
                          : _searchQuery.trim(),
                    ),
                  ),
                  onOpenDetail: (p) => _openProductDetail(context, p),
                )
              : const _V3ScanPane(),
        ),
        // ── Bottom tray ───────────────────────────────────────────────────
        _V3BottomTray(
          selectedCountLabel: l.productSelV3SelectedCount(selectedCount),
          ctaLabel: l.productSelV3ShelfCTA,
          ctaEnabled: selectedCount > 0,
          onNext: () async {
            await _flushWrites();
            if (!mounted) return;
            if (widget.onDone != null) {
              widget.onDone!();
            } else {
              _goToSchedule(context);
            }
          },
        ),
      ],
    );
  }
}

// ── V3 Tab toggle ─────────────────────────────────────────────────────────────

class _V3TabToggle extends StatelessWidget {
  final String value;
  final String searchLabel;
  final String scanLabel;
  final ValueChanged<String> onChange;

  const _V3TabToggle({
    required this.value,
    required this.searchLabel,
    required this.scanLabel,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          _Tab(
            label: searchLabel,
            icon: Icons.search_rounded,
            isSelected: value == 'search',
            onTap: () => onChange('search'),
          ),
          _Tab(
            label: scanLabel,
            icon: Icons.qr_code_scanner_rounded,
            isSelected: value == 'scan',
            onTap: () => onChange('scan'),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isSelected ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── V3 Search pane ────────────────────────────────────────────────────────────

class _V3SearchPane extends StatelessWidget {
  final TextEditingController controller;
  final String searchHint;
  final String popularLabel;
  final List<MasterProduct> products;
  final bool isSearchResult;
  final Map<String, Set<Slot>> selMap;
  final Future<void> Function(MasterProduct) onToggle;
  final VoidCallback onAddCustom;
  final void Function(MasterProduct) onOpenDetail;

  const _V3SearchPane({
    required this.controller,
    required this.searchHint,
    required this.popularLabel,
    required this.products,
    required this.isSearchResult,
    required this.selMap,
    required this.onToggle,
    required this.onAddCustom,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Container(
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
                hintText: searchHint,
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline.withAlpha(153),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => controller.clear(),
                        child: const Icon(Icons.close_rounded,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                isDense: true,
              ),
            ),
          ),
        ),
        // Manual-add card — prominent, directly under search field
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: _AddCustomProductCTA(
            title: l.productSelManualCardTitle,
            subtitle: l.productSelManualCardSub,
            onTap: onAddCustom,
          ),
        ),
        // Section label
        if (!isSearchResult)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  popularLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        // Product list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _V3FinderRow(
                  key: Key('v3_row_${p.id}'),
                  product: p,
                  isSelected: selMap.containsKey(p.id),
                  onTap: () => onToggle(p),
                  onOpenDetail: () => onOpenDetail(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── V3 Finder row (simplified — name + brand, checkbox, no slot chips) ───────

class _V3FinderRow extends StatelessWidget {
  final MasterProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onOpenDetail;

  const _V3FinderRow({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryFixed.withAlpha(180)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.glowSm,
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withAlpha(80), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Left: product info — opens detail screen
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenDetail,
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
                        if (product.brand != null &&
                            product.brand!.isNotEmpty) ...[
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
                ],
              ),
            ),
          ),
          // Right: selection checkbox — toggles selection
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outline,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── V3 Scan pane (inline live scanner) ────────────────────────────────────────

/// Embeds the real [BarcodeScanView] directly in the guided scan tab so the
/// camera starts scanning right away — a single screen, no separate sheet.
class _V3ScanPane extends StatelessWidget {
  const _V3ScanPane();

  @override
  Widget build(BuildContext context) {
    // Cream layout — BarcodeScanView owns the bounded viewfinder card, the
    // animated laser, the in-card hint, and the below-card gallery button.
    return const BarcodeScanView();
  }
}

// ── V3 Bottom tray ────────────────────────────────────────────────────────────

class _V3BottomTray extends StatelessWidget {
  final String selectedCountLabel;
  final String ctaLabel;
  final bool ctaEnabled;
  final VoidCallback onNext;

  const _V3BottomTray({
    required this.selectedCountLabel,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(242),
        boxShadow: AppColors.navGlow,
        border: const Border(
            top: BorderSide(color: AppColors.primaryFixed, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCountLabel,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: ctaEnabled ? 1.0 : 0.45,
            child: IgnorePointer(
              ignoring: !ctaEnabled,
              child: PrimaryButton(
                label: ctaLabel,
                trailingIcon: Icons.auto_awesome_rounded,
                onTap: onNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Browse filter bar ─────────────────────────────────────────────────────────

class _BrowseFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final Slot? slotFilter;
  final ValueChanged<Slot?> onSlotFilter;
  final int selectedCount;
  final AppLocalizations l;

  const _BrowseFilterBar({
    required this.controller,
    required this.slotFilter,
    required this.onSlotFilter,
    required this.selectedCount,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: l.myProductsSearchHint,
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline.withAlpha(153),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => controller.clear(),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.onSurfaceVariant),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips + selected count
          Row(
            children: [
              _SlotChip(
                label: l.productSelFilterAll,
                isSelected: slotFilter == null,
                onTap: () => onSlotFilter(null),
              ),
              const SizedBox(width: 8),
              _SlotChip(
                label: l.slotMorning,
                icon: Icons.wb_sunny_rounded,
                activeColor: AppColors.secondaryContainer,
                activeTextColor: AppColors.secondary,
                isSelected: slotFilter == Slot.morning,
                onTap: () => onSlotFilter(
                    slotFilter == Slot.morning ? null : Slot.morning),
              ),
              const SizedBox(width: 8),
              _SlotChip(
                label: l.slotEvening,
                icon: Icons.dark_mode_rounded,
                activeColor: AppColors.tertiaryFixed,
                activeTextColor: AppColors.onTertiaryContainer,
                isSelected: slotFilter == Slot.evening,
                onTap: () => onSlotFilter(
                    slotFilter == Slot.evening ? null : Slot.evening),
              ),
              const Spacer(),
              if (selectedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$selectedCount',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    this.icon,
    this.activeColor = AppColors.primaryFixed,
    this.activeTextColor = AppColors.primary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeTextColor : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? activeTextColor : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category section (browse view) ────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final Category cat;
  final List<MasterProduct> products;
  final Map<String, Set<Slot>> selMap;
  final int selectedInCat;
  final String catUsage;
  final Future<void> Function(MasterProduct) onToggle;
  final Future<void> Function(MasterProduct, Slot, bool) onTimingChange;
  final void Function(MasterProduct) onEdit;
  final void Function(MasterProduct)? onOpenDetail;
  final AppLocalizations l;
  final String locale;

  const _CategorySection({
    super.key,
    required this.cat,
    required this.products,
    required this.selMap,
    required this.selectedInCat,
    required this.catUsage,
    required this.onToggle,
    required this.onTimingChange,
    required this.onEdit,
    this.onOpenDetail,
    required this.l,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              _CategoryGlyph(categoryId: cat.id, size: 32, active: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.localizedName(locale),
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (selectedInCat > 0)
                Text(
                  l.productSelCategorySelected(selectedInCat),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        // Products
        for (int i = 0; i < products.length; i++)
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, i < products.length - 1 ? 10 : 0),
            child: _SelectRow(
              key: Key('browse_row_${products[i].id}'),
              product: products[i],
              selectedSlots: selMap[products[i].id] ?? {},
              categoryUsage: catUsage,
              onToggle: () => onToggle(products[i]),
              onTimingChange: (slot, enabled) =>
                  onTimingChange(products[i], slot, enabled),
              onEdit: () => onEdit(products[i]),
              onViewDetail: onOpenDetail != null
                  ? () => onOpenDetail!(products[i])
                  : null,
              l: l,
            ),
          ),
      ],
    );
  }
}

// ── Barcode FAB ───────────────────────────────────────────────────────────────

class _BarcodeFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _BarcodeFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
      label: Text(
        AppLocalizations.of(context)!.barcodeScan,
        style: AppTypography.labelMd.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step
                    ? AppColors.primary
                    : AppColors.primaryFixed.withAlpha(102),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Category glyph ─────────────────────────────────────────────────────────────

class _CategoryGlyph extends StatelessWidget {
  final String categoryId;
  final double size;
  final bool active;

  const _CategoryGlyph({
    required this.categoryId,
    this.size = 40,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _catIcon[categoryId] ?? Icons.category;
    final iconSize = size >= 48 ? 26.0 : size >= 40 ? 22.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primaryFixed.withAlpha(128),
        borderRadius: BorderRadius.circular(size >= 48 ? 16 : 10),
      ),
      child: Icon(icon,
          size: iconSize, color: active ? Colors.white : AppColors.primary),
    );
  }
}

// ── SelectRow ──────────────────────────────────────────────────────────────────

class _SelectRow extends StatefulWidget {
  final MasterProduct product;
  final Set<Slot> selectedSlots;
  final String categoryUsage;
  final VoidCallback onToggle;
  final void Function(Slot slot, bool enabled) onTimingChange;
  final VoidCallback? onEdit;
  final VoidCallback? onViewDetail;
  final AppLocalizations l;

  const _SelectRow({
    super.key,
    required this.product,
    required this.selectedSlots,
    required this.categoryUsage,
    required this.onToggle,
    required this.onTimingChange,
    this.onEdit,
    this.onViewDetail,
    required this.l,
  });

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  bool _infoOpen = false;

  bool get _isCustom => widget.product.addedInVersion == 'custom';

  bool get _isFlexible =>
      widget.product.morningConfig != null &&
      widget.product.eveningConfig != null;

  bool get _isOn => widget.selectedSlots.isNotEmpty;
  bool get _showTiming => _isFlexible && _isOn;
  bool get _isExpanded => _showTiming || _infoOpen;

  String _frequencyLabel() {
    final config =
        widget.product.morningConfig ?? widget.product.eveningConfig;
    if (config == null) return widget.l.onboardingFrequencyDaily;
    final f = config.frequencyRule;
    return f is WeeklyMaxRule
        ? widget.l.onboardingFrequencyWeekly(f.maxPerWeek)
        : widget.l.onboardingFrequencyDaily;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final p = widget.product;
    final isOn = _isOn;
    final isExpanded = _isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.primaryFixed.withAlpha(77)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isExpanded ? 26 : 9999),
        border: Border.all(
          color: isOn
              ? AppColors.primary.withAlpha(77)
              : Colors.transparent,
        ),
        boxShadow: isOn ? null : AppColors.glowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProductThumb(imageAsset: p.imageAsset, size: 50),
                            if (isOn)
                              Positioned(
                                bottom: -2,
                                left: -2,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (!_isFlexible) ...[
                                const SizedBox(height: 4),
                                FixedSlotChip(product: p),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _infoOpen = !_infoOpen),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: _infoOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_infoOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),
                  if (p.localizedComment(l.localeName).isNotEmpty)
                    Text(
                      p.localizedComment(l.localeName),
                      textAlign: TextAlign.start,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  if (widget.categoryUsage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.categoryUsage,
                            textAlign: TextAlign.start,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.productSelFrequencyLabel + _frequencyLabel(),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCustom && widget.onEdit != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l.customProductEditButton,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.onViewDetail != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onViewDetail,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            l.productDetailViewDetails,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (_showTiming)
            _TimingControl(
              amSelected: widget.selectedSlots.contains(Slot.morning),
              pmSelected: widget.selectedSlots.contains(Slot.evening),
              onToggleAm: () => widget.onTimingChange(
                  Slot.morning,
                  !widget.selectedSlots.contains(Slot.morning)),
              onTogglePm: () => widget.onTimingChange(
                  Slot.evening,
                  !widget.selectedSlots.contains(Slot.evening)),
              l: l,
            ),
        ],
      ),
    );
  }
}

// ── Timing control ─────────────────────────────────────────────────────────────

class _TimingControl extends StatelessWidget {
  final bool amSelected;
  final bool pmSelected;
  final VoidCallback onToggleAm;
  final VoidCallback onTogglePm;
  final AppLocalizations l;

  const _TimingControl({
    required this.amSelected,
    required this.pmSelected,
    required this.onToggleAm,
    required this.onTogglePm,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                l.productSelTimingLabel,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TimingPill(
                    label: l.slotMorning,
                    icon: Icons.wb_sunny_rounded,
                    isSelected: amSelected,
                    activeColor: AppColors.primaryContainer,
                    onTap: onToggleAm,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TimingPill(
                    label: l.slotEvening,
                    icon: Icons.dark_mode_rounded,
                    isSelected: pmSelected,
                    activeColor: AppColors.tertiary,
                    onTap: onTogglePm,
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

class _TimingPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TimingPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.outlineVariant.withAlpha(128),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Custom Product CTA card ───────────────────────────────────────────────

class _AddCustomProductCTA extends StatelessWidget {
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;

  const _AddCustomProductCTA({required this.onTap, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final displayTitle = title ?? l.addCustomProductCtaTitle;
    final displaySubtitle = subtitle ?? l.addCustomProductCtaSub;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(128),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.primaryFixed,
            width: 3.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              textDirection: TextDirection.ltr,
              color: AppColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
