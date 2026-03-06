import 'package:flutter/foundation.dart';
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

  User? get user => _user;
  List<Character> get characters => _characters;
  List<Message> get messages => _messages;
  Character? get currentCharacter => _currentCharacter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 注册/获取用户
    _user = await ApiService.register();
    if (_user == null) {
      _error = '用户初始化失败';
    }

    // 获取角色列表
    _characters = await ApiService.getCharacters();

    _isLoading = false;
    notifyListeners();
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

      await for (final event in ApiService.sendMessageStream(_currentCharacter!.id, content)) {
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
            _messages[aiMessageIndex] = Message(role: 'assistant', content: fullContent);
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

  // 清除对话历史
  Future<void> clearHistory() async {
    if (_currentCharacter == null) return;

    await ApiService.clearChatHistory(_currentCharacter!.id);
    _messages = [];
    notifyListeners();
  }

  // 兑换卡密
  Future<bool> redeemCard(String cardKey) async {
    final result = await ApiService.verifyCard(cardKey);
    if (result != null && result['success']) {
      await refreshUserInfo();
      return true;
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
