import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color seedColor = const Color(0xFF5B8B4B);
    final double buttonWidth = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 80),
                const Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 70),

                _MainMenuButton(
                  icon: Icons.edit,
                  label: '사진 촬영하여\n시작하기',
                  color: seedColor,
                  width: buttonWidth,
                  onTap: () => context.push('/camera'),
                ),
                const SizedBox(height: 30),

                _MainMenuButton(
                  icon: Icons.star,
                  label: '즐겨찾기',
                  color: seedColor,
                  width: buttonWidth,
                  onTap: () => context.push('/favorites'),
                ),
                const SizedBox(height: 30),

                _MainMenuButton(
                  icon: Icons.info_outline,
                  label: '신고 목록',
                  color: seedColor,
                  width: buttonWidth,
                  onTap: () => context.push('/report-list'),
                ),
                const SizedBox(height: 30),

                _MainMenuButton(
                  icon: Icons.person,
                  label: '내 정보',
                  color: seedColor,
                  width: buttonWidth,
                  onTap: () => context.push('/profile'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _MainMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // 더 큼
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
