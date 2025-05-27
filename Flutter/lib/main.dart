import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: WasteGuideApp()));
}

class WasteGuideApp extends ConsumerWidget {
  const WasteGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider); // 여기!

    return MaterialApp.router(
      title: 'Waste Guide',
      theme: theme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
