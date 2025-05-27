import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recycling_helper/providers/upload_result_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recycling_helper/models/favorite_chat.dart';


class ApiService {
  static const String baseUrl = 'http://158.179.174.13:8000';  // 서버 주소

  static Future<String?> login(String? username, String password) async {
    if (username == null) {
      print('❗ username이 null입니다. SharedPreferences에 저장되지 않았을 수 있습니다.');
      return null;
    }

    final url = Uri.parse('$baseUrl/api/login/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username); // 로그인 시 저장
      await prefs.setString('token', data['token']);
      return data['token'];
    } else {
      print('로그인 실패: ${response.body}');
      return null;
    }
  }
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String email,
    required String region,
  }) async {
    final url = Uri.parse('$baseUrl/api/register/');
    print('📤 보내는 데이터:');
    print('username: $username');
    print('password: $password');
    print('email: $email');
    print('current_location_id: $region');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "email": email,
        "current_location_id": region,
      }),
    );
    print('📤 전송 데이터: username=$username, password=$password, email=$email, current_location_id=$region');
    print('📤 JSON: ${response.body}');


    final data = jsonDecode(response.body);
    print('📡 응답 status: ${response.statusCode}');
    print('📦 응답 본문: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"success": true, "message": data["message"] ?? "회원가입 성공"};
    } else {
      return {"success": false, "message": data["message"] ?? "회원가입 실패"};
    }
  }

  static Future<Map<String, dynamic>?> uploadImage(WidgetRef ref, String imagePath) async {
    try {
      final uri = Uri.parse('$baseUrl/api/image/upload/');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('📂 전달된 이미지 경로: $imagePath');
      print('📂 파일 존재 여부: ${File(imagePath).existsSync()}');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      print('💻 실제 요청 URL: ${request.url}');
      print('🚀 서버로 요청 전송 시작');

      // ✅ 이 부분만 따로 try-catch!
      http.StreamedResponse response;
      try {
        response = await request.send();
      } catch (e) {
        print('❌ request.send() 실패: $e'); // ✅ 예외 로그 찍힘
        return null;
      }

      final resBody = await response.stream.bytesToString();
      print('📡 응답 status: ${response.statusCode}');
      print('📦 응답 body: ${resBody}');

      final data = jsonDecode(resBody);

      if (data.containsKey('embedding')) {
        print('🔎 추출된 임베딩 길이: ${data['embedding'].length}');
        print('🔎 일부 임베딩 값: ${data['embedding'].sublist(0, 5)}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 이미지 업로드 성공');
        print('🆔 이미지 ID: ${data['image_id']}');
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ 업로드 실패 (최상위): $e');
      return null;
    }
  }


  static Future<List<Map<String, dynamic>>> getVectors() async {
    final uri = Uri.parse('$baseUrl/api/vectors/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) =>
      Map<String, dynamic>.from(item)).toList();
    } else {
      print('❌ 벡터 목록 요청 실패: ${response.body}');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> queryPolicy({
    required String label,
    required int imageId,
    String query = "분리수거 방법 알려줘",
  }) async {
    final uri = Uri.parse('$baseUrl/api/policy/query/');  // ✅ 정확한 엔드포인트
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "label": label,
          "query": query,
          "image": imageId,
        }),
      );

      print('📡 정책 요청 status: ${response.statusCode}');
      print('📦 정책 응답 body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ 정책 요청 예외 발생: $e');
      return null;
    }
  }

  static Future<bool> uploadFeedback({
    required String message,
    required String type,
    required int? imageId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/feedback/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': imageId,
        'type': type,         // ✅ 올바르게 수정
        'message': message,   // ✅ 올바르게 수정
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ 오류 신고 성공: ${jsonDecode(response.body)['id']}');
      return true;
    } else {
      print('❌ 오류 신고 실패: ${response.body}');
      return false;
    }
  }

  // 신고 목록 불러오기
  static Future<List<Map<String, dynamic>>> fetchFeedbackList() async {
    try {
      final uri = Uri.parse('$baseUrl/api/feedback/');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data); // 리스트로 파싱
      } else {
        print('❌ 신고 목록 요청 실패: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserFeedbackList() async {
    try {
      final uri = Uri.parse('$baseUrl/api/feedback/');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ 피드백 목록 요청 실패: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/info/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<bool> updateUserInfo(String username, String region, String email, {String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      "username": username,
      "region": region,
      "email": email,
      if (password != null && password.isNotEmpty) "password": password,
    };

    print('📡 [PATCH] 사용자 정보 수정 요청 전송');
    print('🧾 요청 body: ${jsonEncode(body)}');

    final response = await http.patch(
      Uri.parse('$baseUrl/api/user/update/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    print('📡 응답 statusCode: ${response.statusCode}');
    print('📦 응답 body: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/user/delete/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return false;

    final token = await login(username, password);
    return token != null;
  }
  static Future<bool> toggleFavorite({
    required int chatId,
    required bool isAdding,
    int? favoriteId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = isAdding
        ? Uri.parse('$baseUrl/api/favorite-chat-action/')
        : Uri.parse('$baseUrl/api/favorite-chat-action/$favoriteId/'); // ✅ 고정된 삭제 URL
    print('📤 즐겨찾기 ${isAdding ? '추가' : '삭제'} 요청 URL: $uri');
    print('📤 chatId: $chatId');
    final response = await (isAdding
        ? http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"chat_id": chatId}),
    )
        : http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));
    print('📡 즐겨찾기 ${isAdding ? '추가' : '삭제'} 요청 status: ${response.statusCode}');
    print('📦 응답 body: ${response.body}');
    return response.statusCode >= 200 && response.statusCode < 300;
  }


  // 목록 조회
  static Future<List<FavoriteChat>> fetchFavoriteChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/favorite-chat/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('📦 즐겨찾기 목록 응답: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List data = jsonDecode(response.body);
      for (final item in data) {
        print('📄 즐겨찾기 항목: ${jsonEncode(item)}');
      }
      return data.map((e) => FavoriteChat.fromListJson(e)).toList();
    } else {
      print('❌ 목록 조회 실패: ${response.body}');
      return [];
    }
  }
// 상세 조회
  static Future<FavoriteChat?> fetchFavoriteChatDetail(int favoriteId) async {
    final uri = Uri.parse('$baseUrl/api/favorite-chat/$favoriteId/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('❌ 토큰이 없습니다. 로그인 필요');
      return null;
    }

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 [응답 status] ${response.statusCode}');
      print('📥 [응답 body] ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final favorite = data['favorite'];
        final reward = data['reward'];
        return FavoriteChat.fromJson(favorite, reward: reward); // ✅ reward 포함
      } else {
        return null;
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      return null;
    }
  }
  static Future<Map<String, dynamic>?> queryReward({
    required String label,
    required int chatId, // chatId가 필요한 구조라면 추가
  }) async {
    final uri = Uri.parse('$baseUrl/api/reward/query/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('🚀 [보상 요청 시작]');
    print('📤 요청 URL: $uri');
    print('📤 요청 데이터: label=$label, chat_Id=$chatId');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "label": label,
          "chat_id": chatId,  // chatId 전달
        }),
      );

      print('📡 응답 status: ${response.statusCode}');
      print('📦 응답 body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('✅ 파싱된 응답: $data');
        print('🔑 포함된 키: ${data.keys.toList()}'); // 어떤 key가 있는지 보기
        return data;
      } else {
        print('❗ 요청 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      return null;
    }
  }
}
