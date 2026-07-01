import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../domain/services/product_sorter.dart';
import '../../domain/services/routine_service.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/weekday_picker.dart';

String _getDayFullName(int d, AppLocalizations l) => switch (d) {
      0 => l.calendarDayFullSun,
      1 => l.calendarDayFullMon,
      2 => l.calendarDayFullTue,
      3 => l.calendarDayFullWed,
      4 => l.calendarDayFullThu,
      5 => l.calendarDayFullFri,
      6 => l.calendarDayFullSat,
      _ => '',
    };

String _getDayAbbrName(int d, AppLocalizations l) => switch (d) {
      0 => l.calendarDayAbbrevSun,
      1 => l.calendarDayAbbrevMon,
      2 => l.calendarDayAbbrevTue,
      3 => l.calendarDayAbbrevWed,
      4 => l.calendarDayAbbrevThu,
      5 => l.calendarDayAbbrevFri,
      6 => l.calendarDayAbbrevSat,
      _ => '',
    };

/// Renders a product name, wrapping Latin brand names as an LTR island so
/// they read correctly inside the RTL layout (mirrors the rest of the app).
Widget _productName(MasterProduct p,
    {double fontSize = 13, FontWeight weight = FontWeight.w700}) {
  final latin = p.name.codeUnits.every((c) => c < 128);
  final text = Text(
    p.name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.start,
    style: AppTypography.bodyMd.copyWith(
      color: AppColors.onSurface,
      fontWeight: weight,
      fontSize: fontSize,
    ),
  );
  return latin
      ? Directionality(textDirection: TextDirection.ltr, child: text)
      : text;
}

class ScheduleSetupScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool fromProducts;

  // Onboarding single-slot mode. When set, the screen renders only this slot
  // with a custom header (back arrow + step label) instead of GlowAppBar and
  // slot-tab-switcher. The caller provides onContinue and onBack callbacks.
  final Slot? onboardingSlot;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const ScheduleSetupScreen({
    super.key,
    this.fromSetup = false,
    this.fromProducts = false,
    this.onboardingSlot,
    this.onContinue,
    this.onBack,
  });

  @override
  ConsumerState<ScheduleSetupScreen> createState() =>
      _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends ConsumerState<ScheduleSetupScreen> {
  Slot _activeSlot = Slot.morning;
  Set<Slot> _visitedSlots = {Slot.morning};

  bool get _isOnboarding => widget.onboardingSlot != null;

  // View mode: 'days' (default) | 'products'
  String _viewMode = 'days';

  // Selected day in days mode (Sunday=0, same as DateTime.now().weekday % 7)
  int _selectedDay = DateTime.now().weekday % 7;
  bool _selectedDayInitialized = false;

  // Products mode state
  String? _openProductId; // which product row's day-editor is expanded
  bool _showDaily = false; // is the "every day" group expanded

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _rowKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.onboardingSlot != null) {
      _activeSlot = widget.onboardingSlot!;
      _visitedSlots = {widget.onboardingSlot!};
    }
  }

  /// Remove a single weekday for a product (used by the conflict "remove from
  /// {day}" action). Daily products with no override start as all-7.
  Future<void> _removeDay(String productId, int dayId) async {
    final schedules = ref.read(allSchedulesProvider).valueOrNull ?? [];
    final master = ref.read(masterContentProvider).valueOrNull;
    final product =
        master?.products.where((p) => p.id == productId).firstOrNull;
    final currentDays = product != null
        ? RoutineService.effectiveDays(product, _activeSlot, schedules)
        : <int>{};
    final updated = Set<int>.from(currentDays)..remove(dayId);
    await ref.read(routineServiceProvider).setDays(
          productId: productId,
          slot: _activeSlot,
          days: updated,
        );
  }

  /// Toggle a product's presence on a specific day (used in days mode).
  Future<void> _toggleDayForProduct(MasterProduct p, int dayId) async {
    final schedules = ref.read(allSchedulesProvider).valueOrNull ?? [];
    final current =
        RoutineService.effectiveDays(p, _activeSlot, schedules);
    final updated = Set<int>.from(current);
    if (updated.contains(dayId)) {
      updated.remove(dayId);
    } else {
      updated.add(dayId);
    }
    await ref.read(routineServiceProvider).setDays(
          productId: p.id,
          slot: _activeSlot,
          days: updated,
        );
  }

  /// Auto-fix all conflicts/overuse for the active slot.
  ///
  /// Delegates to [RoutineService.fixProblems], which handles conflict
  /// resolution, overuse pruning, and persistence. Surfaces a "what changed"
  /// dialog with an Undo that re-applies the inverse mutations.
  Future<void> _autoFix() async {
    final l = AppLocalizations.of(context)!;
    final scheduler = ref.read(routineServiceProvider);
    final master = ref.read(masterContentProvider).valueOrNull;
    if (master == null) return;

    final result = await scheduler.fixProblems(
      master: master,
      slot: _activeSlot,
    );

    if (result.isEmpty) return;

    final isEnglish = l.localeName == 'en';
    final descriptions = result.changeDescriptions
        .map((d) => isEnglish ? d.en : d.he)
        .toList();

    final summary = descriptions.isNotEmpty
        ? descriptions.join('\n')
        : l.autoFixAppliedFallback;

    if (!mounted) return;

    // Show a dialog with explicit "keep" and "undo" buttons. A SnackBar with a
    // single action reads as "cancel" in Hebrew, so the user had no clear path
    // to confirm the fix.
    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          summary,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.autoFixUndo,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.autoFixKeep,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldUndo == true && mounted) {
      await scheduler.applyMutationsPersisting(result.inverse);
    }
  }

  void _handleContinue(BuildContext context) {
    if (widget.fromSetup) {
      context.go('/setup/order?from=setup');
    } else if (_isProductsFlow) {
      // The shelf "add products" flow commits here — run the auto-sorter and
      // show its "routine ready" summary, which then hands off to the shelf.
      context.go('/routine-ready');
    } else {
      context.pop(true);
    }
  }

  bool get _isProductsFlow => widget.fromProducts && !widget.fromSetup;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _switchSlot(Slot slot) {
    setState(() {
      _activeSlot = slot;
      _visitedSlots = {..._visitedSlots, slot};
      _openProductId = null;
      _showDaily = false;
      _rowKeys.clear();
      _selectedDayInitialized = false; // recompute priority day for the new slot
    });
  }


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _isOnboarding ? null : const GlowAppBar(),
      bottomNavigationBar:
          _isOnboarding ? null : (_isProductsFlow ? null : AppBottomNav.setup(context)),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final morningSelections = morningAsync.valueOrNull ?? [];
          final eveningSelections = eveningAsync.valueOrNull ?? [];
          final schedules = schedulesAsync.valueOrNull ?? [];
          final mutedIds =
              (mutedAsync.valueOrNull ?? []).map((m) => m.ruleId).toSet();
                final allProducts = ref.watch(allProductsProvider).valueOrNull ?? const <MasterProduct>[];

          final morningSelectedIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningSelectedIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          final morningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  morningSelectedIds.contains(p.id) &&
                  p.morningConfig != null)
              .toList()
            ..sort(ProductSorter.adminComparator(
              categories: master.categories,
              subcategories: master.subcategories,
              slot: Slot.morning,
            ));
          final eveningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  eveningSelectedIds.contains(p.id) &&
                  p.eveningConfig != null)
              .toList()
            ..sort(ProductSorter.adminComparator(
              categories: master.categories,
              subcategories: master.subcategories,
              slot: Slot.evening,
            ));

          final activeProducts =
              _activeSlot == Slot.morning ? morningProducts : eveningProducts;

          final occasional = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is WeeklyMaxRule)
              .toList();
          final daily = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is DailyRule)
              .toList();
          final narrowed = daily
              .where((p) =>
                  RoutineService.effectiveDays(p, _activeSlot, schedules).length < 7)
              .toList();
          final everyDay = daily
              .where((p) =>
                  RoutineService.effectiveDays(p, _activeSlot, schedules).length == 7)
              .toList();
          final flexed = [...occasional, ...narrowed]
            ..sort(ProductSorter.adminComparator(
              categories: master.categories,
              subcategories: master.subcategories,
              slot: _activeSlot,
            ));

          final isEmpty = morningProducts.isEmpty && eveningProducts.isEmpty;

          // Guided AM→PM progression (unchanged behaviour)
          final activeSlots = [
            if (morningProducts.isNotEmpty) Slot.morning,
            if (eveningProducts.isNotEmpty) Slot.evening,
          ];
          final slotIdx = activeSlots.indexOf(_activeSlot).clamp(0, 99);
          final allVisited = activeSlots.every(_visitedSlots.contains);
          final nextSlot = (!allVisited && slotIdx < activeSlots.length - 1)
              ? activeSlots[slotIdx + 1]
              : null;
          final nextSlotRoutine = nextSlot == null
              ? null
              : nextSlot == Slot.morning
                  ? l.slotMorning
                  : l.slotEvening;
          final nextSlotIcon = nextSlot == null
              ? null
              : nextSlot == Slot.morning
                  ? Icons.wb_sunny_rounded
                  : Icons.dark_mode_rounded;

          final scheduler = ref.read(routineServiceProvider);
          final otherSlotProducts =
              _activeSlot == Slot.morning ? eveningProducts : morningProducts;

          // ── conflict + over-frequency computation for the ACTIVE slot ──
          // warningsForDayFrom is pure/synchronous; pass the full product lists
          // (not pre-filtered to the day) — it filters per-day internally.
          final Map<int, List<ConflictInfo>> activeDayPairs = {};
          final Map<int, List<({MasterProduct product, int count, int cap})>>
              overuseMap = {};
          final Set<String> cellSet = {};
          int zeroDayCount = 0;
          for (int d = 0; d < 7; d++) {
            final w = scheduler.warningsForDayFrom(
              master: master,
              slot: _activeSlot,
              weekday: d,
              slotProducts: activeProducts,
              otherSlotProducts: otherSlotProducts,
              schedules: schedules,
              mutedRuleIds: mutedIds,
            );
            if (w.conflicts.isNotEmpty) {
              activeDayPairs[d] = w.conflicts;
              for (final c in w.conflicts) {
                cellSet.add('${c.productA.id}-$d');
                cellSet.add('${c.productB.id}-$d');
              }
            }
            if (w.overused.isNotEmpty) {
              overuseMap[d] = w.overused
                  .map((e) => (product: e.product, count: e.count, cap: e.cap))
                  .toList();
            }
            // zeroDayCount is slot-level (constant across days); take from day 0
            if (d == 0) zeroDayCount = w.zeroDayCount;
          }
          final overuseDays = overuseMap.keys.toSet();

          // Combined issue days (conflict OR overuse)
          final issueDays = {...activeDayPairs.keys, ...overuseDays};

          final conflictDays = activeDayPairs.keys.toList()..sort();
          final pairCount =
              activeDayPairs.values.fold<int>(0, (a, b) => a + b.length);

          // Priority day: first issue day, else today, else first day with product
          if (!_selectedDayInitialized) {
            final today = DateTime.now().weekday % 7;
            int priorityDay;
            final sortedIssueDays = issueDays.toList()..sort();
            if (sortedIssueDays.isNotEmpty) {
              priorityDay = sortedIssueDays.first;
            } else {
              final firstProductDay = List.generate(7, (d) => d).firstWhere(
                (d) => activeProducts.any(
                    (p) => RoutineService.effectiveDays(p, _activeSlot, schedules).contains(d)),
                orElse: () => today,
              );
              priorityDay = issueDays.isEmpty ? firstProductDay : today;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_selectedDayInitialized) {
                setState(() {
                  _selectedDay = priorityDay;
                  _selectedDayInitialized = true;
                });
              }
            });
          }

          // per-slot issue totals for the tab badges
          int slotIssueCount(Slot tabSlot, List<MasterProduct> products) {
            final tabOtherProducts =
                tabSlot == Slot.morning ? eveningProducts : morningProducts;
            int total = 0;
            for (int d = 0; d < 7; d++) {
              final w = scheduler.warningsForDayFrom(
                master: master,
                slot: tabSlot,
                weekday: d,
                slotProducts: products,
                otherSlotProducts: tabOtherProducts,
                schedules: schedules,
                mutedRuleIds: mutedIds,
              );
              total += w.conflicts.length + w.overused.length;
            }
            return total;
          }

          final isEnglish = l.localeName == 'en';

          // ── days mode helpers ──
          final selectedDayProducts = activeProducts
              .where((p) =>
                  RoutineService.effectiveDays(p, _activeSlot, schedules)
                      .contains(_selectedDay))
              .toList();
          final notSelectedDayProducts = activeProducts
              .where((p) =>
                  !RoutineService.effectiveDays(p, _activeSlot, schedules)
                      .contains(_selectedDay))
              .toList();

          // Per-day product counts for the strip chips
          Map<int, int> dayProductCounts() {
            final counts = <int, int>{};
            for (int d = 0; d < 7; d++) {
              counts[d] = activeProducts
                  .where((p) =>
                      RoutineService.effectiveDays(p, _activeSlot, schedules).contains(d))
                  .length;
            }
            return counts;
          }

          final dayCounts = dayProductCounts();

          return Column(
            children: [
              if (_isOnboarding) ...[
                // Custom header block for onboarding single-slot mode
                SafeArea(
                  bottom: false,
                  child: _OnboardingScheduleHeader(
                    slot: _activeSlot,
                    onBack: widget.onBack!,
                    l: l,
                  ),
                ),
                if (!isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _ViewModeToggle(
                      viewMode: _viewMode,
                      onChanged: (v) => setState(() => _viewMode = v),
                    ),
                  ),
              ] else if (!isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _SlotTabSwitcher(
                    activeSlot: _activeSlot,
                    hasMorning: morningProducts.isNotEmpty,
                    hasEvening: eveningProducts.isNotEmpty,
                    morningIssues:
                        slotIssueCount(Slot.morning, morningProducts),
                    eveningIssues:
                        slotIssueCount(Slot.evening, eveningProducts),
                    visitedSlots: _visitedSlots,
                    onSelect: _switchSlot,
                    l: l,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ViewModeToggle(
                    viewMode: _viewMode,
                    onChanged: (v) => setState(() => _viewMode = v),
                  ),
                ),
              ],
              Expanded(
                child: isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l.scheduleNoProducts,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _viewMode == 'days'
                        ? ListView(
                            key: ValueKey('days-$_activeSlot'),
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            children: [
                              // Day strip
                              _DayStrip(
                                selectedDay: _selectedDay,
                                slot: _activeSlot,
                                dayCounts: dayCounts,
                                issueDays: issueDays,
                                onSelect: (d) => setState(() {
                                  _selectedDay = d;
                                  _selectedDayInitialized = true;
                                }),
                                l: l,
                              ),
                              const SizedBox(height: 12),
                              // Day summary card
                              _DaySummaryCard(
                                dayId: _selectedDay,
                                conflicts:
                                    activeDayPairs[_selectedDay] ?? [],
                                overusedProducts:
                                    overuseMap[_selectedDay] ?? [],
                                slot: _activeSlot,
                                categories: master.categories,
                                isEnglish: isEnglish,
                                onRemoveFromDay: _removeDay,
                                onAutoFix: (_) => _autoFix(),
                                l: l,
                              ),
                              const SizedBox(height: 16),
                              // Section: products on this day
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 4, left: 4, bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.checklist_rounded,
                                      size: 14,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'מוצרים ביום ${_getDayFullName(_selectedDay, l)} (${selectedDayProducts.length})',
                                      textAlign: TextAlign.start,
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final p in selectedDayProducts)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _DayProductCard(
                                    product: p,
                                    slot: _activeSlot,
                                    included: true,
                                    hasConflict: cellSet
                                        .contains('${p.id}-$_selectedDay'),
                                    isOverused: overuseMap[_selectedDay]
                                            ?.any((e) => e.product.id == p.id) ??
                                        false,
                                    categories: master.categories,
                                    isEnglish: isEnglish,
                                    onToggle: () => _toggleDayForProduct(
                                        p, _selectedDay),
                                    l: l,
                                  ),
                                ),
                              // Section: products NOT on this day
                              if (notSelectedDayProducts.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 4, left: 4, bottom: 8),
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          size: 14,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'לא בשימוש ב${_activeSlot == Slot.morning ? "בוקר" : "ערב"} ביום ${_getDayFullName(_selectedDay, l)} (${notSelectedDayProducts.length})',
                                          textAlign: TextAlign.start,
                                          style:
                                              AppTypography.labelMd.copyWith(
                                            color:
                                                AppColors.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                for (final p in notSelectedDayProducts)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: _DayProductCard(
                                      product: p,
                                      slot: _activeSlot,
                                      included: false,
                                      hasConflict: false,
                                      isOverused: false,
                                      categories: master.categories,
                                      isEnglish: isEnglish,
                                      onToggle: () => _toggleDayForProduct(
                                          p, _selectedDay),
                                      l: l,
                                    ),
                                  ),
                              ],
                            ],
                          )
                        : ListView(
                            key: ValueKey('products-$_activeSlot'),
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            children: [
                              // 1 · calm "by frequency" list
                              if (flexed.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 4, left: 4, bottom: 2),
                                  child: Text(
                                    '${l.scheduleByFrequency} (${flexed.length})',
                                    textAlign: TextAlign.start,
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                for (final p in flexed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _ListRow(
                                      key: _rowKeys.putIfAbsent(
                                          p.id, () => GlobalKey()),
                                      product: p,
                                      slot: _activeSlot,
                                      schedules: schedules,
                                      cellSet: cellSet,
                                      categories: master.categories,
                                      isEnglish: isEnglish,
                                      open: _openProductId == p.id,
                                      onToggleOpen: () => setState(() =>
                                          _openProductId =
                                              _openProductId == p.id
                                                  ? null
                                                  : p.id),
                                      selectedDays: RoutineService.effectiveDays(
                                          p, _activeSlot, schedules),
                                      onChanged: (days, existing) =>
                                          ref.read(routineServiceProvider).setDays(
                                            productId: p.id,
                                            slot: _activeSlot,
                                            days: days,
                                          ),
                                      l: l,
                                    ),
                                  ),
                              ],

                              // 2 · "every day" group, collapsed
                              if (everyDay.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _DailyGroup(
                                  products: everyDay,
                                  open: _showDaily,
                                  onToggle: () => setState(
                                      () => _showDaily = !_showDaily),
                                  slot: _activeSlot,
                                  schedules: schedules,
                                  cellSet: cellSet,
                                  categories: master.categories,
                                  isEnglish: isEnglish,
                                  openProductId: _openProductId,
                                  onToggleOpen: (id) => setState(() =>
                                      _openProductId =
                                          _openProductId == id ? null : id),
                                  effectiveDays: (p) =>
                                      RoutineService.effectiveDays(p, _activeSlot, schedules),
                                  onChanged: (id, days, existing) =>
                                      ref.read(routineServiceProvider).setDays(
                                        productId: id,
                                        slot: _activeSlot,
                                        days: days,
                                      ),
                                  l: l,
                                ),
                              ],
                            ],
                          ),
              ),
              if (_isOnboarding)
                _OnboardingScheduleCta(
                  l: l,
                  onContinue: widget.onContinue!,
                  hasConflicts: pairCount > 0,
                  conflictCount: conflictDays.length,
                  activeSlotLabel: _activeSlot == Slot.morning
                      ? l.slotMorning
                      : l.slotEvening,
                  hasZeroDays: zeroDayCount > 0,
                )
              else
                _BottomCta(
                  fromSetup: widget.fromSetup,
                  isProductsFlow: _isProductsFlow,
                  nextSlotRoutine: nextSlotRoutine,
                  nextSlotIcon: nextSlotIcon,
                  l: l,
                  hasConflicts: pairCount > 0,
                  conflictCount: conflictDays.length,
                  activeSlotLabel: _activeSlot == Slot.morning
                      ? l.slotMorning
                      : l.slotEvening,
                  hasZeroDays: zeroDayCount > 0,
                  onTap: nextSlot != null
                      ? () => _switchSlot(nextSlot)
                      : () => _handleContinue(context),
                  onBack: () => context.pop(),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Onboarding single-slot header ────────────────────────────────────────────
// Replaces GlowAppBar in onboarding mode. Matches the _Header style from
// CategoryReviewScreen: back arrow + title + step label + subtitle.
// A static context chip (non-tappable pill) identifies the slot being set up.

class _OnboardingScheduleHeader extends StatelessWidget {
  final Slot slot;
  final VoidCallback onBack;
  final AppLocalizations l;

  const _OnboardingScheduleHeader({
    required this.slot,
    required this.onBack,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final isMorning = slot == Slot.morning;
    final slotText = isMorning ? l.slotMorning : l.slotEvening;
    final chipLabel =
        isMorning ? l.scheduleContextChipMorning : l.scheduleContextChipEvening;
    final chipColor =
        isMorning ? AppColors.primaryContainer : AppColors.tertiary;
    final chipIcon =
        isMorning ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded;

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
                  l.scheduleHeaderWeekly,
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
          // Step label line
          Text(
            l.scheduleStepLabel(slotText),
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            l.scheduleSubtitleV3,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Static context chip (non-tappable)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chipIcon, size: 14, color: chipColor),
                const SizedBox(width: 6),
                Text(
                  chipLabel,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

// ── Onboarding schedule bottom CTA ──────────────────────────────────────────
// Single primary button (scheduleContinueToOrder) for onboarding mode.
// Does NOT use the AM→PM advancing logic of _BottomCta.

class _OnboardingScheduleCta extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onContinue;
  final bool hasConflicts;
  final int conflictCount;
  final String activeSlotLabel;
  final bool hasZeroDays;

  const _OnboardingScheduleCta({
    required this.l,
    required this.onContinue,
    required this.hasConflicts,
    required this.conflictCount,
    required this.activeSlotLabel,
    required this.hasZeroDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.navGlow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: l.scheduleContinueToOrder,
                onTap: hasZeroDays ? null : onContinue,
                trailingIcon: Icons.arrow_forward,
                height: 56,
              ),
              if (hasZeroDays) ...[
                const SizedBox(height: 6),
                Text(
                  l.scheduleZeroDayError(activeSlotLabel),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (hasConflicts) ...[
                const SizedBox(height: 6),
                Text(
                  l.scheduleConflictWarningCount(conflictCount, activeSlotLabel),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── View mode pill toggle ────────────────────────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  final String viewMode;
  final ValueChanged<String> onChanged;

  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: AppColors.soft,
      ),
      child: Row(
        children: [
          _PillOption(
            label: 'לפי ימים',
            icon: Icons.calendar_today_rounded,
            active: viewMode == 'days',
            onTap: () => onChanged('days'),
          ),
          _PillOption(
            label: 'לפי מוצרים',
            icon: Icons.format_list_bulleted_rounded,
            active: viewMode == 'products',
            onTap: () => onChanged('products'),
          ),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _PillOption({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: active ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: active
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day strip ────────────────────────────────────────────────────────────────

class _DayStrip extends StatelessWidget {
  final int selectedDay;
  final Slot slot;
  final Map<int, int> dayCounts;
  final Set<int> issueDays;
  final ValueChanged<int> onSelect;
  final AppLocalizations l;

  const _DayStrip({
    required this.selectedDay,
    required this.slot,
    required this.dayCounts,
    required this.issueDays,
    required this.onSelect,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = slot == Slot.morning
        ? AppColors.primaryContainer
        : AppColors.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int d = 0; d < 7; d++) _DayChip(
            dayId: d,
            label: _getDayAbbrName(d, l),
            count: dayCounts[d] ?? 0,
            selected: selectedDay == d,
            hasIssue: issueDays.contains(d),
            activeColor: activeColor,
            onTap: () => onSelect(d),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int dayId;
  final String label;
  final int count;
  final bool selected;
  final bool hasIssue;
  final Color activeColor;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayId,
    required this.label,
    required this.count,
    required this.selected,
    required this.hasIssue,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final squareBg = selected
        ? activeColor
        : count > 0
            ? AppColors.surfaceLow
            : Colors.transparent;
    final squareTextColor = selected ? Colors.white : AppColors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? activeColor
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: squareBg,
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? null
                      : Border.all(
                          color: count > 0
                              ? AppColors.outlineVariant.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 0 ? '$count' : '·',
                  style: AppTypography.labelMd.copyWith(
                    color: squareTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (hasIssue)
                PositionedDirectional(
                  top: -5,
                  end: -5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.priority_high_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day summary card ──────────────────────────────────────────────────────────

class _DaySummaryCard extends StatelessWidget {
  final int dayId;
  final List<ConflictInfo> conflicts;
  final List<({MasterProduct product, int count, int cap})> overusedProducts;
  final Slot slot;
  final List<Category> categories;
  final bool isEnglish;
  final Future<void> Function(String productId, int dayId) onRemoveFromDay;
  final Future<void> Function(List<ConflictInfo> conflicts) onAutoFix;
  final AppLocalizations l;

  const _DaySummaryCard({
    required this.dayId,
    required this.conflicts,
    required this.overusedProducts,
    required this.slot,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveFromDay,
    required this.onAutoFix,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final noteCount = conflicts.length + overusedProducts.length;
    final hasIssues = noteCount > 0;
    final dayName = _getDayFullName(dayId, l);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasIssues
                  ? AppColors.errorContainer
                  : AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              hasIssues
                  ? Icons.priority_high_rounded
                  : Icons.check_rounded,
              size: 18,
              color: hasIssues
                  ? AppColors.error
                  : AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasIssues
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.daySummaryNoteCount(noteCount, dayName),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.daySummaryNoteSub,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showIssueSheet(
                                  context, dayName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(9999),
                                  boxShadow: AppColors.glowSm,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.visibility_rounded,
                                        size: 14,
                                        color: AppColors.onPrimary),
                                    const SizedBox(width: 5),
                                    Text(
                                      l.issueActionReviewNotes,
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onAutoFix(conflicts),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_fix_high_rounded,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  l.issueActionAutoFix,
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.daySummaryAllGood(dayName),
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showIssueSheet(BuildContext context, String dayName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (ctx) => RoutineIssueSheet(
        dayId: dayId,
        dayName: dayName,
        conflicts: conflicts,
        overusedProducts: overusedProducts,
        slot: slot,
        categories: categories,
        isEnglish: isEnglish,
        onRemoveFromDay: onRemoveFromDay,
        l: l,
      ),
    );
  }
}

// ── Day product card ─────────────────────────────────────────────────────────

class _DayProductCard extends StatelessWidget {
  final MasterProduct product;
  final Slot slot;
  final bool included;
  final bool hasConflict;
  final bool isOverused;
  final List<Category> categories;
  final bool isEnglish;
  final VoidCallback onToggle;
  final AppLocalizations l;

  const _DayProductCard({
    required this.product,
    required this.slot,
    required this.included,
    required this.hasConflict,
    required this.isOverused,
    required this.categories,
    required this.isEnglish,
    required this.onToggle,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categories
        .where((c) => c.id == product.categoryId)
        .firstOrNull;

    // Schedule text
    final rule = product.configForSlot(slot)?.frequencyRule;
    final scheduleText = rule is WeeklyMaxRule
        ? l.scheduleRecommendedWeekly(rule.maxPerWeek)
        : l.scheduleRecommendedDaily;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
        border: hasConflict
            ? Border.all(color: AppColors.error.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          // Thumb
          ProductThumb(imageAsset: product.imageAsset, size: 44),
          const SizedBox(width: 10),
          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/collection/${product.id}'),
                  child: _productName(product, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (cat != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          cat.localizedName(isEnglish ? 'en' : 'he'),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.event_repeat_rounded,
                                  size: 9,
                                  color: AppColors.onSurfaceVariant),
                            ),
                            TextSpan(text: ' $scheduleText'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasConflict)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 9, color: AppColors.error),
                            const SizedBox(width: 3),
                            Text(
                              l.chipPossibleConflict,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.error,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isOverused)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_repeat_rounded,
                                size: 9, color: AppColors.error),
                            const SizedBox(width: 3),
                            Text(
                              l.chipHighUsage,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.error,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: included
                    ? AppColors.errorContainer
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                included
                    ? Icons.delete_outline_rounded
                    : Icons.add_rounded,
                size: 18,
                color: included
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Routine issue sheet (renamed from _ConflictSheet) ────────────────────────

class RoutineIssueSheet extends StatelessWidget {
  final int dayId;
  final String dayName;
  final List<ConflictInfo> conflicts;
  final List<({MasterProduct product, int count, int cap})> overusedProducts;
  final Slot slot;
  final List<Category> categories;
  final bool isEnglish;
  final Future<void> Function(String productId, int dayId) onRemoveFromDay;
  final AppLocalizations l;

  const RoutineIssueSheet({
    super.key,
    required this.dayId,
    required this.dayName,
    required this.conflicts,
    required this.overusedProducts,
    required this.slot,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveFromDay,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.issueSheetTitle(dayName),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.issueSheetSubtitle,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Conflicts section
                  if (conflicts.isNotEmpty) ...[
                    _SectionHeader(label: l.issueSheetConflictSection),
                    const SizedBox(height: 8),
                    for (int i = 0; i < conflicts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _ConflictSheetCard(
                        conflict: conflicts[i],
                        dayId: dayId,
                        dayName: dayName,
                        slot: slot,
                        categories: categories,
                        isEnglish: isEnglish,
                        onRemoveFromDay: onRemoveFromDay,
                        l: l,
                      ),
                    ],
                  ],
                  // Overuse section
                  if (overusedProducts.isNotEmpty) ...[
                    if (conflicts.isNotEmpty) const SizedBox(height: 20),
                    _SectionHeader(label: l.issueSheetOveruseSection),
                    const SizedBox(height: 8),
                    for (int i = 0; i < overusedProducts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _OveruseSheetCard(
                        entry: overusedProducts[i],
                        dayId: dayId,
                        categories: categories,
                        isEnglish: isEnglish,
                        onRemoveFromDay: onRemoveFromDay,
                        l: l,
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _OveruseSheetCard extends StatelessWidget {
  final ({MasterProduct product, int count, int cap}) entry;
  final int dayId;
  final List<Category> categories;
  final bool isEnglish;
  final Future<void> Function(String productId, int dayId) onRemoveFromDay;
  final AppLocalizations l;

  const _OveruseSheetCard({
    required this.entry,
    required this.dayId,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveFromDay,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categories
        .where((c) => c.id == entry.product.categoryId)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetProductRow(
            product: entry.product,
            category: cat,
            isEnglish: isEnglish,
          ),
          const SizedBox(height: 8),
          Text(
            l.issueSheetOveruseBody(entry.count, entry.cap),
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Primary action: remove from day
          GestureDetector(
            onTap: () {
              onRemoveFromDay(entry.product.id, dayId);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: AppColors.glowSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_rounded,
                      size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    l.issueActionRemoveFromDay,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary: keep anyway
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Text(
                l.issueActionKeep,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictSheetCard extends StatelessWidget {
  final ConflictInfo conflict;
  final int dayId;
  final String dayName;
  final Slot slot;
  final List<Category> categories;
  final bool isEnglish;
  final Future<void> Function(String productId, int dayId) onRemoveFromDay;
  final AppLocalizations l;

  const _ConflictSheetCard({
    required this.conflict,
    required this.dayId,
    required this.dayName,
    required this.slot,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveFromDay,
    required this.l,
  });

  MasterProduct get _movable {
    final aIsMovable =
        conflict.productA.configForSlot(slot)?.frequencyRule is WeeklyMaxRule;
    return aIsMovable ? conflict.productA : conflict.productB;
  }

  @override
  Widget build(BuildContext context) {
    final catA = categories
        .where((c) => c.id == conflict.productA.categoryId)
        .firstOrNull;
    final catB = categories
        .where((c) => c.id == conflict.productB.categoryId)
        .firstOrNull;
    final reason = conflict.localizedReason(isEnglish ? 'en' : 'he');
    final movable = _movable;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        boxShadow: AppColors.glowSm,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.block_rounded,
                  size: 14, color: AppColors.error),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.issueSheetConflictSection,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Product A row
          _SheetProductRow(
            product: conflict.productA,
            category: catA,
            isEnglish: isEnglish,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          // Product B row
          _SheetProductRow(
            product: conflict.productB,
            category: catB,
            isEnglish: isEnglish,
          ),
          if (reason != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded,
                    size: 12,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Primary action: remove movable product from day
          GestureDetector(
            onTap: () {
              onRemoveFromDay(movable.id, dayId);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: AppColors.glowSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_rounded,
                      size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.issueActionRemoveFromDayNamed(movable.name),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary actions row — Wrap so the two actions reflow on narrow
          // screens instead of overflowing horizontally.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  l.issueActionKeep,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                '|',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.outlineVariant.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Remove from today; "spread to week" — remove from day,
                  // let user reschedule manually (no free-slot finder in v1)
                  onRemoveFromDay(movable.id, dayId);
                  Navigator.of(context).pop();
                },
                child: Text(
                  l.issueActionAutoDistribute,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetProductRow extends StatelessWidget {
  final MasterProduct product;
  final Category? category;
  final bool isEnglish;

  const _SheetProductRow({
    required this.product,
    required this.category,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProductThumb(imageAsset: product.imageAsset, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _productName(product, fontSize: 12),
              if (category != null)
                Text(
                  category!.localizedName(isEnglish ? 'en' : 'he'),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Calm product row (read-only ribbon; tap to edit days) ───────────────────

class _MiniWeek extends StatelessWidget {
  final Set<int> days;
  final Slot slot;
  final String pid;
  final Set<String> cellSet;

  const _MiniWeek({
    required this.days,
    required this.slot,
    required this.pid,
    required this.cellSet,
  });

  @override
  Widget build(BuildContext context) {
    final onColor =
        slot == Slot.morning ? AppColors.primaryContainer : AppColors.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int d = 0; d < 7; d++) ...[
          if (d > 0) const SizedBox(width: 3),
          () {
            final on = days.contains(d);
            final conflict = on && cellSet.contains('$pid-$d');
            return Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: conflict
                    ? AppColors.error
                    : on
                        ? onColor
                        : const Color(0x1A000000),
              ),
            );
          }(),
        ],
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final MasterProduct product;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final Set<String> cellSet;
  final List<Category> categories;
  final bool isEnglish;
  final bool open;
  final VoidCallback onToggleOpen;
  final Set<int> selectedDays;
  final void Function(Set<int> weekdays, WeekdaySchedule? existing) onChanged;
  final AppLocalizations l;

  const _ListRow({
    super.key,
    required this.product,
    required this.slot,
    required this.schedules,
    required this.cellSet,
    required this.categories,
    required this.isEnglish,
    required this.open,
    required this.onToggleOpen,
    required this.selectedDays,
    required this.onChanged,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final existing = schedules
        .where((s) => s.productId == product.id && s.slot == slot)
        .firstOrNull;
    final rule = product.configForSlot(slot)?.frequencyRule;
    final cap = rule is WeeklyMaxRule ? rule.maxPerWeek : null;
    final count = selectedDays.length;
    final over = cap != null && count > cap;
    final everyDay = cap == null && count == 7;
    final hasConflict =
        List.generate(7, (d) => '${product.id}-$d').any(cellSet.contains);
    final freqText =
        cap != null ? l.scheduleRecommendedWeekly(cap) : l.scheduleRecommendedDaily;
    final cat = categories
        .where((c) => c.id == product.categoryId)
        .firstOrNull;

    return GlowCard(
      radius: 20,
      padding: EdgeInsets.zero,
      shadow: AppColors.glowSm,
      border: open
          ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleOpen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ProductThumb(imageAsset: product.imageAsset, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/collection/${product.id}'),
                          child: _productName(product, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _MiniWeek(
                              days: selectedDays,
                              slot: slot,
                              pid: product.id,
                              cellSet: cellSet,
                            ),
                            const SizedBox(width: 8),
                            if (over)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_rounded,
                                        size: 11, color: AppColors.error),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$count/$cap×',
                                      textDirection: TextDirection.ltr,
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                everyDay
                                    ? l.scheduleCountEveryDay
                                    : '$count/${cap ?? 7}',
                                textDirection: TextDirection.ltr,
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10,
                                ),
                              ),
                            if (cat != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    cat.localizedName(isEnglish ? 'en' : 'he'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasConflict) ...[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.priority_high_rounded,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Icon(
                        open ? Icons.expand_less_rounded : Icons.tune_rounded,
                        size: 17,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      freqText,
                      textAlign: TextAlign.start,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  WeekdayPicker(
                    selectedDays: selectedDays,
                    onChanged: (days) => onChanged(days, existing),
                  ),
                  if (over) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded,
                            size: 13, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l.scheduleOverCap(cap),
                            style: AppTypography.labelSm.copyWith(
                                color: AppColors.error, fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── "Every day" group (collapsed summary with stacked thumbs) ───────────────

class _DailyGroup extends StatelessWidget {
  final List<MasterProduct> products;
  final bool open;
  final VoidCallback onToggle;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final Set<String> cellSet;
  final List<Category> categories;
  final bool isEnglish;
  final String? openProductId;
  final ValueChanged<String> onToggleOpen;
  final Set<int> Function(MasterProduct p) effectiveDays;
  final void Function(String id, Set<int> days, WeekdaySchedule? existing)
      onChanged;
  final AppLocalizations l;

  const _DailyGroup({
    required this.products,
    required this.open,
    required this.onToggle,
    required this.slot,
    required this.schedules,
    required this.cellSet,
    required this.categories,
    required this.isEnglish,
    required this.openProductId,
    required this.onToggleOpen,
    required this.effectiveDays,
    required this.onChanged,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.scheduleCountEveryDay} (${products.length})',
                    textAlign: TextAlign.start,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                _StackedThumbs(products: products, max: 10),
                const SizedBox(width: 8),
                Icon(
                  open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (open)
          for (final p in products)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _ListRow(
                product: p,
                slot: slot,
                schedules: schedules,
                cellSet: cellSet,
                categories: categories,
                isEnglish: isEnglish,
                open: openProductId == p.id,
                onToggleOpen: () => onToggleOpen(p.id),
                selectedDays: effectiveDays(p),
                onChanged: (days, existing) => onChanged(p.id, days, existing),
                l: l,
              ),
            ),
      ],
    );
  }
}

class _StackedThumbs extends StatelessWidget {
  final List<MasterProduct> products;
  final int max;

  const _StackedThumbs({required this.products, this.max = 5});

  @override
  Widget build(BuildContext context) {
    final shown = products.take(max).toList();
    const thumbSize = 24.0;
    const step = 16.0;
    final width = shown.isEmpty ? 0.0 : thumbSize + (shown.length - 1) * step;
    return SizedBox(
      width: width,
      height: thumbSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * step,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                padding: const EdgeInsets.all(1.5),
                child: ProductThumb(
                    imageAsset: shown[i].imageAsset, size: thumbSize - 3),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Slot tab switcher ───────────────────────────────────────────────────────

class _SlotTabSwitcher extends StatelessWidget {
  final Slot activeSlot;
  final bool hasMorning;
  final bool hasEvening;
  final int morningIssues;
  final int eveningIssues;
  final Set<Slot> visitedSlots;
  final ValueChanged<Slot> onSelect;
  final AppLocalizations l;

  const _SlotTabSwitcher({
    required this.activeSlot,
    required this.hasMorning,
    required this.hasEvening,
    required this.morningIssues,
    required this.eveningIssues,
    required this.visitedSlots,
    required this.onSelect,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: AppColors.soft,
      ),
      child: Row(
        children: [
          _SlotTab(
            label: l.slotMorning,
            icon: Icons.wb_sunny_rounded,
            active: activeSlot == Slot.morning,
            isMorning: true,
            issueCount: morningIssues,
            isVisited: visitedSlots.contains(Slot.morning),
            onTap: hasMorning ? () => onSelect(Slot.morning) : null,
          ),
          _SlotTab(
            label: l.slotEvening,
            icon: Icons.dark_mode_rounded,
            active: activeSlot == Slot.evening,
            isMorning: false,
            issueCount: eveningIssues,
            isVisited: visitedSlots.contains(Slot.evening),
            onTap: hasEvening ? () => onSelect(Slot.evening) : null,
          ),
        ],
      ),
    );
  }
}

class _SlotTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isMorning;
  final int issueCount;
  final bool isVisited;
  final VoidCallback? onTap;

  const _SlotTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.isMorning,
    required this.issueCount,
    required this.isVisited,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg =
        isMorning ? AppColors.primaryContainer : AppColors.tertiary;
    const activeText = AppColors.onPrimary;
    final inactiveText = AppColors.onSurfaceVariant.withValues(alpha: 0.6);
    final hasIssues = issueCount > 0;
    final showVisited = isVisited && !active && !hasIssues;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 40,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: active ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: active ? activeText : inactiveText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: active ? activeText : inactiveText),
              if (hasIssues) ...[
                const SizedBox(width: 4),
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$issueCount',
                    style: AppTypography.labelSm.copyWith(
                      color: active ? AppColors.error : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ] else if (showVisited) ...[
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 11, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom CTA (unchanged behaviour) ────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool fromSetup;
  final bool isProductsFlow;
  final String? nextSlotRoutine;
  final IconData? nextSlotIcon;
  final AppLocalizations l;
  final VoidCallback onTap;
  final VoidCallback? onBack;
  final bool hasConflicts;
  final int conflictCount;
  final String activeSlotLabel;
  final bool hasZeroDays;

  const _BottomCta({
    required this.fromSetup,
    required this.isProductsFlow,
    required this.nextSlotRoutine,
    required this.nextSlotIcon,
    required this.l,
    required this.onTap,
    required this.hasConflicts,
    required this.conflictCount,
    required this.activeSlotLabel,
    required this.hasZeroDays,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isAdvancing = nextSlotRoutine != null;

    final String label;
    final IconData trailingIcon;
    if (isAdvancing) {
      label = l.scheduleContinueTo(nextSlotRoutine!);
      trailingIcon = Icons.arrow_forward;
    } else {
      label = fromSetup
          ? l.continueAction
          : isProductsFlow
              ? l.scheduleSaveFinish
              : l.saveAction;
      trailingIcon = Icons.check_rounded;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.navGlow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 52,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PrimaryButton(
                  label: label,
                  onTap: hasZeroDays ? null : onTap,
                  leadingIcon: isAdvancing ? nextSlotIcon : null,
                  trailingIcon: trailingIcon,
                  height: 56,
                ),
              ),
            ],
          ),
          if (hasZeroDays) ...[
            const SizedBox(height: 6),
            Text(
              l.scheduleZeroDayError(activeSlotLabel),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (hasConflicts) ...[
            const SizedBox(height: 6),
            Text(
              l.scheduleConflictWarningCount(conflictCount, activeSlotLabel),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
