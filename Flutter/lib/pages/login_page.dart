import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController();
  final _pw = TextEditingController();
  bool _isTapped = false;

  Future<void> _submit() async {
    print("!!!!!!!로그인 시작!!!!!!!");
    if (_username.text.isEmpty || _pw.text.isEmpty) {
      if (!mounted) return; // ❗ 위젯이 여전히 살아있을 때만 context 사용
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final result = await ref.read(authProvider.notifier).login(_username.text, _pw.text);

    if (!mounted) return; // ✅ 여기서도 비동기 이후 context 사용 전 확인

    if (result.success) {
      context.go('/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '로그인 실패')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.2),
                    // ✅ 화면 위에서 1/4 지점
                    Text(
                      '분리배출 도우미',
                      style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '로그인',
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _username,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pw,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8B4B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('아직 회원이 아니신가요? '),
                        GestureDetector(
                          onTap: () {
                            context.go('/signup');
                          },
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'By clicking continue, you agree to our Term of Service\nand Privacy Policy',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}