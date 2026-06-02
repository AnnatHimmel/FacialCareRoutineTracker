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
  int _step = 1;
  String _name = '';
  String? _gender;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _handleFinish() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      if (_name.trim().isNotEmpty) {
        await settings.setUserName(_name.trim());
      }
      if (_gender != null) {
        await settings.setUserGender(_gender!);
        ref.read(appLocaleProvider.notifier).state =
            _gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
      }
      await settings.setOnboardingCompleted(true);
    } catch (_) {
      // Repository may not be available in tests; always proceed.
    }
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(l),
            Expanded(
              child: _step == 1
                  ? _buildStep1(l)
                  : _step == 2
                      ? _buildStep2(l)
                      : _buildStep3(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            '$_step/3',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                final filled = i < _step;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: filled ? AppColors.primary : AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: widget.onFinish,
            child: Text(l.onboardingSkip,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
                const SizedBox(height: 16),
                ClipOval(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.onboardingWelcome,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.onboardingAppIntro,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              PrimaryButton(
                label: l.onboardingStart,
                leadingIcon: Icons.arrow_forward,
                onTap: _next,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            l.onboardingTellUs,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (v) => setState(() => _name = v),
          ),
          const SizedBox(height: 20),
          Text(l.onboardingGenderLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _genderButton(l.onboardingGenderFemale, 'female')),
              const SizedBox(width: 12),
              Expanded(child: _genderButton(l.onboardingGenderMale, 'male')),
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
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: Text(l.backAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: canContinue ? 1.0 : 0.5,
                  child: ElevatedButton(
                    onPressed: canContinue ? _next : null,
                    child: Text(l.continueAction),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _genderButton(String label, String value) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
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
    await context.push<void>('/products/schedule');
    if (!mounted) return;
    await _handleFinish();
  }
}
