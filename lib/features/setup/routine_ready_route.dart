import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/services/routine_build_summary.dart';
import '../../shared/providers/root_providers.dart';
import 'routine_ready_summary_screen.dart';

/// Terminal route that runs the auto-sorter and shows the "routine ready"
/// summary. This is the single, reliable entry point every routine-changing
/// flow navigates to (`context.go('/routine-ready')`) once its mutations are
/// persisted — replacing the three divergent mechanisms that previously showed
/// the summary inconsistently.
///
/// It builds the [RoutineBuildSummary] itself from the scheduler (which now
/// fetches custom products internally via [RoutineService.allProducts], so
/// no `extraProducts` argument is needed), then hands off to the shelf
/// (`/collection`) via the summary's single CTA. If the summary can't be built
/// it redirects straight to the shelf so the flow never dead-ends.
class RoutineReadyRoute extends ConsumerStatefulWidget {
  const RoutineReadyRoute({super.key});

  @override
  ConsumerState<RoutineReadyRoute> createState() => _RoutineReadyRouteState();
}

class _RoutineReadyRouteState extends ConsumerState<RoutineReadyRoute> {
  late final Future<RoutineBuildSummary?> _future = _build();

  Future<RoutineBuildSummary?> _build() async {
    MasterContent? master = ref.read(masterContentProvider).valueOrNull;
    master ??= await ref.read(masterContentProvider.future);
    if (master == null) return null;
    return ref.read(routineServiceProvider).buildRoutineSummary(
          master: master,
        );
  }

  bool _navigatedAway = false;

  void _goToShelf() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    // Defer the actual navigation out of the current call stack. When this is
    // reached from PopScope.onPopInvoked the Navigator is mid-pop and locked;
    // calling context.go synchronously trips the `!_debugLocked` assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/collection');
    });
  }

  @override
  Widget build(BuildContext context) {
    // This route is reached via `context.go('/routine-ready')`, which replaces
    // go_router's match list with a single entry. A system back-press would
    // pop that lone entry and crash ("no pages left to show"), so intercept it
    // and route to the shelf instead.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToShelf();
      },
      child: FutureBuilder<RoutineBuildSummary?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: AppColors.surface,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final summary = snapshot.data;
          if (summary == null) {
            // Could not build a summary — don't dead-end; bounce to the shelf.
            WidgetsBinding.instance.addPostFrameCallback((_) => _goToShelf());
            return const Scaffold(
              backgroundColor: AppColors.surface,
              body: SizedBox.shrink(),
            );
          }
          return RoutineReadySummaryScreen(
            summary: summary,
            onContinue: _goToShelf,
          );
        },
      ),
    );
  }
}
