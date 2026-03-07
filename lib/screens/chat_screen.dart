import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add HapticFeedback
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'dart:ui';
import '../models/character.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/animated_orb.dart';
import '../widgets/typing_indicator.dart';
import 'vip_screen.dart';

class ChatScreen extends StatefulWidget {
  final Character character;

  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty || !mounted) return;

    final provider = context.read<ChatProvider>();

    // 贴心优化1：直接在 UI 层进行星光余额检查，避免消息在发出前被清空 (保护用户输入的纯正心血)
    if (provider.user != null &&
        !provider.user!.isVip &&
        provider.user!.freeChats <= 0) {
      FocusScope.of(context).unfocus();
      _showVipDialog();
      return;
    }

    if (provider.hapticEnabled) {
      HapticFeedback.lightImpact(); // 轻触震动反馈
    }
    _controller.clear();
    FocusScope.of(context).unfocus(); // 自动收起键盘

    await provider.sendMessage(content);

    // 滚动到底部 (因为 reverse: true，所以 0.0 是最新消息)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 贴心优化2：如果后端异步拦截抛出了次数耗尽（双重保险）
    if (provider.error == '免费次数已用完，请兑换VIP') {
      _showVipDialog();
      provider.clearError();
    } else if (provider.error != null && mounted) {
      // 网络错误或其他异常的统一弹出反馈
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.redAccent.withAlpha(200),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      provider.clearError();
    }
  }

  void _showVipDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(150),
      builder: (context) => _buildGlassDialog(
        title: '星光微芒殆尽',
        content: '需要唤醒更多星辰秘钥，才能继续你们的旅途。',
        cancelText: '暂不',
        confirmText: '去唤醒',
        onConfirm: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VipScreen()),
          );
        },
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(60), // 更轻的遮罩，不遮挡聊天记录
      builder: (context) => _buildGlassDialog(
        title: '遗忘记忆',
        content: '确定要抹除与 ${widget.character.name} 之间的记忆吗？这些时光将消散于星海中。',
        cancelText: '取消',
        confirmText: '确定',
        onConfirm: () {
          context.read<ChatProvider>().clearHistory();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildGlassDialog({
    required String title,
    required String content,
    required String cancelText,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.3, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.white.withAlpha(60),
                  ],
                  stops: const [0.3, 1.0],
                ),
                border: Border.all(color: Colors.white.withAlpha(60)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(20),
                    blurRadius: 30,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.cyanAccent,
                    size: 36,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        autofocus: true,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withAlpha(20), // 简约毛玻璃底色
                          border: Border.all(color: Colors.white.withAlpha(80)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(25),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: onConfirm,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 高清壁纸背景放在最底层，不受系统键盘挤压
        Positioned.fill(
          child: Image.asset('assets/images/chat_bg.png', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withAlpha(160))),
        // 动态悬浮修饰光晕
        Positioned(
          top: 150,
          left: -60,
          child: AnimatedOrb(
            size: 200,
            color: Colors.purpleAccent.withAlpha(30),
            duration: const Duration(seconds: 5),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -80,
          child: AnimatedOrb(
            size: 250,
            color: Colors.cyanAccent.withAlpha(20),
            duration: const Duration(seconds: 7),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, // 必须透明以显示底层背景
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withAlpha(50),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'avatar_${widget.character.id}',
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.transparent,
                      backgroundImage: CachedNetworkImageProvider(
                        widget.character.avatarUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.character.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black.withAlpha(50),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white70),
            flexibleSpace: ClipRRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.transparent],
                        stops: [0.0, 1.0],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(50),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.white70,
                ),
                tooltip: '遗忘记忆',
                onPressed: _showClearHistoryDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 顶部垫高一块空间，并展示状态，或者由于用了 SafeArea 可以不用填空
                // 用户状态栏
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    final user = provider.user;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                        ), // 更亮的边框
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha(30), // 外发光晕
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user?.isVip == true
                                ? '✨ 你的极光已常驻'
                                : '⭐ 剩余星光微芒: ${user?.freeChats ?? 0}',
                            style: TextStyle(
                              color: user?.isVip == true
                                  ? Colors.cyanAccent
                                  : Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                          if (user?.isVip != true)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VipScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '点亮',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // 消息列表
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      final messages = provider.messages;

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withAlpha(50),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: CachedNetworkImageProvider(
                                    widget.character.avatarUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '夜深了...\n让 ${widget.character.name} 陪你坐一会儿。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  height: 1.6,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // 反转列表模式：最新消息永远位于底部
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // 读取倒序数组，让最新消息是 index = 0
                          final message = messages[messages.length - 1 - index];
                          return _MessageBubble(
                            message: message.content,
                            isUser: message.isUser,
                            avatar: message.isUser
                                ? null
                                : widget.character.avatarUrl,
                          );
                        },
                      );
                    },
                  ),
                ),
                // 输入框
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white24],
                            stops: [0.0, 1.0],
                          ).createShader(bounds),
                          blendMode: BlendMode.dstIn,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: MediaQuery.of(context).padding.bottom > 0
                              ? MediaQuery.of(context).padding.bottom + 8
                              : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withAlpha(40),
                              Colors.black.withAlpha(70),
                            ],
                            stops: const [0.0, 0.4],
                          ),
                          border: const Border(
                            top: BorderSide(
                              color: Colors.transparent,
                              width: 0.0,
                            ), // 移除小白线
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(20), // 顶部泛出一点白光
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20), // 内部毛玻璃层
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(50),
                                    width: 1,
                                  ), // 高光白边
                                ),
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '写下你的心事...',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                  ),
                                  maxLines: 4,
                                  minLines: 1,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Consumer<ChatProvider>(
                              builder: (context, provider, child) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(
                                      30,
                                    ), // 更亮的发送按钮底色
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withAlpha(100),
                                      width: 1.2,
                                    ), // 强光边缘
                                    boxShadow: provider.isLoading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.white.withAlpha(
                                                80,
                                              ), // 明显的白色光晕
                                              blurRadius: 25,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                  ),
                                  child: IconButton(
                                    icon: provider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 20,
                                          ),
                                    color: Colors.white,
                                    onPressed: provider.isLoading
                                        ? null
                                        : _sendMessage,
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
              ],
            ),
          ),
        ), // End Scaffold
      ],
    ); // End Stack
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? avatar;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && avatar != null) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withAlpha(50),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(avatar!),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: Border.all(
                color: isUser
                    ? Colors.deepPurpleAccent.withAlpha(80)
                    : Colors.white.withAlpha(120), // 区分用户与AI气泡的边缘光
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? Colors.deepPurpleAccent.withAlpha(30)
                      : Colors.white.withAlpha(40), // 区分氛围光
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(70)),
                  child: isUser
                      ? Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                            letterSpacing: 0.5,
                          ),
                        )
                      : (message.isEmpty
                            ? const TypingIndicator()
                            : _buildImmersiveMessage(message)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建沉浸式消息（支持行内混合：自动解析「动作」和 *独白*）
  Widget _buildImmersiveMessage(String msg) {
    if (msg.isEmpty) return const SizedBox.shrink();

    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'(「.*?」|\*.*?\*)');

    msg.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        final text = match[0]!;
        if (text.startsWith('「') && text.endsWith('」')) {
          spans.add(
            TextSpan(
              text: text,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          );
        } else if (text.startsWith('*') && text.endsWith('*')) {
          spans.add(
            TextSpan(
              text: text.substring(1, text.length - 1),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          );
        }
        return '';
      },
      onNonMatch: (String text) {
        spans.add(
          TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        );
        return '';
      },
    );

    return RichText(text: TextSpan(children: spans));
  }
}
