import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/providers/root_providers.dart';

class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(onboardingCompletedProvider);
    final startupAsync = ref.watch(silentStartupProvider);

    if (setupAsync.isLoading || startupAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final completed = setupAsync.valueOrNull ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(completed ? '/today' : '/setup/selection?from=setup');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
