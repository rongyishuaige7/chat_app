import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'Lumina 夜岛',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            background: const Color(0xFF0F172A), // 深海蓝/午夜蓝
            surface: const Color(0xFF1E293B),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          useMaterial3: true,
          fontFamily: 'sans-serif', // 可以的话，后续引入圆润一些的字体
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
