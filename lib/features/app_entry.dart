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
    final localeSyncAsync = ref.watch(localeSyncProvider);

    if (setupAsync.isLoading ||
        startupAsync.isLoading ||
        localeSyncAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final completed = setupAsync.valueOrNull ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(completed ? '/today' : '/onboarding');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
