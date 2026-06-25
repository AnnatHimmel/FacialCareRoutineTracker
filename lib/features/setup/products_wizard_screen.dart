import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/services/routine_build_summary.dart';
import '../../shared/providers/root_providers.dart';
import 'order_customization_screen.dart';
import 'product_selection_screen.dart';
import 'routine_ready_summary_screen.dart';
import 'schedule_setup_screen.dart';

enum _Stage {
  products,
  routineSummary,
  amSchedule,
  amOrder,
  pmSchedule,
  pmOrder,
}

/// Wizard that orchestrates the "Add / remove products" flow for returning
/// users. Mirrors the setup stages in [OnboardingScreen._buildStep3()] but
/// ends at /collection instead of the week-glance screen.
class ProductsWizardScreen extends ConsumerStatefulWidget {
  const ProductsWizardScreen({super.key});

  @override
  ConsumerState<ProductsWizardScreen> createState() =>
      _ProductsWizardScreenState();
}

class _ProductsWizardScreenState extends ConsumerState<ProductsWizardScreen> {
  _Stage _stage = _Stage.products;
  RoutineBuildSummary? _summary;

  bool _hasMorning() {
    final sels = ref.read(selectionsProvider(Slot.morning)).valueOrNull ?? [];
    return sels.any((s) => s.isSelected);
  }

  bool _hasEvening() {
    final sels = ref.read(selectionsProvider(Slot.evening)).valueOrNull ?? [];
    return sels.any((s) => s.isSelected);
  }

  Future<void> _loadSummary() async {
    MasterContent? master = ref.read(masterContentProvider).valueOrNull;
    if (master == null) {
      try {
        master = await ref.read(masterContentProvider.future);
      } catch (_) {}
    }
    if (!mounted) return;
    if (master == null) {
      _afterRoutineSummary();
      return;
    }
    final customProds = ref.read(customProductsProvider).valueOrNull ?? [];
    final extraProducts = customProds.map((c) => c.toMasterProduct()).toList();
    RoutineBuildSummary? summary;
    try {
      summary = await ref.read(routineSchedulerProvider).buildRoutineSummary(
            master: master,
            extraProducts: extraProducts,
          );
    } catch (_) {}
    if (!mounted) return;
    if (summary == null) {
      _afterRoutineSummary();
      return;
    }
    setState(() => _summary = summary);
  }

  void _afterProductSelection() {
    setState(() {
      _summary = null;
      _stage = _Stage.routineSummary;
    });
    _loadSummary();
  }

  void _afterRoutineSummary() {
    if (_hasMorning()) {
      setState(() => _stage = _Stage.amSchedule);
    } else if (_hasEvening()) {
      setState(() => _stage = _Stage.pmSchedule);
    } else {
      _handleFinish();
    }
  }

  void _afterMorningOrder() {
    if (_hasEvening()) {
      setState(() => _stage = _Stage.pmSchedule);
    } else {
      _handleFinish();
    }
  }

  void _handleFinish() {
    if (!mounted) return;
    context.go('/week-glance');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    switch (_stage) {
      case _Stage.products:
        return ProductSelectionScreen(
          onDone: _afterProductSelection,
        );

      case _Stage.routineSummary:
        final summary = _summary;
        if (summary == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final firstSlotLabel = _hasMorning() ? l.slotMorning : l.slotEvening;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _stage = _Stage.products);
          },
          child: RoutineReadySummaryScreen(
            summary: summary,
            ctaLabel: l.routineReadyReviewSlotCta(firstSlotLabel),
            onContinue: _afterRoutineSummary,
          ),
        );

      case _Stage.amSchedule:
        return ScheduleSetupScreen(
          onboardingSlot: Slot.morning,
          onBack: () => setState(() => _stage = _Stage.routineSummary),
          onContinue: () => setState(() => _stage = _Stage.amOrder),
        );

      case _Stage.amOrder:
        return OrderCustomizationScreen(
          onboardingSlot: Slot.morning,
          onBack: () => setState(() => _stage = _Stage.amSchedule),
          onContinue: _afterMorningOrder,
        );

      case _Stage.pmSchedule:
        return ScheduleSetupScreen(
          onboardingSlot: Slot.evening,
          onBack: () => setState(() {
            _stage = _hasMorning() ? _Stage.amOrder : _Stage.routineSummary;
          }),
          onContinue: () => setState(() => _stage = _Stage.pmOrder),
        );

      case _Stage.pmOrder:
        return OrderCustomizationScreen(
          onboardingSlot: Slot.evening,
          onBack: () => setState(() => _stage = _Stage.pmSchedule),
          onContinue: _handleFinish,
        );
    }
  }
}
