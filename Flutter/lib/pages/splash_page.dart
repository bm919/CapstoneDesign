import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider);
    Future.microtask(() {
      if (token != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
