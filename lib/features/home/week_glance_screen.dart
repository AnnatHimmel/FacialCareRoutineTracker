import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/week_glance_builder.dart';
import '../../features/setup/order_customization_screen.dart';
import '../../features/setup/schedule_setup_screen.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/product_thumb.dart';

// ── Main screen ────────────────────────────────────────────────────────────────

class WeekGlanceScreen extends ConsumerStatefulWidget {
  const WeekGlanceScreen({super.key});

  @override
  ConsumerState<WeekGlanceScreen> createState() => _WeekGlanceScreenState();
}

class _WeekGlanceScreenState extends ConsumerState<WeekGlanceScreen> {
  bool _morningExpanded = true;
  bool _eveningExpanded = true;

  void _startEditFlow(Slot slot) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _EditRoutineFlow(
        slot: slot,
        onBack: () => Navigator.of(context).pop(),
        onDone: () => Navigator.of(context).pop(),
      ),
    ));
  }

  TextStyle _buildHeaderTitleStyle() => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: AppColors.onSurface,
  );

  TextStyle _buildHeaderSubtitleStyle() => GoogleFonts.quicksand(
    fontSize: 12.5,
    color: AppColors.onSurfaceVariant,
  );

  TextStyle _buildConflictHeaderStyle() => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 12.5,
    color: AppColors.error,
  );

  TextStyle _buildConflictExplanationStyle() => GoogleFonts.quicksand(
    fontSize: 11,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  TextStyle _buildCTATextStyle() => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: Colors.white,
  );

  TextStyle _buildSecondaryActionStyle() => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
    color: AppColors.onSurfaceVariant,
  );

  void _showConflictsSheet(
    Slot slot,
    List<WeekConflictPair> conflicts,
    List<String> dayAbbrevs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final l = AppLocalizations.of(sheetCtx)!;
        final slotLabel = slot == Slot.morning ? l.slotMorning : l.slotEvening;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: AppColors.glowLg,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withAlpha(153),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header row
                  Row(
                    children: [
                      const Icon(Icons.warning,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        l.weekGlanceIssueTitle(conflicts.length, slotLabel),
                        style: _buildHeaderTitleStyle(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    l.weekGlanceConflictSheetSubtitle,
                    style: _buildHeaderSubtitleStyle(),
                  ),
                  const SizedBox(height: 12),
                  // Each conflict pair
                  for (final pair in conflicts) ...[
                    // Day chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (pair.days.toList()..sort())
                          .map((d) => _DayChip(
                                label: l.scheduleDayChip(dayAbbrevs[d]),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Conflict card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(13),
                        border: Border.all(
                            color: AppColors.error.withAlpha(31), width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Conflict header
                          Row(
                            children: [
                              const Icon(Icons.block,
                                  size: 15, color: AppColors.error),
                              const SizedBox(width: 6),
                              Text(
                                l.weekGlanceConflictNotMix,
                                style: _buildConflictHeaderStyle(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Product list card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.glowSm,
                            ),
                            child: Column(
                              children: [
                                _ConflictProductRow(
                                    name: pair.productA.name,
                                    brand: pair.productA.brand ?? ''),
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant.withAlpha(60),
                                ),
                                _ConflictProductRow(
                                    name: pair.productB.name,
                                    brand: pair.productB.brand ?? ''),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Explanation row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info,
                                  size: 13, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (pair.reason != null &&
                                          pair.reason!.isNotEmpty)
                                      ? pair.reason!
                                      : l.weekGlanceConflictExplanation,
                                  style: _buildConflictExplanationStyle(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGlowGradient,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: AppColors.glowLg,
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit,
                            size: 18, color: Colors.white),
                        label: Text(
                          l.weekGlanceEditRoutine(slotLabel),
                          style: _buildCTATextStyle(),
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          _startEditFlow(slot);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Secondary action
                  GestureDetector(
                    onTap: () => Navigator.of(sheetCtx).pop(),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(sheetCtx)!.issueActionKeep,
                        style: _buildSecondaryActionStyle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final masterAsync = ref.watch(masterContentProvider);
    final morningSelections =
        ref.watch(selectionsProvider(Slot.morning)).valueOrNull ?? [];
    final eveningSelections =
        ref.watch(selectionsProvider(Slot.evening)).valueOrNull ?? [];
    final schedules = ref.watch(allSchedulesProvider).valueOrNull ?? [];
    final muted = ref.watch(mutedConflictsProvider).valueOrNull ?? [];
    final customProducts = ref.watch(customProductsProvider).valueOrNull ?? [];
    final morningOrder =
        ref.watch(orderOverrideProvider(Slot.morning)).valueOrNull;
    final eveningOrder =
        ref.watch(orderOverrideProvider(Slot.evening)).valueOrNull;

    final dayAbbrevs = [
      l.calendarDayAbbrevSun,
      l.calendarDayAbbrevMon,
      l.calendarDayAbbrevTue,
      l.calendarDayAbbrevWed,
      l.calendarDayAbbrevThu,
      l.calendarDayAbbrevFri,
      l.calendarDayAbbrevSat,
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(title: l.weekGlanceTitle, showBack: true),
      body: masterAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, stack) => const SizedBox.shrink(),
        data: (master) {
          final allProducts = [
            ...master.products,
            ...customProducts.map((c) => c.toMasterProduct()),
          ];

          final glance = const WeekGlanceBuilder().build(
            allProducts: allProducts,
            categories: master.categories,
            subcategories: master.subcategories,
            rules: master.rules,
            morningSelections: morningSelections,
            eveningSelections: eveningSelections,
            schedules: schedules,
            mutedRuleIds: muted.map((m) => m.ruleId).toSet(),
            morningOrderOverride: morningOrder,
            eveningOrderOverride: eveningOrder,
          );

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                children: [
                  _WRoutineSection(
                    slot: Slot.morning,
                    glance: glance.morning,
                    dayAbbrevs: dayAbbrevs,
                    expanded: _morningExpanded,
                    onToggleExpanded: () =>
                        setState(() => _morningExpanded = !_morningExpanded),
                    onEdit: () => _startEditFlow(Slot.morning),
                    onShowConflicts: glance.morning.hasIssues
                        ? () => _showConflictsSheet(
                              Slot.morning,
                              glance.morning.conflicts,
                              dayAbbrevs,
                            )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _WRoutineSection(
                    slot: Slot.evening,
                    glance: glance.evening,
                    dayAbbrevs: dayAbbrevs,
                    expanded: _eveningExpanded,
                    onToggleExpanded: () =>
                        setState(() => _eveningExpanded = !_eveningExpanded),
                    onEdit: () => _startEditFlow(Slot.evening),
                    onShowConflicts: glance.evening.hasIssues
                        ? () => _showConflictsSheet(
                              Slot.evening,
                              glance.evening.conflicts,
                              dayAbbrevs,
                            )
                        : null,
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

// ── Day chip ──────────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  final String label;
  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
      color: AppColors.error,
    );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(23),
        border: Border.all(color: AppColors.error.withAlpha(56)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            label,
            style: labelStyle,
          ),
        ],
      ),
    );
  }
}

// ── Conflict product row ───────────────────────────────────────────────────────

class _ConflictProductRow extends StatelessWidget {
  final String name;
  final String brand;
  const _ConflictProductRow({required this.name, required this.brand});

  @override
  Widget build(BuildContext context) {
    final productNameStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: AppColors.onSurface,
    );
    final brandStyle = GoogleFonts.quicksand(
      fontSize: 11,
      color: AppColors.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const ProductThumb(imageAsset: null, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: productNameStyle,
                ),
                if (brand.isNotEmpty)
                  Text(
                    brand,
                    style: brandStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────

class _WRoutineSection extends StatelessWidget {
  final Slot slot;
  final SlotWeekGlance glance;
  final List<String> dayAbbrevs;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;
  final VoidCallback? onShowConflicts;

  const _WRoutineSection({
    required this.slot,
    required this.glance,
    required this.dayAbbrevs,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onShowConflicts,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.glowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _WSectionHeader(
            slot: slot,
            hasIssues: glance.hasIssues,
            issueCount: glance.issueCount,
            expanded: expanded,
            onToggleExpanded: onToggleExpanded,
            onEdit: onEdit,
            l: l,
          ),
          if (expanded)
            _WExpandedBody(
              slot: slot,
              products: glance.products,
              dayAbbrevs: dayAbbrevs,
              hasIssues: glance.hasIssues,
              issueCount: glance.issueCount,
              onShowConflicts: onShowConflicts,
              l: l,
            ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _WSectionHeader extends StatelessWidget {
  final Slot slot;
  final bool hasIssues;
  final int issueCount;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;
  final AppLocalizations l;

  const _WSectionHeader({
    required this.slot,
    required this.hasIssues,
    required this.issueCount,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.l,
  });

  Color _getSlotColor() => slot == Slot.morning ? AppColors.primary : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    final isMorning = slot == Slot.morning;
    final slotColor = _getSlotColor();
    final slotLabelStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: slotColor,
    );
    final badgeTextStyle = GoogleFonts.quicksand(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    final editButtonStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
      color: AppColors.primary,
    );

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Icon(
                      isMorning
                          ? Icons.wb_sunny_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                      color: slotColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMorning ? l.slotMorning : l.slotEvening,
                      style: slotLabelStyle,
                    ),
                    if (hasIssues) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$issueCount',
                          style: badgeTextStyle,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: AppColors.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.outlineVariant.withAlpha(77),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  l.weekGlanceEditButton,
                  style: editButtonStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expanded body ──────────────────────────────────────────────────────────────

class _WExpandedBody extends StatelessWidget {
  final Slot slot;
  final List<ProductWeekSpread> products;
  final List<String> dayAbbrevs;
  final bool hasIssues;
  final int issueCount;
  final VoidCallback? onShowConflicts;
  final AppLocalizations l;

  const _WExpandedBody({
    required this.slot,
    required this.products,
    required this.dayAbbrevs,
    required this.hasIssues,
    required this.issueCount,
    required this.onShowConflicts,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          if (products.isNotEmpty || hasIssues)
            _WStatusBanner(
              slot: slot,
              hasIssues: hasIssues,
              issueCount: issueCount,
              onCheckConflicts: onShowConflicts,
              l: l,
            ),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 8),
            _WWeekMatrix(
              products: products,
              dayAbbrevs: dayAbbrevs,
              slot: slot,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status banner ──────────────────────────────────────────────────────────────

class _WStatusBanner extends StatelessWidget {
  final Slot slot;
  final bool hasIssues;
  final int issueCount;
  final VoidCallback? onCheckConflicts;
  final AppLocalizations l;

  // Green status banner colors
  static const _greenBgColor = Color(0x1C69A870);
  static const _greenCheckColor = Color(0xFF3A7A44);
  static const _greenTitleColor = Color(0xFF2D5E35);
  static const _greenSubColor = Color(0xFF4A8C54);

  // Error status banner colors
  static const _errorSubColor = Color(0xFFB84040);

  // Reusable text styles
  static TextStyle _buildTitleStyle(Color color) => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 12.5,
    color: color,
  );

  static TextStyle _buildSubtitleStyle(Color color) => GoogleFonts.quicksand(
    fontSize: 11,
    color: color,
  );

  static TextStyle _buildButtonTextStyle() => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    fontSize: 11,
  );

  const _WStatusBanner({
    required this.slot,
    required this.hasIssues,
    required this.issueCount,
    required this.onCheckConflicts,
    required this.l,
  });

  Widget _buildGreenStatusBanner(
    bool isMorning,
    TextStyle titleStyle,
    TextStyle subtitleStyle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _greenBgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              size: 15, color: _greenCheckColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.weekGlanceStatusOkTitle,
                style: titleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                isMorning
                    ? l.weekGlanceStatusOkSubMorning
                    : l.weekGlanceStatusOkSubEvening,
                style: subtitleStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatusBanner(
    bool isMorning,
    TextStyle errorTitleStyle,
    TextStyle errorSubStyle,
    TextStyle buttonTextStyle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, size: 15, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.weekGlanceIssueTitle(
                    issueCount,
                    isMorning ? l.slotMorning : l.slotEvening,
                  ),
                  style: errorTitleStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  l.weekGlanceIssueSub,
                  style: errorSubStyle,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onCheckConflicts,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                  color: AppColors.error.withAlpha(56)),
              backgroundColor: AppColors.error.withAlpha(23),
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 28),
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l.weekGlanceCheckIssues,
              style: buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = slot == Slot.morning;

    if (!hasIssues) {
      return _buildGreenStatusBanner(
        isMorning,
        _buildTitleStyle(_greenTitleColor),
        _buildSubtitleStyle(_greenSubColor),
      );
    }

    return _buildErrorStatusBanner(
      isMorning,
      _buildTitleStyle(AppColors.error),
      _buildSubtitleStyle(_errorSubColor),
      _buildButtonTextStyle(),
    );
  }
}

// ── Week matrix ────────────────────────────────────────────────────────────────

class _WWeekMatrix extends StatelessWidget {
  final List<ProductWeekSpread> products;
  final List<String> dayAbbrevs;
  final Slot slot;

  const _WWeekMatrix({
    required this.products,
    required this.dayAbbrevs,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final dayHeaderStyle = GoogleFonts.quicksand(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant.withAlpha(128),
    );

    return Column(
      children: [
        // Day header row
        Row(
          children: [
            const SizedBox(width: 112),
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    dayAbbrevs[i],
                    style: dayHeaderStyle,
                  ),
                ),
              ),
          ],
        ),
        // Product rows
        ...List.generate(products.length, (pi) {
          final isLast = pi == products.length - 1;
          return Container(
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            AppColors.outlineVariant.withAlpha(38),
                        width: 0.5,
                      ),
                    ),
                  ),
            child: _WMatrixRow(
                spread: products[pi], slot: slot),
          );
        }),
      ],
    );
  }
}

// ── Matrix row ─────────────────────────────────────────────────────────────────

class _WMatrixRow extends StatelessWidget {
  final ProductWeekSpread spread;
  final Slot slot;

  const _WMatrixRow({required this.spread, required this.slot});

  @override
  Widget build(BuildContext context) {
    final productNameStyle = GoogleFonts.quicksand(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      height: 1.3,
    );
    final issueIndicatorStyle = GoogleFonts.quicksand(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ProductThumb(imageAsset: spread.product.imageAsset, size: 28),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    spread.product.name,
                    style: productNameStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: !spread.activeDays[i]
                  ? const SizedBox.shrink()
                  : spread.conflictDays.contains(i)
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '!',
                            style: issueIndicatorStyle,
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slot == Slot.morning
                                ? AppColors.primary
                                : AppColors.secondaryFixedDim,
                          ),
                        ),
            ),
          ),
      ],
    );
  }
}

// ── Edit routine flow ──────────────────────────────────────────────────────────

class _EditRoutineFlow extends StatefulWidget {
  final Slot slot;
  final VoidCallback onBack;
  final VoidCallback onDone;

  const _EditRoutineFlow({
    required this.slot,
    required this.onBack,
    required this.onDone,
  });

  @override
  State<_EditRoutineFlow> createState() => _EditRoutineFlowState();
}

class _EditRoutineFlowState extends State<_EditRoutineFlow> {
  bool _showOrder = false;

  @override
  Widget build(BuildContext context) => _showOrder
      ? OrderCustomizationScreen(
          onboardingSlot: widget.slot,
          onContinue: widget.onDone,
          onBack: () => setState(() => _showOrder = false),
        )
      : ScheduleSetupScreen(
          onboardingSlot: widget.slot,
          onContinue: () => setState(() => _showOrder = true),
          onBack: widget.onBack,
        );
}
