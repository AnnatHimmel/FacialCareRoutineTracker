import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/product_sorter.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/product_thumb.dart';

class WeekGlanceScreen extends ConsumerWidget {
  const WeekGlanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningSelAsync = ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        title: l.homeWeekGlanceTitle,
        showBack: true,
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox.shrink(),
        data: (master) {
          final morningSelections = morningSelAsync.valueOrNull ?? [];
          final eveningSelections = eveningSelAsync.valueOrNull ?? [];
          final schedules = schedulesAsync.valueOrNull ?? [];

          final morningProductIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningProductIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          final morningProducts = master.products
              .where(
                  (p) => morningProductIds.contains(p.id) && !p.isDeprecated)
              .toList()
            ..sort(ProductSorter.adminComparator(
              categories: master.categories,
              subcategories: master.subcategories,
              slot: Slot.morning,
            ));

          final eveningProducts = master.products
              .where(
                  (p) => eveningProductIds.contains(p.id) && !p.isDeprecated)
              .toList()
            ..sort(ProductSorter.adminComparator(
              categories: master.categories,
              subcategories: master.subcategories,
              slot: Slot.evening,
            ));

          // Determine today's weekday index (Sunday=0 per app convention)
          final now = DateTime.now();
          // Dart: Monday=1 … Saturday=6, Sunday=7 → convert to Sunday=0
          final todayIdx = now.weekday == 7 ? 0 : now.weekday;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeekGrid(
                  morningProducts: morningProducts,
                  eveningProducts: eveningProducts,
                  schedules: schedules,
                  todayIdx: todayIdx,
                  l: l,
                ),
                const SizedBox(height: 12),
                const _AdvisoryCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Advisory card ──────────────────────────────────────────────────────────────

class _AdvisoryCard extends StatelessWidget {
  const _AdvisoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withAlpha(153), // /60 opacity
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'אין התנגשויות מתוזמנות השבוע.',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week grid ──────────────────────────────────────────────────────────────────

class _WeekGrid extends StatelessWidget {
  final List<MasterProduct> morningProducts;
  final List<MasterProduct> eveningProducts;
  final List<WeekdaySchedule> schedules;
  final int todayIdx;
  final AppLocalizations l;

  // Hebrew day letters, Sunday-first
  static const _days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  const _WeekGrid({
    required this.morningProducts,
    required this.eveningProducts,
    required this.schedules,
    required this.todayIdx,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.glow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDayHeader(),
            if (morningProducts.isNotEmpty) ...[
              _buildSlotHeader(Slot.morning),
              for (int i = 0; i < morningProducts.length; i++)
                _buildProductRow(
                  morningProducts[i],
                  Slot.morning,
                  isLast: i == morningProducts.length - 1,
                ),
            ],
            if (eveningProducts.isNotEmpty) ...[
              _buildSlotHeader(Slot.evening),
              for (int i = 0; i < eveningProducts.length; i++)
                _buildProductRow(
                  eveningProducts[i],
                  Slot.evening,
                  isLast: i == eveningProducts.length - 1,
                ),
            ],
            // Closing strip — rounds the bottom of today's column tint
            _buildClosingStrip(),
          ],
        ),
      ),
    );
  }

  // Day header row: name column + א–ש day letters
  Widget _buildDayHeader() {
    final todayBg = AppColors.primaryFixed.withAlpha(64);
    return Row(
      children: [
        const SizedBox(width: 118), // name column placeholder
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: i == todayIdx ? todayBg : null,
                borderRadius: i == todayIdx
                    ? const BorderRadius.vertical(top: Radius.circular(10))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: Text(
                _days[i],
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: i == todayIdx
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant.withAlpha(140), // ~55%
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Slot header: icon + label in 118px name column, today tint in day columns
  Widget _buildSlotHeader(Slot slot) {
    final isMorning = slot == Slot.morning;
    final iconColor =
        isMorning ? AppColors.primary : AppColors.secondaryFixedDim;
    final labelColor = isMorning ? AppColors.primary : AppColors.secondary;
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded;
    final label = isMorning ? l.slotMorning : l.slotEvening;
    final todayBg = AppColors.primaryFixed.withAlpha(64);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 118,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Container(
              color: i == todayIdx ? todayBg : null,
              height: 40, // matches pt-4 pb-1.5 ≈ 16+6 + some line height
            ),
          ),
      ],
    );
  }

  // Product row: thumbnail + name (118px) + 7 day cells
  Widget _buildProductRow(MasterProduct product, Slot slot,
      {required bool isLast}) {
    final todayBg = AppColors.primaryFixed.withAlpha(64);
    final dotColor = slot == Slot.morning
        ? AppColors.primary
        : AppColors.secondaryFixedDim;

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withAlpha(51), // /20 opacity
                  width: 0.5,
                ),
              ),
            ),
      child: Row(
        children: [
          // Product thumbnail + name in fixed 118px column
          SizedBox(
            width: 118,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  ProductThumb(imageAsset: product.imageAsset, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      style: GoogleFonts.quicksand(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
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
          // 7 day cells
          for (int dayIdx = 0; dayIdx < 7; dayIdx++)
            Expanded(
              child: Container(
                color: dayIdx == todayIdx ? todayBg : null,
                height: 48,
                alignment: Alignment.center,
                child: _isScheduledOn(product, slot, dayIdx)
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }

  // Closing strip — rounds the bottom of today's column tint
  Widget _buildClosingStrip() {
    final todayBg = AppColors.primaryFixed.withAlpha(64);
    return Row(
      children: [
        const SizedBox(width: 118),
        for (int i = 0; i < 7; i++)
          Expanded(
            child: i == todayIdx
                ? Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: todayBg,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                  )
                : const SizedBox(height: 8),
          ),
      ],
    );
  }

  /// Returns true if [product] is scheduled on [dayIdx] for [slot].
  ///
  /// Rules:
  /// - If a WeekdaySchedule exists for (product, slot) → use its weekdays set.
  /// - If no schedule exists AND the product's SlotConfig has DailyRule → every day.
  /// - Otherwise → not scheduled.
  bool _isScheduledOn(MasterProduct product, Slot slot, int dayIdx) {
    final schedule = schedules.where(
      (s) => s.productId == product.id && s.slot == slot,
    );

    if (schedule.isNotEmpty) {
      return schedule.first.weekdays.contains(dayIdx);
    }

    // No explicit schedule — fall back to DailyRule
    final config = product.configForSlot(slot);
    if (config == null) return false;
    return config.frequencyRule is DailyRule;
  }
}
