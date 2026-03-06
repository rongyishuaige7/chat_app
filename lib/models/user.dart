class User {
  final String deviceId;
  final int freeChats;
  final String? vipExpireTime;
  final bool isVip;

  User({
    required this.deviceId,
    required this.freeChats,
    this.vipExpireTime,
    required this.isVip,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      deviceId: json['device_id'] ?? '',
      freeChats: json['free_chats'] ?? 0,
      vipExpireTime: json['vip_expire_time'],
      isVip: json['is_vip'] ?? false,
    );
  }
}
