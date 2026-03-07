import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/animated_orb.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    // 提前把背景大图加载进内存，防止下个页面第一次渲染时的掉帧
    // 使用 addPostFrameCallback 确保 context 已经准备好，修复红屏报错
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/bg.png'), context);
    });

    // 进入全屏沉浸模式，隐藏系统状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 渐显动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    // 轻微放大，产生一种向宇宙深处推进的视觉
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // 背景从模糊到清晰的渐变
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // 动画放完后，稍微停留一会儿，自动通过淡出动画切换到首页
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        // 先推入路由，再慢慢恢复状态栏，避免上方突然塌陷
        Navigator.of(context).pushReplacement(_createFadeRoute()).then((_) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
      }
    });
  }

  // 自定义的页面切换路由：长达1秒的全局淡入淡出（完美无缝衔接，使用 easeOut 曲线柔和淡入）
  Route _createFadeRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const HomeScreen(),
      transitionDuration: const Duration(milliseconds: 1600),
      reverseTransitionDuration: const Duration(milliseconds: 1600),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(opacity: animation.drive(tween), child: child);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 纯黑底色防透
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 底层背景底图与轻微缩放
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Image.asset(
                  'assets/images/bg.png', // 直接复用深色星空壁纸
                  fit: BoxFit.cover,
                ),
              );
            },
          ),

          // 2. 动态毛玻璃模糊效果，产生“拨开云雾”的感觉
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, child) {
              if (_blurAnimation.value == 0) return const SizedBox();
              return BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(color: Colors.transparent),
              );
            },
          ),

          // 3. 常规的调光遮罩，以免背景太抢戏
          Container(color: Colors.black.withAlpha(120)),

          // 4. 深海灵力光晕，与首页形成设计语言统一
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: -80,
            child: AnimatedOrb(
              size: 350,
              color: Colors.deepPurpleAccent.withAlpha(50),
              duration: const Duration(seconds: 4),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            right: -100,
            child: AnimatedOrb(
              size: 400,
              color: Colors.cyanAccent.withAlpha(30),
              duration: const Duration(seconds: 6),
            ),
          ),

          // 5. 核心 Logo 和 Slogan 区域的显影
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withAlpha(40),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App 主名 - 流光渐变色
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Colors.cyanAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Lumina 夜岛',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App 诗意 Slogan
                  Text(
                    '在星穹尽头，寻找灵魂共振。',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withAlpha(160),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
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
}
