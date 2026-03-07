import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  User? _user;
  List<Character> _characters = [];
  List<Message> _messages = [];
  Character? _currentCharacter;
  bool _isLoading = false;
  String? _error;
  bool _hapticEnabled = true;

  User? get user => _user;
  List<Character> get characters => _characters;
  List<Message> get messages => _messages;
  Character? get currentCharacter => _currentCharacter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hapticEnabled => _hapticEnabled;

  // 初始化
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 加载偏好设置
    final prefs = await SharedPreferences.getInstance();
    _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;

    // 注册/获取用户
    _user = await ApiService.register();
    if (_user == null) {
      _error = '用户初始化失败';
    }

    // 获取角色列表
    _characters = await ApiService.getCharacters();

    _isLoading = false;
    notifyListeners();

    // 异步预热图片缓存，不阻塞 UI
    _precacheAvatars();
  }

  void _precacheAvatars() {
    for (var char in _characters) {
      if (char.avatarUrl.isNotEmpty) {
        final provider = CachedNetworkImageProvider(char.avatarUrl);
        provider
            .resolve(ImageConfiguration.empty)
            .addListener(
              ImageStreamListener(
                (_, __) {},
                onError: (e, stack) {
                  debugPrint('预加载图片失败: $e');
                },
              ),
            );
      }
    }
  }

  // 刷新用户信息
  Future<void> refreshUserInfo() async {
    _user = await ApiService.getUserInfo();
    notifyListeners();
  }

  // 选择角色
  Future<void> selectCharacter(Character character) async {
    _currentCharacter = character;
    _messages = await ApiService.getChatHistory(character.id);
    notifyListeners();
  }

  // 发送消息（流式）
  Future<String?> sendMessage(String content) async {
    if (_currentCharacter == null) return null;

    _isLoading = true;
    
    // 【核心修复】：UI 即时响应预扣费，避免等待流结束后才更新，导致用户认为没有扣费
    if (_user != null && !_user!.isVip && _user!.freeChats > 0) {
      _user = User(
        deviceId: _user!.deviceId,
        freeChats: _user!.freeChats - 1,
        vipExpireTime: _user!.vipExpireTime,
        isVip: _user!.isVip,
      );
    }
    
    notifyListeners();

    // 添加用户消息
    final userMessage = Message(role: 'user', content: content);
    _messages.add(userMessage);
    notifyListeners();

    // 添加一个占位的AI消息，后续流式填充
    _messages.add(Message(role: 'assistant', content: ''));
    final aiMessageIndex = _messages.length - 1; // 记录索引位置，而非对象引用
    notifyListeners();

    try {
      String fullContent = '';
      bool hasError = false;

      await for (final event in ApiService.sendMessageStream(
        _currentCharacter!.id,
        content,
      )) {
        if (event.containsKey('error') && event['error'] == true) {
          // 错误处理
          if (event['code'] == 'NO_CHATS') {
            // 移除占位AI消息和用户消息
            if (aiMessageIndex < _messages.length) {
              _messages.removeAt(aiMessageIndex);
            }
            _messages.remove(userMessage);
            _error = '免费次数已用完，请兑换VIP';
            hasError = true;
            break;
          } else {
            if (aiMessageIndex < _messages.length) {
              _messages.removeAt(aiMessageIndex);
            }
            _messages.remove(userMessage);
            _error = event['message'] ?? '网络请求失败，请稍后重试';
            hasError = true;
            break;
          }
        }

        if (event.containsKey('content')) {
          fullContent += event['content'] as String;
          // 用固定索引更新消息内容
          if (aiMessageIndex < _messages.length) {
            _messages[aiMessageIndex] = Message(
              role: 'assistant',
              content: fullContent,
            );
          }
          notifyListeners();
        }

        if (event.containsKey('done') && event['done'] == true) {
          // 流结束，更新剩余次数
          if (event['remaining_free_chats'] != null && _user != null) {
            _user = User(
              deviceId: _user!.deviceId,
              freeChats: event['remaining_free_chats'],
              vipExpireTime: _user!.vipExpireTime,
              isVip: _user!.isVip,
            );
          }
          // 刷新用户信息以获取最新的免费次数
          refreshUserInfo();
        }
      }

      _isLoading = false;
      notifyListeners();
      return hasError ? null : fullContent;
    } catch (e) {
      if (aiMessageIndex < _messages.length) {
        _messages.removeAt(aiMessageIndex);
      }
      _messages.remove(userMessage);
      _error = '网络请求失败，请稍后重试';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // 清除对话历史 (支持指定角色，若不传则清除当前角色)
  Future<bool> clearHistory([String? charId]) async {
    final targetId = charId ?? _currentCharacter?.id;
    if (targetId == null) return false;

    try {
      await ApiService.clearChatHistory(targetId);
      if (targetId == _currentCharacter?.id) {
        _messages = [];
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // 切换触觉反馈
  Future<void> toggleHapticFeedback(bool value) async {
    _hapticEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);
  }

  // 兑换卡密
  Future<Map<String, dynamic>?> redeemCard(String cardKey) async {
    final result = await ApiService.verifyCard(cardKey);
    if (result != null && result['success'] == true) {
      await refreshUserInfo();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
