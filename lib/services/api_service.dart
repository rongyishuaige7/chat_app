import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/character.dart';
import '../models/user.dart';
import '../models/message.dart';
import 'dio_client.dart';

class ApiService {
  static final _dio = DioClient().dio;
  static const String imageBaseUrl = 'http://47.99.163.144:3000';

  // 注册用户
  static Future<User?> register() async {
    try {
      final response = await _dio.post('/user/register');
      if (response.statusCode == 200 && response.data['success']) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 获取用户信息
  static Future<User?> getUserInfo() async {
    try {
      final response = await _dio.get('/user/info');
      if (response.statusCode == 200 && response.data['success']) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 获取角色列表
  static Future<List<Character>> getCharacters() async {
    try {
      final response = await _dio.get('/characters');
      if (response.statusCode == 200 && response.data['success']) {
        return (response.data['data'] as List)
            .map((json) => Character.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 流式发送消息（使用 Dio ResponseType.stream）
  static Stream<Map<String, dynamic>> sendMessageStream(String characterId, String message) async* {
    try {
      final response = await _dio.post(
        '/chat/send/stream',
        data: {
          'character_id': characterId,
          'message': message,
        },
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (status) => true,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;

      if (response.statusCode != 200) {
        try {
          // 非 200 时，流里通常包含完整的错误 json
          final bodyBytes = await stream.reduce((a, b) => [...a, ...b]);
          final bodyString = utf8.decode(bodyBytes);
          final data = jsonDecode(bodyString);
          yield {'error': true, 'code': data['code'], 'message': data['message'] ?? '请求失败'};
        } catch (_) {
          yield {'error': true, 'code': 'ERROR', 'message': '与星域失去连接'};
        }
        return;
      }

      String buffer = '';
      
      await for (final chunk in stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          final dataStr = trimmed.substring(5).trim();
          if (dataStr.isEmpty) continue;

          try {
            final parsed = jsonDecode(dataStr) as Map<String, dynamic>;
            yield parsed;
          } catch (_) {}
        }
      }
    } on DioException catch (e) {
      yield {'error': true, 'message': '网络连接中断', 'code': e.response?.statusCode};
    } catch (e) {
      yield {'error': true, 'message': '遭遇星际风暴，请重试'};
    }
  }

  // 获取对话历史
  static Future<List<Message>> getChatHistory(String characterId) async {
    try {
      final response = await _dio.get('/chat/history/$characterId');
      if (response.statusCode == 200 && response.data['success']) {
        return (response.data['data'] as List)
            .map((json) => Message.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 清除对话历史
  static Future<bool> clearChatHistory(String characterId) async {
    try {
      final response = await _dio.delete('/chat/clear/$characterId');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 兑换卡密
  static Future<Map<String, dynamic>?> verifyCard(String cardKey) async {
    try {
      final response = await _dio.post('/card/verify', data: {'card_key': cardKey});
      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'],
          'message': data['message'],
          'vip_expire_time': data['data']?['vip_expire_time'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

