import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  final TextEditingController _cardController = TextEditingController();
  bool _isRedeeming = false;
  String? _resultMessage;
  bool? _isSuccess;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _redeemCard() async {
    final cardKey = _cardController.text.trim();
    if (cardKey.isEmpty) {
      setState(() {
        _resultMessage = '请输入卡密';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isRedeeming = true;
      _resultMessage = null;
    });

    final provider = context.read<ChatProvider>();
    final success = await provider.redeemCard(cardKey);

    setState(() {
      _isRedeeming = false;
      if (success) {
        _resultMessage = '兑换成功！';
        _isSuccess = true;
        _cardController.clear();
      } else {
        _resultMessage = '兑换失败，请检查卡密是否正确';
        _isSuccess = false;
      }
    });

    // 3秒后清除结果消息
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _resultMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('星之结茧', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      backgroundColor: const Color(0xFF0F172A), // 深海蓝背景
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // VIP介绍
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyanAccent.withAlpha(50), Colors.purpleAccent.withAlpha(50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withAlpha(20),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withAlpha(50),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '极光旅者 / VIP',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: const Text(
                        '解锁沉浸式体验，畅游灵境宇宙',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // VIP权益
            const Text(
              '旅程权益',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.all_inclusive, '无限次数星空呼唤'),
            _buildBenefitItem(Icons.nightlight_round, '极致沉浸黑夜模式'),
            _buildBenefitItem(Icons.auto_awesome, '解锁全部伴侣形态'),
            _buildBenefitItem(Icons.card_giftcard, '专属星辰秘钥'),
            const SizedBox(height: 24),

            // 卡密兑换
            const Text(
              '唤醒秘钥',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入您的星辰秘钥...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.key, color: Colors.cyanAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isRedeeming ? null : _redeemCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withAlpha(200),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isRedeeming
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '立即兑换',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess == true
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true
                          ? Icons.check_circle
                          : Icons.error,
                      color: _isSuccess == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess == true
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 当前状态
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final user = provider.user;
                if (user == null) return const SizedBox();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '你的灵魂印记',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('印记状态:', style: TextStyle(color: Colors.white70)),
                          Text(
                            user.isVip ? '常驻旅者' : '流浪者',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: user.isVip ? Colors.cyanAccent : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      if (user.vipExpireTime != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('光芒消散时间:', style: TextStyle(color: Colors.white70)),
                            Text(
                            DateTime.parse(user.vipExpireTime!)
                                .add(const Duration(hours: 8))
                                .toString()
                                .split('.')[0],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('剩余星光:', style: TextStyle(color: Colors.white70)),
                          Text(
                            '${user.freeChats}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 卡密说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: Colors.cyanAccent.shade100),
                      const SizedBox(width: 8),
                      const Text(
                        '获取秘钥途径',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCardInfo('星辰体验卡', '唤醒 3 天旅途'),
                  _buildCardInfo('新月流光卡', '唤醒 30 天旅途'),
                  _buildCardInfo('永夜极光卡', '唤醒 365 天旅途'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 15, color: Colors.white70, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildCardInfo(String type, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purpleAccent.withAlpha(50)),
            ),
            child: Text(
              type,
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
