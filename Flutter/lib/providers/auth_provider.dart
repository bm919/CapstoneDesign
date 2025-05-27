import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final authProvider =
StateNotifierProvider<AuthNotifier, String?>((ref) => AuthNotifier());

class AuthResult {
  final bool success;
  final String? message;

  AuthResult({required this.success, this.message});
}

class AuthNotifier extends StateNotifier<String?> {
  AuthNotifier() : super(null) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      state = token;
    } else {
      state = null;
    }
  }

  Future<AuthResult> login(String username, String password) async {
    print("------------------로그인 함수 호출 직전---------------");
    final url = Uri.parse('http://158.179.174.13:8000/api/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('🔍 statusCode: ${response.statusCode}');
      print('🔍 response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final token = data['access'];

          if (token != null && token is String) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            state = token;
            return AuthResult(success: true);
          } else {
            return AuthResult(success: false, message: '서버 응답에 토큰이 없습니다.');
          }
        } catch (e) {
          return AuthResult(success: false, message: '응답 파싱 오류: ${e.toString()}');
        }
      } else {
        return AuthResult(success: false, message: '로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      return AuthResult(success: false, message: '요청 예외 발생: $e');
    }
    print("---------------로그인 함수 호출 끝------------");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = null;
  }

  Future<AuthResult> signup(String username, String password, String email, String region) async {
    final url = Uri.parse('http://158.179.174.13:8000/api/register/');
    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'region': region,
        }),
      );
      print('🔴 응답 status: ${response.statusCode}');
      print('🔴 응답 본문: ${response.body}');


      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['access'] ?? data['token'];
        print('🧪 서버에서 받은 토큰: $token');

        if (token != null && token is String) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          state = token;
          return AuthResult(success: true, message: data['message'] ?? '회원가입 및 로그인 성공');
        } else {
          return AuthResult(success: true, message: data['message'] ?? '회원가입 성공 (토큰 없음)');
        }
      } else {
        return AuthResult(success: false, message: data['message'] ?? data['detail'] ?? '회원가입 실패');
      }
    } catch (e) {
      //print('❗ JSON 파싱 실패. 서버 응답 본문:\n${response.body}');
      return AuthResult(success: false, message: '서버에서 유효한 JSON을 반환하지 않았습니다.');
    }
  }

}
