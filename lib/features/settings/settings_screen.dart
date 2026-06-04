import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/backup_reminder_banner.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

final _userProfileProvider = FutureProvider<({String? name, String? gender})>(
  (ref) async {
    final settings = ref.watch(settingsRepositoryProvider);
    final name = await settings.getUserName();
    final gender = await settings.getUserGender();
    return (name: name, gender: gender);
  },
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final appVersion = masterAsync.valueOrNull?.manifest.appVersion ?? '—';
    final profileAsync = ref.watch(_userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _ProfileCard(
            profileAsync: profileAsync,
            onEdit: () => _showEditProfileSheet(context, ref, l),
            onLogout: () => _confirmLogout(context, ref, l),
            l: l,
          ),

          const SizedBox(height: 16),
          const BackupReminderBanner(),
          const SizedBox(height: 8),

          _SectionLabel(label: l.settingsSectionRoutine),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.reorder,
            label: l.settingsOrderProducts,
            subtitle: l.settingsOrderSubtitle,
            onTap: () => context.push('/setup/order'),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: l.settingsSectionData),
          const SizedBox(height: 8),

          _LanguageRow(),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.cloud_download_outlined,
            label: l.exportTitle,
            subtitle: l.settingsExportSubtitle,
            onTap: () => context.push('/export-import'),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: l.settingsSectionInfo),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.info_outlined,
            label: l.settingsAbout,
            subtitle: l.settingsAboutSubtitle(appVersion),
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.system_update_outlined,
            label: l.settingsCheckUpdates,
            subtitle: l.settingsCheckUpdatesSubtitle,
            onTap: () => context.push('/update-review'),
          ),

          if (kIsWeb) ...[
            const SizedBox(height: 12),
            _SettingsRow(
              icon: Icons.workspace_premium_outlined,
              label: l.settingsPremium,
              subtitle: l.settingsPremiumSubtitle,
              onTap: () => context.push('/premium'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Profile Card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AsyncValue<({String? name, String? gender})> profileAsync;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  final AppLocalizations l;

  const _ProfileCard({
    required this.profileAsync,
    required this.onEdit,
    required this.onLogout,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.valueOrNull;
    final name = profile?.name;
    final gender = profile?.gender;
    final displayName = (name != null && name.isNotEmpty) ? name : l.settingsProfileGuest;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GlowCard(
      padding: const EdgeInsets.all(20),
      shadow: AppColors.glowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarCircle(initial: initial, gender: gender),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfileActionButton(
                  icon: Icons.edit_outlined,
                  label: l.settingsProfileEdit,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileActionButton(
                  icon: Icons.logout_rounded,
                  label: l.settingsLogout,
                  onTap: onLogout,
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initial;
  final String? gender;
  const _AvatarCircle({required this.initial, this.gender});

  @override
  Widget build(BuildContext context) {
    final symbol = gender == 'female' ? '♀' : gender == 'male' ? '♂' : null;
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGlowGradient,
        shape: BoxShape.circle,
        boxShadow: AppColors.glowSm,
      ),
      alignment: Alignment.center,
      child: Text(
        symbol ?? initial,
        style: AppTypography.headlineMd.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: symbol != null ? 26 : 22,
        ),
      ),
    );
  }
}


class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    final bgColor = isDestructive
        ? AppColors.errorContainer.withAlpha(80)
        : AppColors.primaryFixed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: color.withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet ─────────────────────────────────────────────────────────

Future<void> _showEditProfileSheet(
    BuildContext context, WidgetRef ref, AppLocalizations l) async {
  final profile = ref.read(_userProfileProvider).valueOrNull;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditProfileSheet(
      initialName: profile?.name ?? '',
      initialGender: profile?.gender,
      l: l,
      onSave: (name, gender) async {
        final settings = ref.read(settingsRepositoryProvider);
        if (name.trim().isNotEmpty) await settings.setUserName(name.trim());
        if (gender != null) {
          await settings.setUserGender(gender);
          ref.read(appLocaleProvider.notifier).state =
              gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
        }
        ref.invalidate(_userProfileProvider);
      },
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String? initialGender;
  final AppLocalizations l;
  final Future<void> Function(String name, String? gender) onSave;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialGender,
    required this.l,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _gender = widget.initialGender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.settingsProfileEdit,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            Text(
              l.settingsProfileNameLabel,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.start,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: l.settingsProfileNameHint,
                  hintStyle: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.onboardingGenderLabel,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _genderBtn(l.onboardingGenderFemale, 'female')),
                const SizedBox(width: 12),
                Expanded(child: _genderBtn(l.onboardingGenderMale, 'male')),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _nameCtrl.text.trim().isNotEmpty ? 1.0 : 0.5,
              child: GestureDetector(
                onTap: _nameCtrl.text.trim().isEmpty || _saving
                    ? null
                    : _doSave,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _nameCtrl.text.trim().isNotEmpty
                        ? AppColors.primaryGlowGradient
                        : null,
                    color: _nameCtrl.text.trim().isEmpty
                        ? AppColors.surfaceHigh
                        : null,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: _nameCtrl.text.trim().isNotEmpty
                        ? AppColors.glowSm
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(
                          l.settingsProfileSave,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderBtn(String label, String value) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: selected ? AppColors.glowSm : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _doSave() async {
    setState(() => _saving = true);
    await widget.onSave(_nameCtrl.text, _gender);
    if (mounted) Navigator.of(context).pop();
  }
}

// ── Logout ─────────────────────────────────────────────────────────────────────

Future<void> _confirmLogout(
    BuildContext context, WidgetRef ref, AppLocalizations l) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.settingsLogout, textAlign: TextAlign.start),
      content: Text(
        l.settingsLogoutConfirmContent,
        textAlign: TextAlign.start,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.settingsLogoutConfirmBtn,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(settingsRepositoryProvider).clearUserProfile();
    ref.invalidate(onboardingCompletedProvider);
    if (context.mounted) context.go('/');
  }
}

// ── Shared section helpers ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        label,
        textAlign: TextAlign.start,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LanguageRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);
    final isEnglish = locale.languageCode == 'en';
    final currentLabel = isEnglish ? l.settingsLanguageEnglish : l.settingsLanguageHebrew;

    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shadow: AppColors.glowSm,
      onTap: () => _showLanguagePicker(context, ref, l, isEnglish),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsLanguage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  currentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}

Future<void> _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l,
  bool isEnglish,
) async {
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l.settingsLanguage),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop('he'),
          child: Row(
            children: [
              if (!isEnglish)
                const Icon(Icons.check, size: 20, color: AppColors.primary),
              if (isEnglish) const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(l.settingsLanguageHebrew),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop('en'),
          child: Row(
            children: [
              if (isEnglish)
                const Icon(Icons.check, size: 20, color: AppColors.primary),
              if (!isEnglish) const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(l.settingsLanguageEnglish),
            ],
          ),
        ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  final settings = ref.read(settingsRepositoryProvider);
  await settings.setAppLanguage(picked);
  if (picked == 'en') {
    ref.read(appLocaleProvider.notifier).state = const Locale('en');
  } else {
    final gender = await settings.getUserGender();
    ref.read(appLocaleProvider.notifier).state =
        gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shadow: AppColors.glowSm,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}
