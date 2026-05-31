import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/fixed_slot_chip.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import 'add_custom_product_sheet.dart';

const _uuid = Uuid();

// ── Category display metadata (design-time constants) ─────────────────────────

const _catIcon = <String, IconData>{
  'cat-cleanser-step1': Icons.wash,
  'cat-cleanser-step2': Icons.soap,
  'cat-retinoid': Icons.biotech,
  'cat-toner': Icons.water_drop,
  'cat-serum': Icons.science,
  'cat-moisturizer': Icons.spa,
  'cat-oil': Icons.opacity,
  'cat-spf': Icons.wb_sunny,
};

const _catEn = <String, String>{
  'cat-cleanser-step1': 'Cleanse 1',
  'cat-cleanser-step2': 'Cleanse 2',
  'cat-retinoid': 'Retinoid',
  'cat-toner': 'Toner / Essence',
  'cat-serum': 'Serum / Active',
  'cat-moisturizer': 'Moisturize',
  'cat-oil': 'Oil',
  'cat-spf': 'Protect',
};

const _catHint = <String, String>{
  'cat-cleanser-step1': 'הסרת איפור ומסנני הגנה — לרוב בערב.',
  'cat-cleanser-step2': 'ניקוי פנים יומיומי ועדין.',
  'cat-retinoid': 'חידוש העור — ערב בלבד, בהדרגה.',
  'cat-toner': 'איזון העור והכנה לספיגת השלבים הבאים.',
  'cat-serum': 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצי.',
  'cat-moisturizer': 'נעילת הלחות והרגעת העור.',
  'cat-oil': 'שכבת הזנה אחרונה, לרוב בערב.',
  'cat-spf': 'הגנה מהשמש — שלב הבוקר האחרון, חובה.',
};

const _catUsage = <String, String>{
  'cat-cleanser-step1': 'עסי על עור יבש להמסת איפור ומסנני הגנה, ושטפי במים פושרים.',
  'cat-cleanser-step2': 'הקציפי עם מעט מים, עסי בעדינות בתנועות מעגליות ושטפי.',
  'cat-retinoid': 'כמות בגודל אפונה על עור יבש, הימנעי מאזור העיניים. ערב בלבד, בהדרגה.',
  'cat-toner': 'טפחי כמה טיפות בכפות הידיים על עור נקי, לפני הסרומים.',
  'cat-serum': 'כמה טיפות על עור נקי. המתיני לספיגה לפני השלב הבא.',
  'cat-moisturizer': 'מרחי שכבה אחידה לנעילת הלחות והרגעת העור.',
  'cat-oil': 'חממי כמה טיפות בין כפות הידיים ולחצי על העור כשלב אחרון.',
  'cat-spf': 'כמות נדיבה (אורך אצבע) כשלב אחרון בבוקר — גם ביום מעונן.',
};

// ── Screen ────────────────────────────────────────────────────────────────────

enum _SelectionView { guided, summary }

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool isTabDestination;

  const ProductSelectionScreen({
    super.key,
    this.fromSetup = false,
    this.isTabDestination = false,
  });

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  _SelectionView _view = _SelectionView.guided;
  int _catStep = 0;

  // Summary state
  String _slotFilter = 'all'; // 'all' | 'AM' | 'PM'
  String? _openCategoryId;

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goToSummary() => setState(() {
        _view = _SelectionView.summary;
        _openCategoryId = null;
      });

  void _backToGuided() => setState(() => _view = _SelectionView.guided);

  void _goToSchedule(BuildContext context) {
    if (widget.fromSetup) {
      context.push('/setup/schedule?from=setup');
    } else {
      context.push('/products/schedule');
    }
  }

  // ── Selection state helpers ────────────────────────────────────────────────

  /// Maps productId → Set of slots the product is selected for.
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

  /// Toggle a product on/off. When adding in the summary's filtered view,
  /// [filterSlot] restricts the default to only that slot.
  Future<void> _toggleProduct(
    MasterProduct product,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morningSelections,
    List<ProductSelection> eveningSelections, {
    Slot? filterSlot,
  }) async {
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
    final repo = ref.read(userDataRepositoryProvider);
    final match = existing
        .where((s) => s.productId == product.id && s.slot == slot)
        .firstOrNull;
    if (match != null) {
      await repo.upsertSelection(
        match.copyWith(isSelected: isSelected, lastModified: DateTime.now()),
      );
    } else if (isSelected) {
      await repo.upsertSelection(
        ProductSelection(
          id: _uuid.v4(),
          productId: product.id,
          slot: slot,
          isSelected: true,
          lastModified: DateTime.now(),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        showBack: _view == _SelectionView.summary,
        onBack: _view == _SelectionView.summary ? _backToGuided : null,
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final morning = morningAsync.valueOrNull ?? [];
          final evening = eveningAsync.valueOrNull ?? [];
          final selMap = _buildSelMap(morning, evening);
          final categories = [...master.categories]
            ..sort((a, b) => a.order.compareTo(b.order));

          return _view == _SelectionView.guided
              ? _buildGuided(context, master, categories, selMap, morning, evening)
              : _buildSummary(context, master, categories, selMap, morning, evening);
        },
      ),
    );
  }

  // ── Guided step ────────────────────────────────────────────────────────────

  Widget _buildGuided(
    BuildContext context,
    MasterContent master,
    List<Category> categories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Text('לא נמצאו קטגוריות',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
      );
    }

    final step = _catStep.clamp(0, categories.length - 1);
    final cat = categories[step];
    final total = categories.length;
    final isLast = step == total - 1;

    final catProducts = master.products
        .where((p) => !p.isDeprecated && p.categoryId == cat.id)
        .toList()
      ..sort((a, b) {
        final ao = a.morningConfig?.order ?? a.eveningConfig?.order ?? 9999;
        final bo = b.morningConfig?.order ?? b.eveningConfig?.order ?? 9999;
        return ao.compareTo(bo);
      });

    final catSel = catProducts.where((p) => selMap.containsKey(p.id)).length;
    final totalSel = selMap.length;
    final ctaLabel = isLast ? 'לסיכום' : catSel > 0 ? 'המשך' : 'דלג על השלב';

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step counter row + skip button
                    Row(
                      children: [
                        TextButton(
                          key: const Key('skip_to_summary'),
                          onPressed: _goToSummary,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          child: const Text('דלג לסיכום'),
                        ),
                        const Spacer(),
                        Text(
                          'שלב ${step + 1} מתוך $total',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress bar
                    _ProgressBar(step: step, total: total),
                    const SizedBox(height: 16),

                    // Category header
                    Row(
                      children: [
                        _CategoryGlyph(
                            categoryId: cat.id, size: 48, active: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_catEn[cat.id] ?? '').toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  letterSpacing: 0.12,
                                ),
                              ),
                              Text(
                                cat.name,
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Category hint
                    if (_catHint.containsKey(cat.id)) ...[
                      const SizedBox(height: 8),
                      Text(
                        _catHint[cat.id]!,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Product list
            if (catProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'אין מוצרים בקטגוריה זו',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(
                          bottom: i < catProducts.length - 1 ? 10 : 0),
                      child: _SelectRow(
                        key: Key('select_row_${catProducts[i].id}'),
                        product: catProducts[i],
                        selectedSlots: selMap[catProducts[i].id] ?? {},
                        categoryUsage: _catUsage[cat.id] ?? '',
                        onToggle: () => _toggleProduct(
                            catProducts[i], selMap, morning, evening),
                        onTimingChange: (slot, enabled) => _setTiming(
                            catProducts[i], slot, enabled, morning, evening),
                      ),
                    ),
                    childCount: catProducts.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),

        // Sticky footer
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(242),
              boxShadow: AppColors.navGlow,
              border: const Border(
                  top: BorderSide(color: AppColors.primaryFixed, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddCustomProductSheet(),
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withAlpha(153),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (step > 0) ...[
                      GestureDetector(
                        onTap: () => setState(() => _catStep--),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.onSurface, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: PrimaryButton(
                        label: ctaLabel,
                        leadingIcon: Icons.arrow_forward_rounded,
                        onTap: () {
                          if (isLast) {
                            _goToSummary();
                          } else {
                            setState(() => _catStep++);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  catSel == 0
                      ? 'אין בחירה בקטגוריה זו — אפשר להמשיך'
                      : '$catSel נבחרו · $totalSel בסך הכל',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary view ───────────────────────────────────────────────────────────

  Widget _buildSummary(
    BuildContext context,
    MasterContent master,
    List<Category> categories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
  ) {
    final amCount =
        selMap.values.where((s) => s.contains(Slot.morning)).length;
    final pmCount =
        selMap.values.where((s) => s.contains(Slot.evening)).length;
    final totalCount = selMap.length;

    final filterSlot = _slotFilter == 'AM'
        ? Slot.morning
        : _slotFilter == 'PM'
            ? Slot.evening
            : null;

    final visibleCats = categories.where((cat) {
      return master.products.any((p) {
        if (p.isDeprecated || p.categoryId != cat.id) return false;
        if (_slotFilter == 'AM') return p.morningConfig != null;
        if (_slotFilter == 'PM') return p.eveningConfig != null;
        return true;
      });
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'סיכום · הארון שלך',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'בחרי מוצר פעם אחת. סנני בוקר/ערב כדי לראות כל שגרה בנפרד.',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SlotFilter(
                      value: _slotFilter,
                      onChanged: (v) =>
                          setState(() => _slotFilter = v),
                      counts: {
                        'all': totalCount,
                        'AM': amCount,
                        'PM': pmCount
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Category sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final cat = visibleCats[idx];
                    final catProducts = master.products.where((p) {
                      if (p.isDeprecated || p.categoryId != cat.id) return false;
                      if (_slotFilter == 'AM') return p.morningConfig != null;
                      if (_slotFilter == 'PM') return p.eveningConfig != null;
                      return true;
                    }).toList();
                    final catSel = catProducts.where((p) {
                      if (filterSlot != null) {
                        return selMap[p.id]?.contains(filterSlot) ?? false;
                      }
                      return selMap.containsKey(p.id);
                    }).length;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx < visibleCats.length - 1 ? 10 : 0),
                      child: _CategorySection(
                        category: cat,
                        products: catProducts,
                        selMap: selMap,
                        slotFilter: _slotFilter,
                        isOpen: _openCategoryId == cat.id,
                        catSelCount: catSel,
                        categoryUsage: _catUsage[cat.id] ?? '',
                        onToggleOpen: () => setState(() {
                          _openCategoryId =
                              _openCategoryId == cat.id ? null : cat.id;
                        }),
                        onToggleProduct: (p) => _toggleProduct(
                          p, selMap, morning, evening,
                          filterSlot: filterSlot,
                        ),
                        onTimingChange: (p, slot, enabled) =>
                            _setTiming(p, slot, enabled, morning, evening),
                      ),
                    );
                  },
                  childCount: visibleCats.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Sticky footer
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(242),
              boxShadow: AppColors.navGlow,
              border: const Border(
                  top: BorderSide(color: AppColors.primaryFixed, width: 0.5)),
            ),
            child: Row(
              children: [
                // Morning / evening totals
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded,
                        size: 15, color: AppColors.primaryContainer),
                    const SizedBox(width: 4),
                    Text('$amCount',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                    const SizedBox(width: 12),
                    const Icon(Icons.dark_mode_rounded,
                        size: 15, color: AppColors.tertiary),
                    const SizedBox(width: 4),
                    Text('$pmCount',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddCustomProductSheet(),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withAlpha(153),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    label: 'המשך לתזמון',
                    leadingIcon: Icons.event_rounded,
                    onTap: () => _goToSchedule(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step; // 0-indexed current step
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

// ── Category glyph (rounded-square icon) ──────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon,
          size: iconSize, color: active ? Colors.white : AppColors.primary),
    );
  }
}

// ── SelectRow — the atom of selection ─────────────────────────────────────────
//
// Resting: thumbnail + name. Fixed products show a locked slot chip.
// ⓘ button reveals comment + usage hint + frequency (detail on demand).
// Tapping the row body toggles selection. Flexible + selected → TimingControl.

class _SelectRow extends StatefulWidget {
  final MasterProduct product;
  final Set<Slot> selectedSlots;
  final String categoryUsage;
  final VoidCallback onToggle;
  final void Function(Slot slot, bool enabled) onTimingChange;

  const _SelectRow({
    super.key,
    required this.product,
    required this.selectedSlots,
    required this.categoryUsage,
    required this.onToggle,
    required this.onTimingChange,
  });

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  bool _infoOpen = false;

  bool get _isFlexible =>
      widget.product.morningConfig != null &&
      widget.product.eveningConfig != null;

  bool get _isOn => widget.selectedSlots.isNotEmpty;
  bool get _showTiming => _isFlexible && _isOn;
  bool get _isExpanded => _showTiming || _infoOpen;

  String _frequencyLabel() {
    final config =
        widget.product.morningConfig ?? widget.product.eveningConfig;
    if (config == null) return 'יומי';
    final f = config.frequencyRule;
    return f is WeeklyMaxRule ? 'עד ${f.maxPerWeek}× בשבוע' : 'יומי';
  }

  @override
  Widget build(BuildContext context) {
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
          // ── Main row ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tap area: thumb + name (+ chip for fixed)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        // Thumbnail with check badge
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

                        // Name + optional fixed-slot chip
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              // Chip only for fixed (non-flexible) products
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
                  margin: const EdgeInsets.only(right: 8),
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

          // ── Info reveal ───────────────────────────────────────────────────
          if (_infoOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),
                  if (p.comment != null && p.comment!.isNotEmpty)
                    Text(
                      p.comment!,
                      textAlign: TextAlign.right,
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
                            textAlign: TextAlign.right,
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
                      Text(
                        'תדירות מומלצת: ',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _frequencyLabel(),
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Timing control (flexible + selected) ──────────────────────────
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

  const _TimingControl({
    required this.amSelected,
    required this.pmSelected,
    required this.onToggleAm,
    required this.onTogglePm,
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
                'מתי?',
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
                    label: 'בוקר',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: amSelected,
                    activeColor: AppColors.primaryContainer,
                    onTap: onToggleAm,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TimingPill(
                    label: 'ערב',
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

// ── Slot filter ────────────────────────────────────────────────────────────────

class _SlotFilter extends StatelessWidget {
  final String value; // 'all' | 'AM' | 'PM'
  final ValueChanged<String> onChanged;
  final Map<String, int>? counts;

  const _SlotFilter({
    required this.value,
    required this.onChanged,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    const opts = [
      (key: 'all', label: 'הכל', icon: Icons.apps_rounded, active: AppColors.primary),
      (key: 'AM', label: 'בוקר', icon: Icons.wb_sunny_rounded, active: AppColors.primaryContainer),
      (key: 'PM', label: 'ערב', icon: Icons.dark_mode_rounded, active: AppColors.tertiary),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: opts.map((opt) {
          final isActive = value == opt.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? opt.active : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: isActive ? AppColors.glowSm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(opt.icon,
                        size: 16,
                        color:
                            isActive ? Colors.white : AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      opt.label,
                      style: AppTypography.labelMd.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (counts?[opt.key] != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withAlpha(64)
                              : AppColors.primaryFixed.withAlpha(153),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '${counts![opt.key]}',
                          style: AppTypography.labelSm.copyWith(
                            color: isActive ? Colors.white : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Category section (used in summary view) ───────────────────────────────────

class _CategorySection extends StatelessWidget {
  final Category category;
  final List<MasterProduct> products;
  final Map<String, Set<Slot>> selMap;
  final String slotFilter;
  final bool isOpen;
  final int catSelCount;
  final String categoryUsage;
  final VoidCallback onToggleOpen;
  final Future<void> Function(MasterProduct) onToggleProduct;
  final Future<void> Function(MasterProduct, Slot, bool) onTimingChange;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.selMap,
    required this.slotFilter,
    required this.isOpen,
    required this.catSelCount,
    required this.categoryUsage,
    required this.onToggleOpen,
    required this.onToggleProduct,
    required this.onTimingChange,
  });

  Set<Slot> _rowSlots(MasterProduct p) => selMap[p.id] ?? {};

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isOpen
              ? AppColors.primaryFixed.withAlpha(153)
              : Colors.transparent,
        ),
        boxShadow: isOpen ? AppColors.glowSm : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  _CategoryGlyph(
                      categoryId: category.id, size: 40, active: isOpen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          catSelCount == 0
                              ? '${products.length} אפשרויות'
                              : '$catSelCount נבחרו',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (catSelCount > 0) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Center(
                        child: Text(
                          '$catSelCount',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.outline, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Expanded product list
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  for (int i = 0; i < products.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _SelectRow(
                      product: products[i],
                      selectedSlots: _rowSlots(products[i]),
                      categoryUsage: categoryUsage,
                      onToggle: () => onToggleProduct(products[i]),
                      onTimingChange: (slot, enabled) =>
                          onTimingChange(products[i], slot, enabled),
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

