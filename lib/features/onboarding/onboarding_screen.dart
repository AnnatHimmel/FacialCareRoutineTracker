import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/primary_button.dart';
import '../setup/product_selection_screen.dart';

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
  // Step 3 = product selection
  int _step = 0;
  String _name = '';
  String? _gender;

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
      await settings.setOnboardingCompleted(true);
    } catch (_) {
      // Repository may not be available in tests; always proceed.
    }
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    // Step 0: language picker — rendered before any l10n text
    if (_step == 0) return _LanguageSelectionStep(onSelect: _onLanguageSelected);

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
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
                  textDirection: TextDirection.rtl,
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

  Widget _buildStep3() {
    return ProductSelectionScreen(onDone: () => _continueToSchedule());
  }

  Future<void> _continueToSchedule() async {
    // Use /setup/schedule (no fromProducts flag) so _handleContinue pops with
    // true instead of calling context.go('/today'), which would silently drop
    // the push result and prevent _handleFinish from ever running.
    final finished = await context.push<bool>('/setup/schedule');
    if (!mounted) return;
    if (finished == true) {
      await _handleFinish();
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
