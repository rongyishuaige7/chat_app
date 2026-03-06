import '../services/api_service.dart';

class Character {
  final String id;
  final String name;
  final String avatar;
  final String description;
  final String systemPrompt;

  Character({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    required this.systemPrompt,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      description: json['description'] ?? '',
      systemPrompt: json['system_prompt'] ?? '',
    );
  }

  // 获取完整头像URL
  String get avatarUrl {
    if (avatar.startsWith('http')) {
      return avatar;
    }
    return '${ApiService.imageBaseUrl}$avatar';
  }
}
