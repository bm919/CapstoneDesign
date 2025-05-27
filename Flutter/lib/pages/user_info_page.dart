import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key});

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _emailFocus = FocusNode();

  String? _region = _regions[0];
  static const List<String> _regions = ['서울시', '춘천시', '원주시', '남양주시'];

  String? _validateId() {
    final v = _idCtrl.text;
    if (v.isEmpty) return 'ID를 입력하세요';
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!regex.hasMatch(v)) return '영문과 숫자만 입력하세요';
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) return '영문과 숫자가 모두 포함되어야 합니다';
    return null;
  }

  String? _validatePw() {
    final v = _pwCtrl.text;
    if (v.isEmpty) return '비밀번호를 입력하세요';
    if (v.length > 16) return '16자 이내로 입력하세요';
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v);
    if (!(hasLetter && hasDigit && hasSpecial)) {
      return '영문, 숫자, 특수문자를 포함해야 합니다';
    }
    return null;
  }

  String? _validatePwConfirm() {
    final v = _pwConfirmCtrl.text;
    if (v.isEmpty) return '비밀번호 확인란을 입력하세요';
    if (v != _pwCtrl.text) return '비밀번호가 일치하지 않습니다';
    return null;
  }

  String? _validateEmail() {
    final v = _emailCtrl.text;
    if (v.isEmpty) return '이메일을 입력하세요';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(v)) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _emailCtrl.dispose();
    _idFocus.dispose();
    _pwFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    // 먼저 전체 폼 유효성 검사
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    // region 선택 여부 검사
    if (_region == null || _region!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역을 선택해주세요.')),
      );
      return;
    }

    final trimmedRegion = _region!.trim();

    print('📤 최종 회원가입 전송 데이터:');
    print('ID: ${_idCtrl.text}');
    print('PW: ${_pwCtrl.text}');
    print('EMAIL: ${_emailCtrl.text}');
    print('current_location_id: $trimmedRegion');

    final result = await ref.read(authProvider.notifier).signup(
      _idCtrl.text.trim(),
      _pwCtrl.text,
      _emailCtrl.text.trim(),
      trimmedRegion, // ✅ 공백 제거된 지역 문자열 전달
    );

    final token = ref.read(authProvider);
    print("🔐 현재 로그인된 토큰: $token");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? '회원가입 처리 완료')),
    );

    if (result.success) {
      context.go('/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '회원가입 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          title: const Text('회원가입'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(), // 또는 context.pushReplacement('/login')
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'ID (영문, 숫자를 포함한 16자 이내)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _idCtrl,
                  focusNode: _idFocus,
                  maxLength: 16,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'ID',
                  ),
                  validator: (_) => _validateId(),
                ),
                const SizedBox(height: 16),

                const Text(
                  '비밀번호 (영문, 숫자, 특수문자를 포함한 16자 이내)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _pwCtrl,
                  focusNode: _pwFocus,
                  obscureText: true,
                  maxLength: 16,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  validator: (_) => _validatePw(),
                ),
                const SizedBox(height: 16),

                const Text(
                  '비밀번호 확인',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _pwConfirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  validator: (_) => _validatePwConfirm(),
                ),
                const SizedBox(height: 16),

                const Text(
                  '이메일 주소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  decoration: const InputDecoration(
                    labelText: 'email@domain.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (_) => _validateEmail(),
                ),
                const SizedBox(height: 16),

                const Text(
                  '지역 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '지역 선택',
                  ),
                  value: _region,
                  isExpanded: true,
                  items: _regions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _region = v),
                  validator: (v) => v == null ? '지역을 선택하세요' : null,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('다음'),
            ),
          ),
        ),
      );
  }
}