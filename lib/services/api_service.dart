import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/character.dart';
import '../models/user.dart';
import '../models/message.dart';

class ApiService {
  // 修改为你的服务器IP
  static const String baseUrl = 'http://192.168.1.23:3002/api';
  static const String imageBaseUrl = 'http://192.168.1.23:3002';

  static String? _deviceId;

  // 获取设备ID
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');

    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('device_id', _deviceId!);
    }

    return _deviceId!;
  }

  // 注册用户
  static Future<User?> register() async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('注册错误: $e');
      return null;
    }
  }

  // 获取用户信息
  static Future<User?> getUserInfo() async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/user/info?device_id=$deviceId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('获取用户信息错误: $e');
      return null;
    }
  }

  // 获取角色列表
  static Future<List<Character>> getCharacters() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/characters'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((json) => Character.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取角色列表错误: $e');
      return [];
    }
  }

  // 发送消息（非流式）
  static Future<Map<String, dynamic>?> sendMessage(String characterId, String message) async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'character_id': characterId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'message': data['data']?['message'] ?? '',
          'remaining_free_chats': data['data']?['remaining_free_chats'],
          'code': data['code'],
        };
      }
      return null;
    } catch (e) {
      print('发送消息错误: $e');
      return null;
    }
  }

  // 发送消息（流式SSE）
  static Stream<Map<String, dynamic>> sendMessageStream(String characterId, String message) async* {
    try {
      final deviceId = await getDeviceId();
      final request = http.Request('POST', Uri.parse('$baseUrl/chat/send/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'device_id': deviceId,
        'character_id': characterId,
        'message': message,
      });

      final client = http.Client();
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        // 非200状态码，尝试读取body来获取错误信息
        final body = await streamedResponse.stream.bytesToString();
        try {
          final data = jsonDecode(body);
          yield {'error': true, 'code': data['code'], 'message': data['message'] ?? '请求失败'};
        } catch (_) {
          yield {'error': true, 'message': '请求失败'};
        }
        client.close();
        return;
      }

      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // 保留最后一个可能不完整的行

        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          final dataStr = trimmed.substring(5).trim();
          if (dataStr.isEmpty) continue;

          try {
            final parsed = jsonDecode(dataStr) as Map<String, dynamic>;
            yield parsed;
          } catch (_) {
            // 忽略解析错误
          }
        }
      }

      client.close();
    } catch (e) {
      print('流式发送消息错误: $e');
      yield {'error': true, 'message': '网络请求失败'};
    }
  }

  // 获取对话历史
  static Future<List<Message>> getChatHistory(String characterId) async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/$characterId?device_id=$deviceId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((json) => Message.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取对话历史错误: $e');
      return [];
    }
  }

  // 清除对话历史
  static Future<bool> clearChatHistory(String characterId) async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/clear/$characterId?device_id=$deviceId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('清除对话历史错误: $e');
      return false;
    }
  }

  // 兑换卡密
  static Future<Map<String, dynamic>?> verifyCard(String cardKey) async {
    try {
      final deviceId = await getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/card/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_key': cardKey,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'],
          'message': data['message'],
          'vip_expire_time': data['data']?['vip_expire_time'],
        };
      }
      return null;
    } catch (e) {
      print('兑换卡密错误: $e');
      return null;
    }
  }
}
