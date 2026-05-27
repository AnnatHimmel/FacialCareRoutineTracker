import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/providers/root_providers.dart';

class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(onboardingCompletedProvider);

    return setupAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/setup/selection?from=setup');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      data: (completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            if (completed) {
              context.go('/today');
            } else {
              context.go('/setup/selection?from=setup');
            }
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
