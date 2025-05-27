import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:core';
import 'package:recycling_helper/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordCheckController = TextEditingController();
  String _username = '';
  String _region = '서울시';
  bool _isEditing = false;
  final Color seedColor = const Color(0xFF5B8B4B);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await ApiService.getUserInfo();
    if (user != null) {
      print('🔍 서버 응답 region 값: ${user['region']}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user['username'] ?? '');

      final rawRegion = user['current_location_id']?.toString().trim();
      final validRegions = ['서울시', '춘천시', '원주시', '남양주시'];

      setState(() {
        _username = user['username'] ?? '알 수 없음';
        _emailController.text = user['email'] ?? '';
        _region = validRegions.contains(rawRegion) ? rawRegion! : '서울시';
      });

      print('✅ 서버 응답 지역 (current_location_id): $_region');
    }
  }


  void _tryEdit() {
    setState(() => _isEditing = true);
  }

  void _tryDelete() async {
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('탈퇴하려면 아래 입력란에 "탈퇴"라고 입력하세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: '확인 문구 입력'),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: seedColor,
            ),
            onPressed: () {
              if (confirmController.text.trim() != '탈퇴') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('"탈퇴"라고 정확히 입력해야 합니다.')),
                );
                return;
              }
              Navigator.of(context).pop(true); // 탈퇴 진행
            },
            child: const Text('탈퇴하기'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: seedColor,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ApiService.deleteUser();
      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        ref.read(authProvider.notifier).logout();

        // ✅ 이제 context 안전하니 go 가능!
        if (mounted) context.go('/login');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('탈퇴에 실패했습니다.')),
          );
        }
      }
    }
  }
  void _logout() {
    context.go('/login');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^.+@.+\..+').hasMatch(email);
  }


  bool _isValidPassword(String password) {
    return RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[A-Za-z\d!@#\$%^&*(),.?":{}|<>]{1,16}$').hasMatch(password);
  }

  Future<void> _saveChanges() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _passwordCheckController.text;

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식이 아닙니다.')),
      );
      return;
    }

    if (password.isNotEmpty && !_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 영문, 숫자, 특수기호 포함 16자 이하여야 합니다.')),
      );
      return;
    }

    if (password.isNotEmpty && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 확인이 일치하지 않습니다.')),
      );
      return;
    }

    final success = await ApiService.updateUserInfo(_username, _region, _emailController.text, password:password);
    if (success && mounted) {
      await _loadUserInfo();
      setState(() {
        _isEditing = false;
      }); // ✅ 저장 후 UI 반영용 setState
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보가 수정되었습니다.')),
      );
    } else {
      print('❌ 사용자 정보 수정 실패. 서버 응답이 200이 아닐 수 있습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보 수정에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.15),
        title: const Text('내 정보'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/main'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: _username),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'ID',
                labelStyle: TextStyle(fontSize: 24),
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              readOnly: !_isEditing,
              decoration: const InputDecoration(
                labelText: '이메일',
                labelStyle: TextStyle(fontSize: 24),
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 24),
            if (_isEditing) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호'),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCheckController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
            ],
            DropdownButtonFormField<String>(
              value: _region.isNotEmpty ? _region : null,
              items: ['서울시', '춘천시', '원주시', '남양주시']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: _isEditing ? (v) => setState(() => _region = v!) : null,
              decoration: const InputDecoration(
                labelText: '지역',
                labelStyle: TextStyle(fontSize: 24),
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 24),
            if (!_isEditing) ...[
              GestureDetector(
                onTap: _logout,
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 13,
                    color: seedColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _tryDelete,
                child: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isEditing ? _saveChanges : _tryEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: seedColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditing ? '저장하기' : '수정하기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
