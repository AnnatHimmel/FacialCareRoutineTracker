import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/services/routine_build_summary.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/primary_button.dart';
import '../setup/category_review_screen.dart';
import '../setup/order_customization_screen.dart';
import '../setup/product_selection_screen.dart';
import '../setup/routine_ready_summary_screen.dart';
import '../setup/schedule_setup_screen.dart';

// Wizard sub-stages within Step 3 (product setup)
enum _SetupStage {
  products,
  categoryReview,
  routineSummary,
  amSchedule,
  amOrder,
  pmSchedule,
  pmOrder,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Step 0 = language selection (before any locale-dependent text)
  // Step 1 = welcome
  // Step 2 = personal info
  // Step 3 = product/schedule setup wizard
  int _step = 0;
  _SetupStage _stage = _SetupStage.products;
  String _name = '';
  String? _gender;
  // The auto-sorter's "routine ready" summary, shown at the routineSummary
  // stage after categoryReview. Cached so back-navigation from amSchedule
  // reuses the already-built summary without a rebuild.
  RoutineBuildSummary? _summary;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  // Saves name+gender to disk immediately when the user leaves Step 2.
  // Uses fire-and-forget because product selection gives enough time before
  // the data is needed, and saving the same values twice in _handleFinish is harmless.
  void _onStep2Continue() {
    _persistPersonalInfo();
    _next();
  }

  Future<void> _persistPersonalInfo() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      if (_name.trim().isNotEmpty) await settings.setUserName(_name.trim());
      if (_gender != null) await settings.setUserGender(_gender!);
    } catch (_) {}
  }

  Future<void> _handleFinish() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      // Save name and gender independently so a failure in one does not
      // prevent onboarding_completed from being written below.
      try {
        if (_name.trim().isNotEmpty) {
          await settings.setUserName(_name.trim());
        }
        if (_gender != null) {
          await settings.setUserGender(_gender!);
          if (ref.read(appLocaleProvider).languageCode != 'en') {
            ref.read(appLocaleProvider.notifier).state =
                _gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
          }
        }
      } catch (_) {}
      // Always mark onboarding done — if this is skipped the app re-routes to
      // onboarding on every cold start, losing all previously entered data.
      await settings.setOnboardingCompleted(true);
    } catch (_) {
      // Repository may not be available in tests; always proceed.
    }
    if (!mounted) return;
    widget.onFinish();
  }

  // Populates _summary for the routineSummary stage. Mirrors the logic in
  // RoutineReadyRoute._build(). Falls back to _afterRoutineSummary() if the
  // summary cannot be built so the flow never dead-ends.
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

  // Called from the routineSummary CTA — routes to the first schedule stage.
  void _afterRoutineSummary() {
    if (_hasMorning()) {
      setState(() => _stage = _SetupStage.amSchedule);
    } else if (_hasEvening()) {
      setState(() => _stage = _SetupStage.pmSchedule);
    } else {
      _handleFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 0: language picker — rendered before any l10n text
    if (_step == 0) return _LanguageSelectionStep(onSelect: _onLanguageSelected);

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _step == 1
            ? _buildStep1(l)
            : _step == 2
                ? _buildStep2(l)
                : _buildStep3(),
      ),
    );
  }

  Future<void> _onLanguageSelected(String languageCode) async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.setAppLanguage(languageCode);
      if (languageCode == 'en') {
        ref.read(appLocaleProvider.notifier).state = const Locale('en');
      } else {
        ref.read(appLocaleProvider.notifier).state = const Locale('he');
      }
    } catch (_) {}
    _next();
  }

  Widget _buildStep1(AppLocalizations l) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 168),
                Image.asset(
                  'assets/images/app_icon_no_bg.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The Glow Protocol',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.onboardingTagline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildFeaturePills(l),
              ],
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: _back,
                        borderRadius: BorderRadius.circular(9999),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: l.onboardingStartNeutral,
                      trailingIcon: Icons.arrow_forward,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.onboardingTakesMinute,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePills(AppLocalizations l) {
    final features = [
      (Icons.checklist_rounded, l.onboardingFeature1),
      (Icons.event_rounded, l.onboardingFeature2),
      (Icons.auto_stories_rounded, l.onboardingFeature3),
    ];
    return Column(
      children: features.map((f) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(f.$1, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(f.$2),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2(AppLocalizations l) {
    final canContinue = _name.trim().isNotEmpty && _gender != null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  l.onboardingTellUsNeutral,
                  style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(l.onboardingPrivacyDesc),
                const SizedBox(height: 24),
                Text(l.onboardingNamePrompt),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: l.onboardingNameHint,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (v) => setState(() => _name = v),
                ),
                const SizedBox(height: 20),
                Text(l.onboardingGenderLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _genderButton(l.onboardingGenderFemale, 'female')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _genderButton(l.onboardingGenderMale, 'male')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(l.onboardingPrivacyLock,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: _back,
                    borderRadius: BorderRadius.circular(9999),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: canContinue ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !canContinue,
                    child: PrimaryButton(
                      label: l.continueActionNeutral,
                      trailingIcon: Icons.arrow_forward,
                      onTap: _onStep2Continue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String label, String value) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() => _gender = value);
        final locale = ref.read(appLocaleProvider);
        if (locale.languageCode != 'en') {
          ref.read(appLocaleProvider.notifier).state =
              value == 'male' ? const Locale('he', 'MA') : const Locale('he');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Step 3 helpers ──────────────────────────────────────────────────────────

  bool _hasMorning() {
    final sels = ref.read(selectionsProvider(Slot.morning)).valueOrNull ?? [];
    return sels.any((s) => s.isSelected);
  }

  bool _hasEvening() {
    final sels = ref.read(selectionsProvider(Slot.evening)).valueOrNull ?? [];
    return sels.any((s) => s.isSelected);
  }

  // Called from categoryReview → always go to routineSummary first, where the
  // auto-sorter result is presented. _afterRoutineSummary then routes to the
  // appropriate schedule stage.
  void _afterCategoryReview() {
    setState(() {
      _summary = null;
      _stage = _SetupStage.routineSummary;
    });
    _loadSummary();
  }

  // Called from amOrder → go to pmSchedule directly if evening products exist.
  void _afterMorningOrder() {
    if (_hasEvening()) {
      setState(() => _stage = _SetupStage.pmSchedule);
    } else {
      _handleFinish();
    }
  }

  Widget _buildStep3() {
    switch (_stage) {
      case _SetupStage.products:
        return ProductSelectionScreen(
          onDone: () => setState(() => _stage = _SetupStage.categoryReview),
        );
      case _SetupStage.categoryReview:
        return CategoryReviewScreen(
          onBack: () => setState(() => _stage = _SetupStage.products),
          onNext: _afterCategoryReview,
        );
      case _SetupStage.routineSummary:
        final summary = _summary;
        if (summary == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final l = AppLocalizations.of(context)!;
        final firstSlotLabel = _hasMorning() ? l.slotMorning : l.slotEvening;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              setState(() => _stage = _SetupStage.categoryReview);
            }
          },
          child: RoutineReadySummaryScreen(
            summary: summary,
            ctaLabel: l.routineReadyReviewSlotCta(firstSlotLabel),
            onContinue: _afterRoutineSummary,
          ),
        );
      case _SetupStage.amSchedule:
        // Back returns to routineSummary without rebuilding; cached _summary is reused.
        return ScheduleSetupScreen(
          onboardingSlot: Slot.morning,
          onBack: () => setState(() => _stage = _SetupStage.routineSummary),
          onContinue: () => setState(() => _stage = _SetupStage.amOrder),
        );
      case _SetupStage.amOrder:
        return OrderCustomizationScreen(
          onboardingSlot: Slot.morning,
          onBack: () => setState(() => _stage = _SetupStage.amSchedule),
          onContinue: _afterMorningOrder,
        );
      case _SetupStage.pmSchedule:
        return ScheduleSetupScreen(
          onboardingSlot: Slot.evening,
          onBack: () => setState(() {
            _stage = _hasMorning()
                ? _SetupStage.amOrder
                : _SetupStage.routineSummary;
          }),
          onContinue: () => setState(() => _stage = _SetupStage.pmOrder),
        );
      case _SetupStage.pmOrder:
        return OrderCustomizationScreen(
          onboardingSlot: Slot.evening,
          onBack: () => setState(() => _stage = _SetupStage.pmSchedule),
          onContinue: _handleFinish,
        );
    }
  }
}

// ── Language Selection Step (step 0) ──────────────────────────────────────────
// Shown before any localized text is rendered, so language names are hardcoded.

class _LanguageSelectionStep extends StatelessWidget {
  final Future<void> Function(String languageCode) onSelect;

  const _LanguageSelectionStep({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/app_icon_no_bg.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 40),
              _LangButton(
                label: 'עברית',
                sublabel: 'Hebrew',
                onTap: () => onSelect('he'),
              ),
              const SizedBox(height: 14),
              _LangButton(
                label: 'English',
                sublabel: 'אנגלית',
                onTap: () => onSelect('en'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: AppColors.glowSm,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
