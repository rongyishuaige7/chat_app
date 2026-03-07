import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/character.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/animated_orb.dart';

import 'chat_screen.dart';
import 'vip_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化自开启动画的控制器，打造无缝柔和入场
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.stars, color: Colors.amberAccent),
          tooltip: '会员中心',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VipScreen()),
            );
          },
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Lumina 夜岛',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white70,
            ),
            tooltip: '星穹档案 (设置)',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ProfileScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 高清壁纸背景
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          // 深色遮罩避免背景过于抢夺视线
          Positioned.fill(child: Container(color: Colors.black.withAlpha(80))),
          // 动态呼吸发光球体修饰
          Positioned(
            top: -50,
            left: -50,
            child: AnimatedOrb(
              size: 250,
              color: Colors.deepPurpleAccent.withAlpha(40),
              duration: const Duration(seconds: 4),
            ),
          ),
          Positioned(
            top: 150,
            right: -100,
            child: AnimatedOrb(
              size: 300,
              color: Colors.cyanAccent.withAlpha(20),
              duration: const Duration(seconds: 6),
            ),
          ),
          // 主内容 (附加渐亮入场过渡)
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.characters.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurpleAccent,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户状态毛玻璃卡片
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(2), // 为边框留出空间
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withAlpha(50),
                              Colors.white.withAlpha(10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.2,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white,
                                        ],
                                        stops: [0.3, 1.0],
                                      ).createShader(bounds),
                                  blendMode: BlendMode.dstIn,
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 25,
                                      sigmaY: 25,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: provider.user?.isVip == true
                                      ? 6
                                      : 20,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.2,
                                    colors: [
                                      Colors.black.withAlpha(70),
                                      Colors.white.withAlpha(50),
                                    ],
                                    stops: const [0.3, 1.0],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      provider.user?.isVip == true
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.spaceAround,
                                  children: [
                                    if (provider.user?.isVip != true) ...[
                                      Column(
                                        children: [
                                          const Text(
                                            '心意星光',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${provider.user?.freeChats ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.white24,
                                      ),
                                    ],
                                    Column(
                                      children: [
                                        if (provider.user?.isVip != true)
                                          const Text(
                                            '灵魂印记',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        if (provider.user?.isVip != true)
                                          const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              provider.user?.isVip == true
                                                  ? Icons.auto_awesome
                                                  : Icons.brightness_3,
                                              color:
                                                  provider.user?.isVip == true
                                                  ? Colors.amberAccent
                                                  : Colors.white70,
                                              size: provider.user?.isVip == true
                                                  ? 20
                                                  : 18, // 缩小VIP图标
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              provider.user?.isVip == true
                                                  ? '极光旅者'
                                                  : '微光引路人',
                                              style: TextStyle(
                                                fontSize:
                                                    provider.user?.isVip == true
                                                    ? 16
                                                    : 16, // VIP文字调小
                                                fontWeight: FontWeight
                                                    .bold, // 不用w900使其扁一点、轻一点
                                                letterSpacing:
                                                    provider.user?.isVip == true
                                                    ? 4
                                                    : 0, // 拉宽间距显得更扁平
                                                color:
                                                    provider.user?.isVip == true
                                                    ? Colors.amberAccent
                                                    : Colors.white70,
                                                height: 1.0, // 减少行高
                                                shadows:
                                                    provider.user?.isVip == true
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors
                                                              .amberAccent
                                                              .withAlpha(50),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (provider.user?.isVip != true)
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const VipScreen(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withAlpha(30),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withAlpha(50),
                                            ),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          '点亮星空',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (provider.user?.isVip != true)
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            top: 20,
                            bottom: 8,
                          ),
                          child: Text(
                            '选择伴随着你的微光...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: provider.characters.length,
                          itemBuilder: (context, index) {
                            final character = provider.characters[index];
                            return _CharacterCard(
                              character: character,
                              onTap: () => _enterChat(character),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enterChat(Character character) {
    context.read<ChatProvider>().selectCharacter(character);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(character: character)),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const _CharacterCard({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
          gradient: LinearGradient(
            colors: [Colors.white.withAlpha(20), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.3, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.black.withAlpha(70),
                      Colors.white.withAlpha(150),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withAlpha(50),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'avatar_${character.id}',
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.transparent,
                          backgroundImage: CachedNetworkImageProvider(
                            character.avatarUrl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        character.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(180),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
