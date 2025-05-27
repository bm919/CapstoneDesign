// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/report_detail_page.dart';
import 'pages/report_list_page.dart';
import 'pages/user_info_page.dart';
import 'pages/splash_page.dart';
import 'pages/main_menu_page.dart';
import 'pages/camera_page.dart';
import 'pages/gallery_page.dart';
import 'pages/chat_page.dart';
import 'pages/favorites_page.dart';
import 'pages/profile_page.dart';
import 'pages/report_page.dart';
import 'providers/guide_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/login',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isLoggingIn =
          state.uri.toString() == '/login' || state.uri.toString() == '/signup';

      if (token == null || token.isEmpty) {
        return isLoggingIn ? null : '/login';
      } else {
        return isLoggingIn ? '/main' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const UserInfoPage()),
      GoRoute(path: '/main', builder: (_, __) => const MainMenuPage()),
      GoRoute(path: '/camera', builder: (_, __) => const CameraPage()),
      GoRoute(
        path: '/home/photo',
        builder: (_, __) => const CameraPage(),
        routes: [
          GoRoute(
            path: 'save',
            name: 'gallery',
            builder: (_, state) => GalleryPage(
              imagePath: state.extra as String,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null || extra['imagePath'] == null || extra['label'] == null) {
            return const Scaffold(
              body: Center(child: Text('잘못된 경로입니다')),
            );
          }
          return ChatPage(
            imagePath: extra['imagePath'],
            label: extra['label'],
            rule: extra['rule'] ?? '',
          );
        },
      ),
      GoRoute(path: '/favorites', name: 'favorites', builder: (_, __) => const FavoritesPage()),
      GoRoute(
        path: '/report-error',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ReportErrorPage(
            imagePath: extras['imagePath'] ?? '',
            imageId: extras['imageId'] is int ? extras['imageId'] : null,
            label: extras['label'] ?? '',
            rule: extras['rule'] ?? '',
          );
        },
      ),
      GoRoute(path: '/report-list', builder: (_, __) => const ReportListPage()),
      GoRoute(
        path: '/report-detail',
        builder: (context, state) {
          final report = state.extra as Map<String, dynamic>;
          return ReportDetailPage(report: report);
        },
      ),
      GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const ProfilePage()),
    ],
  );
});