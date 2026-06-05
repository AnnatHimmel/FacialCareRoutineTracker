import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/rule_scope.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/weekday_picker.dart';

const _uuid = Uuid();

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

  const ScheduleSetupScreen({
    super.key,
    this.fromSetup = false,
    this.fromProducts = false,
  });

  @override
  ConsumerState<ScheduleSetupScreen> createState() =>
      _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends ConsumerState<ScheduleSetupScreen> {
  Slot _activeSlot = Slot.morning;
  Set<Slot> _visitedSlots = {Slot.morning};

  // Redesign state
  String? _openProductId; // which product row's day-editor is expanded
  bool _issuesOpen = false; // is the issues panel expanded (starts collapsed)
  bool _showDaily = false; // is the "every day" group expanded

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _rowKeys = {};

  Future<void> _updateSchedule(
    String productId,
    Slot slot,
    Set<int> weekdays,
    WeekdaySchedule? existing,
  ) async {
    await ref.read(userDataRepositoryProvider).upsertSchedule(
          WeekdaySchedule(
            id: existing?.id ?? _uuid.v4(),
            productId: productId,
            slot: slot,
            weekdays: weekdays,
            lastModified: DateTime.now(),
          ),
        );
  }

  /// Remove a single weekday for a product (used by the conflict "remove from
  /// {day}" action). Daily products with no override start as all-7.
  Future<void> _removeDay(String productId, int dayId) async {
    final schedules = ref.read(allSchedulesProvider).valueOrNull ?? [];
    final existing = schedules
        .where((s) => s.productId == productId && s.slot == _activeSlot)
        .firstOrNull;
    final master = ref.read(masterContentProvider).valueOrNull;
    final product = master?.products.where((p) => p.id == productId).firstOrNull;
    final Set<int> current;
    if (existing != null && existing.weekdays.isNotEmpty) {
      current = Set.from(existing.weekdays);
    } else if (product?.configForSlot(_activeSlot)?.frequencyRule is DailyRule) {
      current = {0, 1, 2, 3, 4, 5, 6};
    } else {
      current = <int>{};
    }
    current.remove(dayId);
    await _updateSchedule(productId, _activeSlot, current, existing);
  }

  void _handleContinue(BuildContext context) {
    if (widget.fromSetup) {
      context.go('/setup/order?from=setup');
    } else if (_isProductsFlow) {
      context.go('/today');
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
      _issuesOpen = false;
      _showDaily = false;
      _rowKeys.clear();
    });
  }

  void _openAndScrollToProduct(String id) {
    setState(() => _openProductId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _rowKeys[id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── derived helpers ────────────────────────────────────────────────────────

  Set<int> _effectiveDays(
    MasterProduct p,
    Slot slot,
    List<WeekdaySchedule> schedules,
  ) {
    final sched = schedules
        .where((s) => s.productId == p.id && s.slot == slot)
        .firstOrNull;
    if (sched != null && sched.weekdays.isNotEmpty) return sched.weekdays;
    if (p.configForSlot(slot)?.frequencyRule is DailyRule) {
      return {0, 1, 2, 3, 4, 5, 6};
    }
    return <int>{};
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);
    final customAsync = ref.watch(customProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      bottomNavigationBar: _isProductsFlow ? null : _buildSetupNav(context, l),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final morningSelections = morningAsync.valueOrNull ?? [];
          final eveningSelections = eveningAsync.valueOrNull ?? [];
          final schedules = schedulesAsync.valueOrNull ?? [];
          final mutedIds =
              (mutedAsync.valueOrNull ?? []).map((m) => m.ruleId).toSet();
          final customProds = customAsync.valueOrNull ?? [];

          final allProducts = [
            ...master.products,
            ...customProds.map((p) => p.toMasterProduct()),
          ];

          final morningSelectedIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningSelectedIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          final categoryOrderById = {
            for (final cat in master.categories) cat.id: cat.order,
          };

          int slotOrder(MasterProduct p, Slot slot) =>
              (slot == Slot.morning
                  ? p.morningConfig?.order
                  : p.eveningConfig?.order) ??
              999;

          int categoryThenSlotOrder(
              MasterProduct a, MasterProduct b, Slot slot) {
            final catA = categoryOrderById[a.categoryId] ?? 9999;
            final catB = categoryOrderById[b.categoryId] ?? 9999;
            if (catA != catB) return catA.compareTo(catB);
            return slotOrder(a, slot).compareTo(slotOrder(b, slot));
          }

          final morningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  morningSelectedIds.contains(p.id) &&
                  p.morningConfig != null)
              .toList()
            ..sort((a, b) => categoryThenSlotOrder(a, b, Slot.morning));
          final eveningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  eveningSelectedIds.contains(p.id) &&
                  p.eveningConfig != null)
              .toList()
            ..sort((a, b) => categoryThenSlotOrder(a, b, Slot.evening));

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
                  _effectiveDays(p, _activeSlot, schedules).length < 7)
              .toList();
          final everyDay = daily
              .where((p) =>
                  _effectiveDays(p, _activeSlot, schedules).length == 7)
              .toList();
          final flexed = [...occasional, ...narrowed]
            ..sort((a, b) => categoryThenSlotOrder(a, b, _activeSlot));

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

          final checker = ref.read(incompatibilityCheckerProvider);
          final withinSlotRules = master.rules
              .where((r) => r.scope == RuleScope.withinSlot)
              .toList();

          // ── conflict + over-frequency computation for the ACTIVE slot ──
          final Map<int, List<ConflictInfo>> activeDayPairs = {};
          final Set<String> cellSet = {};
          for (int d = 0; d < 7; d++) {
            final onDay = activeProducts
                .where((p) =>
                    _effectiveDays(p, _activeSlot, schedules).contains(d))
                .toList();
            final pairs = checker
                .getConflictsForSelection(
                  activeSlot: _activeSlot,
                  slotProducts: onDay,
                  otherSlotProducts: const [],
                  rules: withinSlotRules,
                  categories: master.categories,
                  mutedRuleIds: mutedIds,
                )
                .where((c) => !c.isMuted)
                .toList();
            if (pairs.isNotEmpty) {
              activeDayPairs[d] = pairs;
              for (final c in pairs) {
                cellSet.add('${c.productA.id}-$d');
                cellSet.add('${c.productB.id}-$d');
              }
            }
          }
          final conflictDays = activeDayPairs.keys.toList()..sort();
          final pairCount =
              activeDayPairs.values.fold<int>(0, (a, b) => a + b.length);

          final overProds = flexed.where((p) {
            final rule = p.configForSlot(_activeSlot)?.frequencyRule;
            if (rule is! WeeklyMaxRule) return false;
            return _effectiveDays(p, _activeSlot, schedules).length >
                rule.maxPerWeek;
          }).toList();

          final totalIssues = pairCount + overProds.length;

          // per-slot issue totals for the tab badges
          int slotIssueCount(Slot slot, List<MasterProduct> products) {
            int pairs = 0;
            for (int d = 0; d < 7; d++) {
              final onDay = products
                  .where((p) => _effectiveDays(p, slot, schedules).contains(d))
                  .toList();
              pairs += checker
                  .getConflictsForSelection(
                    activeSlot: slot,
                    slotProducts: onDay,
                    otherSlotProducts: const [],
                    rules: withinSlotRules,
                    categories: master.categories,
                    mutedRuleIds: mutedIds,
                  )
                  .where((c) => !c.isMuted)
                  .length;
            }
            final over = products.where((p) {
              final r = p.configForSlot(slot)?.frequencyRule;
              return r is WeeklyMaxRule &&
                  _effectiveDays(p, slot, schedules).length > r.maxPerWeek;
            }).length;
            return pairs + over;
          }

          final isEnglish = l.localeName == 'en';

          return Column(
            children: [
              if (!isEmpty) ...[
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
                    : ListView(
                        key: ValueKey(_activeSlot),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          // 1 · single collapsible issues panel
                          if (totalIssues > 0) ...[
                            _IssuesPanel(
                              open: _issuesOpen,
                              onToggle: () => setState(
                                  () => _issuesOpen = !_issuesOpen),
                              totalIssues: totalIssues,
                              pairCount: pairCount,
                              conflictDays: conflictDays,
                              dayPairs: activeDayPairs,
                              overProds: overProds,
                              slot: _activeSlot,
                              schedules: schedules,
                              categories: master.categories,
                              isEnglish: isEnglish,
                              onRemoveFromDay: _removeDay,
                              onTapOver: _openAndScrollToProduct,
                              effectiveDays: (p) =>
                                  _effectiveDays(p, _activeSlot, schedules),
                              l: l,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // 2 · calm "by frequency" list
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
                                          _openProductId == p.id ? null : p.id),
                                  selectedDays:
                                      _effectiveDays(p, _activeSlot, schedules),
                                  onChanged: (days, existing) =>
                                      _updateSchedule(
                                          p.id, _activeSlot, days, existing),
                                  l: l,
                                ),
                              ),
                          ],

                          // 3 · "every day" group, collapsed
                          if (everyDay.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _DailyGroup(
                              products: everyDay,
                              open: _showDaily,
                              onToggle: () =>
                                  setState(() => _showDaily = !_showDaily),
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
                                  _effectiveDays(p, _activeSlot, schedules),
                              onChanged: (id, days, existing) =>
                                  _updateSchedule(
                                      id, _activeSlot, days, existing),
                              l: l,
                            ),
                          ],
                        ],
                      ),
              ),
              _BottomCta(
                fromSetup: widget.fromSetup,
                isProductsFlow: _isProductsFlow,
                nextSlotRoutine: nextSlotRoutine,
                nextSlotIcon: nextSlotIcon,
                l: l,
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

  Widget _buildSetupNav(BuildContext context, AppLocalizations l) =>
      GlassBottomNav(
        currentIndex: -1,
        onDestinationSelected: (i) {
          const routes = ['/today', '/calendar', '/journal', '/settings'];
          if (i < routes.length) context.go(routes[i]);
        },
        items: [
          GlassNavItem(
            icon: Icons.wb_sunny_outlined,
            selectedIcon: Icons.wb_sunny_rounded,
            label: l.navToday,
          ),
          GlassNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: l.navCalendar,
          ),
          GlassNavItem(
            icon: Icons.auto_stories_outlined,
            selectedIcon: Icons.auto_stories_rounded,
            label: l.navJournal,
          ),
          GlassNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: l.navSettings,
          ),
        ],
      );
}

// ── Issues panel (collapsible; all warnings live here) ──────────────────────

class _IssuesPanel extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  final int totalIssues;
  final int pairCount;
  final List<int> conflictDays;
  final Map<int, List<ConflictInfo>> dayPairs;
  final List<MasterProduct> overProds;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final List<Category> categories;
  final bool isEnglish;
  final Future<void> Function(String productId, int dayId) onRemoveFromDay;
  final ValueChanged<String> onTapOver;
  final Set<int> Function(MasterProduct p) effectiveDays;
  final AppLocalizations l;

  const _IssuesPanel({
    required this.open,
    required this.onToggle,
    required this.totalIssues,
    required this.pairCount,
    required this.conflictDays,
    required this.dayPairs,
    required this.overProds,
    required this.slot,
    required this.schedules,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveFromDay,
    required this.onTapOver,
    required this.effectiveDays,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = <String>[
      if (pairCount > 0) l.scheduleAlertsConflicts(pairCount),
      if (overProds.isNotEmpty) l.scheduleAlertsOverFreq(overProds.length),
    ].join('  ·  ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header / toggle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high_rounded,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalIssues == 1
                              ? l.scheduleAlertsOne
                              : l.scheduleAlertsCount(totalIssues),
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                        if (breakdown.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            breakdown,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              height: 1.375,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // expanded content
          if (open)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.15)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // conflicts
                  if (pairCount > 0) ...[
                    const SizedBox(height: 12),
                    if (overProds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l.scheduleConflictsSection,
                          textAlign: TextAlign.start,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.error.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    for (final d in conflictDays)
                      for (int i = 0; i < dayPairs[d]!.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                              top: (d == conflictDays.first && i == 0) ? 0 : 8),
                          child: _ConflictPairCard(
                            conflict: dayPairs[d]![i],
                            dayLabel: _getDayFullName(d, l),
                            dayAbbrLabel: _getDayAbbrName(d, l),
                            categories: categories,
                            isEnglish: isEnglish,
                            onRemoveA: () =>
                                onRemoveFromDay(dayPairs[d]![i].productA.id, d),
                            onRemoveB: () =>
                                onRemoveFromDay(dayPairs[d]![i].productB.id, d),
                            l: l,
                          ),
                        ),
                  ],

                  // over-frequency
                  if (overProds.isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.only(top: pairCount > 0 ? 8 : 12),
                      padding: EdgeInsets.only(top: pairCount > 0 ? 8 : 0),
                      decoration: pairCount > 0
                          ? BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: AppColors.error
                                        .withValues(alpha: 0.15)),
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (pairCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l.scheduleOverFreqSection,
                                textAlign: TextAlign.start,
                                style: AppTypography.labelSm.copyWith(
                                  color:
                                      AppColors.error.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          for (int i = 0; i < overProds.length; i++)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                              child: _OverFreqRow(
                                product: overProds[i],
                                slot: slot,
                                count: effectiveDays(overProds[i]).length,
                                cap: (overProds[i]
                                        .configForSlot(slot)!
                                        .frequencyRule as WeeklyMaxRule)
                                    .maxPerWeek,
                                onTap: () => onTapOver(overProds[i].id),
                                l: l,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Text(
                    l.scheduleSoftAlertsNote,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                      fontSize: 9.5,
                      height: 1.375,
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

class _ConflictPairCard extends StatelessWidget {
  final ConflictInfo conflict;
  final String dayLabel;
  final String dayAbbrLabel;
  final List<Category> categories;
  final bool isEnglish;
  final VoidCallback onRemoveA;
  final VoidCallback onRemoveB;
  final AppLocalizations l;

  const _ConflictPairCard({
    required this.conflict,
    required this.dayLabel,
    required this.dayAbbrLabel,
    required this.categories,
    required this.isEnglish,
    required this.onRemoveA,
    required this.onRemoveB,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final catA = categories
        .where((c) => c.id == conflict.productA.categoryId)
        .firstOrNull;
    final catB = categories
        .where((c) => c.id == conflict.productB.categoryId)
        .firstOrNull;
    final reason = conflict.localizedReason(isEnglish ? 'en' : 'he');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // day chip
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 2, left: 2),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.scheduleDayChip(dayLabel),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ),
          _ConflictFixRow(
            product: conflict.productA,
            category: catA,
            dayLabel: dayLabel,
            dayAbbrLabel: dayAbbrLabel,
            onRemove: onRemoveA,
            isEnglish: isEnglish,
            l: l,
          ),
          _connector(),
          _ConflictFixRow(
            product: conflict.productB,
            category: catB,
            dayLabel: dayLabel,
            dayAbbrLabel: dayAbbrLabel,
            onRemove: onRemoveB,
            isEnglish: isEnglish,
            l: l,
          ),
          if (reason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_rounded,
                        size: 12,
                        color: AppColors.error.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reason,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        height: 1.375,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox(height: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded,
                    size: 10, color: AppColors.error.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  l.scheduleNoMix,
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 8,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictFixRow extends StatelessWidget {
  final MasterProduct product;
  final Category? category;
  final String dayLabel;
  final String dayAbbrLabel;
  final VoidCallback onRemove;
  final bool isEnglish;
  final AppLocalizations l;

  const _ConflictFixRow({
    required this.product,
    required this.category,
    required this.dayLabel,
    required this.dayAbbrLabel,
    required this.onRemove,
    required this.isEnglish,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProductThumb(imageAsset: product.imageAsset, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _productName(product, fontSize: 11),
                if (category != null)
                  Text(
                    category!.localizedName(isEnglish ? 'en' : 'he'),
                    textAlign: TextAlign.start,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 10, 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppColors.glowSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    isEnglish
                        ? 'Remove from\n$dayAbbrLabel'
                        : l.scheduleRemoveFrom(dayLabel),
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
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

class _OverFreqRow extends StatelessWidget {
  final MasterProduct product;
  final Slot slot;
  final int count;
  final int cap;
  final VoidCallback onTap;
  final AppLocalizations l;

  const _OverFreqRow({
    required this.product,
    required this.slot,
    required this.count,
    required this.cap,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ProductThumb(imageAsset: product.imageAsset, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _productName(product, fontSize: 11),
                  Text(
                    l.scheduleRecommendedWeekly(cap),
                    textAlign: TextAlign.start,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count/$cap×',
                textDirection: TextDirection.ltr,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
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
                        _productName(product, fontSize: 13),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  cat.localizedName(isEnglish ? 'en' : 'he'),
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 9,
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
  final double size;
  final int max;

  const _StackedThumbs({required this.products, this.size = 24, this.max = 5});

  @override
  Widget build(BuildContext context) {
    final shown = products.take(max).toList();
    const step = 16.0; // overlap step (size - 8)
    final width = shown.isEmpty ? 0.0 : size + (shown.length - 1) * step;
    return SizedBox(
      width: width,
      height: size,
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
                    imageAsset: shown[i].imageAsset, size: size - 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = const Color(0x4DBA1A1A)
      ..strokeWidth = 1.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  const _BottomCta({
    required this.fromSetup,
    required this.isProductsFlow,
    required this.nextSlotRoutine,
    required this.nextSlotIcon,
    required this.l,
    required this.onTap,
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
                  onTap: onTap,
                  leadingIcon: isAdvancing ? nextSlotIcon : null,
                  trailingIcon: trailingIcon,
                  height: 56,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
