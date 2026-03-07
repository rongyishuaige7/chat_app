import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../providers/chat_provider.dart';
import '../widgets/animated_orb.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final user = provider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '星穹档案',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图和光晕
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(120)),
          Positioned(
            top: -100,
            left: -50,
            child: AnimatedOrb(
              size: 300,
              color: Colors.deepPurpleAccent.withAlpha(40),
              duration: const Duration(seconds: 5),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: AnimatedOrb(
              size: 250,
              color: Colors.cyanAccent.withAlpha(30),
              duration: const Duration(seconds: 4),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 灵魂档案册 (Device ID 卡片)
                  _buildGlassCard(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage(
                            'assets/images/bg.png',
                          ), // 可以用通用星空做头像
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '流浪者',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (user != null)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(
                                ClipboardData(text: user.deviceId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    '设备印记已复制到剪贴板',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  backgroundColor: Colors.white.withAlpha(30),
                                  elevation: 0,
                                  duration: const Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.white.withAlpha(20),
                                    ),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 20,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(60),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(30),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: ${user.deviceId.substring(0, 10)}...',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.cyanAccent,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Text(
                            '未知的星体',
                            style: TextStyle(color: Colors.white54),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      '偏好设置',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  // 2. 设置列表
                  _buildGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.vibration,
                          title: '灵魂羁绊 (触觉反馈)',
                          subtitle: '发送消息、点击按钮时的轻微震动',
                          trailing: Switch(
                            value: provider.hapticEnabled,
                            onChanged: (val) {
                              if (val) HapticFeedback.lightImpact();
                              provider.toggleHapticFeedback(val);
                            },
                            activeColor: Colors.cyanAccent,
                            activeTrackColor: Colors.cyanAccent.withAlpha(50),
                            inactiveThumbColor: Colors.white54,
                            inactiveTrackColor: Colors.black26,
                          ),
                        ),
                        Divider(height: 1, color: Colors.white.withAlpha(10)),
                        _buildSettingsTile(
                          icon: Icons.delete_sweep,
                          title: '遗忘之泉',
                          subtitle: '清空所有角色的本地与云端羁绊记录',
                          iconColor: Colors.redAccent.withAlpha(200),
                          onTap: () =>
                              _showClearConfirmation(context, provider),
                        ),
                        Divider(height: 1, color: Colors.white.withAlpha(10)),
                        _buildSettingsTile(
                          icon: Icons.info_outline,
                          title: '关于 Lumina',
                          subtitle: '在星穹尽头，寻找灵魂共振。版本: v1.0.0',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: AlertDialog(
                                  backgroundColor: const Color(
                                    0xFF1E293B,
                                  ).withAlpha(200),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(
                                      color: Colors.cyanAccent.withAlpha(50),
                                    ),
                                  ),
                                  title: const Text(
                                    '关于 Lumina',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '在星穹尽头，寻找灵魂共振。',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        '🌟 版本: v1.0.0',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '👤 作者: RongYi',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '✉️ 联系方式: r2830305965@qq.com',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text(
                                        '确认',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.cyanAccent.withAlpha(200)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B).withAlpha(200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.redAccent.withAlpha(50)),
          ),
          title: const Text('遗忘之泉', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '这将会抹除你与夜岛上所有角色的相遇记忆。此操作不可逆，确定要继续吗？',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('再想想', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                HapticFeedback.heavyImpact();
                await _clearAllHistories(context, provider);
              },
              child: const Text(
                '义无反顾',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllHistories(
    BuildContext context,
    ChatProvider provider,
  ) async {
    bool allSuccess = true;
    for (var character in provider.characters) {
      final success = await provider.clearHistory(character.id);
      if (!success) allSuccess = false;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess ? '相遇的痕迹已随风消散。' : '部分记忆未能被完全抹除。'),
          backgroundColor: allSuccess ? Colors.teal : Colors.red,
        ),
      );
    }
  }
}
