import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/radiant_dew_theme.dart';
import 'shared/providers/root_providers.dart';

class SkincareApp extends ConsumerWidget {
  const SkincareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync locale from saved gender on first build; ignored once resolved.
    ref.watch(localeSyncProvider);
    final locale = ref.watch(appLocaleProvider);

    final isRtl = locale.languageCode != 'en';

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: RadiantDewTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}
