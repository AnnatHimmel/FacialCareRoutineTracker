import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? '';
    final profileAsync = ref.watch(_userProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(title: l.navSettings),
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
          const SizedBox(height: 16),

          // ── Standard settings group ─────────────────────────────────────────
          _SettingsGroupCard(
            children: [
              const _LanguageTile(),
              _SettingsTile(
                icon: Icons.cloud_download_outlined,
                label: l.exportTitle,
                subtitle: l.settingsExportSubtitle,
                onTap: () => context.push('/export-import'),
              ),
              _SettingsTile(
                icon: Icons.info_outlined,
                label: l.settingsAbout,
                subtitle: l.settingsAboutSubtitle(appVersion),
                onTap: () => context.push('/about'),
              ),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                label: l.settingsContactUs,
                subtitle: l.settingsContactUsSubtitle,
                onTap: () => _showContactUsSheet(context, l),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const _WeeklyReminderToggleCard(),

          // Debug-only tools. Stripped from release/profile builds.
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const _DebugResumeReminderCard(),
            const SizedBox(height: 16),
            const _DebugClearShelfCard(),
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
    final IconData? genderIcon =
        gender == 'female' ? Icons.female : gender == 'male' ? Icons.male : null;
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGlowGradient,
        shape: BoxShape.circle,
        boxShadow: AppColors.glowSm,
      ),
      alignment: Alignment.center,
      child: genderIcon != null
          ? Icon(genderIcon, color: AppColors.onPrimary, size: 28)
          : Text(
              initial,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
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
          final savedLang = await settings.getAppLanguage();
          if (savedLang != 'en') {
            ref.read(appLocaleProvider.notifier).state =
                gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
          }
        }
        ref.invalidate(_userProfileProvider);
        ref.invalidate(userNameProvider);
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

// ── Contact Us Sheet ───────────────────────────────────────────────────────────

Future<void> _showContactUsSheet(
    BuildContext context, AppLocalizations l) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ContactUsSheet(l: l),
  );
}

class _ContactUsSheet extends StatefulWidget {
  final AppLocalizations l;
  const _ContactUsSheet({required this.l});

  @override
  State<_ContactUsSheet> createState() => _ContactUsSheetState();
}

class _ContactUsSheetState extends State<_ContactUsSheet> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final hasText = _msgCtrl.text.trim().isNotEmpty;

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
              l.settingsContactUsSheetTitle,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 5,
                minLines: 3,
                textAlign: TextAlign.start,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: l.settingsContactUsMessageHint,
                  hintStyle: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: hasText ? 1.0 : 0.5,
              child: GestureDetector(
                onTap: (!hasText || _sending) ? null : _doSend,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: hasText ? AppColors.primaryGlowGradient : null,
                    color: !hasText ? AppColors.surfaceHigh : null,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: hasText ? AppColors.glowSm : null,
                  ),
                  alignment: Alignment.center,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(
                          l.settingsContactUsSend,
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

  Future<void> _doSend() async {
    setState(() => _sending = true);
    final subject = Uri.encodeComponent('Feedback from application');
    final body = Uri.encodeComponent(_msgCtrl.text.trim());
    final uri = Uri.parse(
        'mailto:opengridstudio@gmail.com?subject=$subject&body=$body');
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l.settingsContactUsCannotSend)),
      );
    }
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
    await ref.read(userDataRepositoryProvider).clearRoutineData();
    await ref.read(settingsRepositoryProvider).clearUserProfile();
    ref.invalidate(onboardingCompletedProvider);
    // Force the startup auto-fix to re-run on next app_entry mount so it
    // assigns default spread schedules and re-resolves all conflicts from scratch.
    ref.invalidate(conflictAutoFixProvider);
    if (context.mounted) context.go('/');
  }
}

// ── Weekly Reminder Toggle Card ─────────────────────────────────────────────────

class _WeeklyReminderToggleCard extends ConsumerWidget {
  const _WeeklyReminderToggleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final enabled =
        ref.watch(weeklyReminderEnabledProvider).valueOrNull ?? true;

    return GlowCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsWeeklyReminder,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l.settingsWeeklyReminderDesc,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (v) async {
              await ref
                  .read(settingsRepositoryProvider)
                  .setWeeklyReminderEnabled(v);
              ref.invalidate(weeklyReminderEnabledProvider);
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Debug-only: Resume Weekly Reminder ──────────────────────────────────────────

class _DebugResumeReminderCard extends ConsumerWidget {
  const _DebugResumeReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return GlowCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final settings = ref.read(settingsRepositoryProvider);
          await settings.setWeeklyReminderEnabled(true);
          // Clear today's snooze so the card is eligible again immediately.
          await settings.setWeeklyPhotoReminderDismissedDate('');
          // Force-show overrides the recent-photo gate: the card reappears even
          // if a skin photo was already logged this week (the common case when
          // testing). Cleared automatically once a new photo is captured.
          ref.read(weeklyReminderForceShowProvider.notifier).state = true;
          ref.invalidate(weeklyReminderEnabledProvider);
          ref.invalidate(weeklyReminderDismissedDateProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.settingsDebugResumeReminderDone)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsDebugResumeReminder,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l.settingsDebugSectionNote,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.refresh_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugClearShelfCard extends ConsumerWidget {
  const _DebugClearShelfCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return GlowCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.settingsDebugClearShelf, textAlign: TextAlign.start),
              content: Text(
                l.settingsDebugClearShelfConfirm,
                textAlign: TextAlign.start,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l.cancelAction),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    l.settingsDebugClearShelf,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          await ref.read(debugClearShelfProvider)();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.settingsDebugClearShelfDone)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_outlined,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsDebugClearShelf,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l.settingsDebugSectionNote,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Group Card ────────────────────────────────────────────────────────

class _SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.glow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: AppColors.outlineVariant.withAlpha(51),
                indent: 68,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              textDirection: TextDirection.ltr,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language Tile (ConsumerWidget — needs locale provider) ─────────────────────

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);
    final isEnglish = locale.languageCode == 'en';
    final currentLabel =
        isEnglish ? l.settingsLanguageEnglish : l.settingsLanguageHebrew;

    return _SettingsTile(
      icon: Icons.language,
      label: l.settingsLanguage,
      subtitle: currentLabel,
      onTap: () => _showLanguagePicker(context, ref, l, isEnglish),
    );
  }
}

// ── Language Picker Dialog ─────────────────────────────────────────────────────

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
