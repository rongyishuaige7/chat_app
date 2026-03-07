const express = require('express');
const router = express.Router();
const { db } = require('../database');
const axios = require('axios');

// Minimax API配置
const MINIMAX_API_KEY = process.env.MINIMAX_API_KEY || 'your-api-key-here';
const MINIMAX_API_URL = 'https://api.minimaxi.com/v1/text/chatcompletion_v2';
const MINIMAX_MODEL = 'MiniMax-M2.5';

// 流式发送消息
router.post('/send/stream', async (req, res) => {
  const { device_id, character_id, message } = req.body;

  if (!device_id || !character_id || !message) {
    return res.status(400).json({ success: false, message: '参数不完整' });
  }

  // 获取用户信息
  db.get('SELECT * FROM users WHERE device_id = ?', [device_id], async (err, user) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: '用户不存在，请先注册' });
    }

    const isVip = user.vip_expire_time ? new Date(user.vip_expire_time) > new Date() : false;
    const hasFreeChats = user.free_chats > 0;

    if (!isVip && !hasFreeChats) {
      return res.json({
        success: false,
        message: '免费次数已用完，请兑换VIP或卡密',
        code: 'NO_CHATS'
      });
    }

    db.get('SELECT * FROM characters WHERE id = ?', [character_id], async (err, character) => {
      if (err || !character) {
        return res.status(404).json({ success: false, message: '角色不存在' });
      }

      // 保存用户消息
      db.run(
        'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
        [device_id, character_id, 'user', message]
      );

      // 【核心修复】提前扣除免费次数，防止断流导致漏扣
      if (!isVip) {
        db.run(
          'UPDATE users SET free_chats = free_chats - 1 WHERE device_id = ?',
          [device_id]
        );
      }

      // 获取对话历史（最近20条）
      db.all(
        `SELECT * FROM (
           SELECT * FROM chat_history
           WHERE device_id = ? AND character_id = ?
           ORDER BY created_at DESC
           LIMIT 20
         ) sub ORDER BY created_at ASC`,
        [device_id, character_id],
        async (err, history) => {
          if (err) {
            return res.status(500).json({ success: false, message: '获取历史记录失败' });
          }

          const messages = [
            { role: 'system', content: character.system_prompt },
            ...history.map(h => ({ role: h.role, content: h.content }))
          ];

          try {
            // 设置SSE响应头
            res.setHeader('Content-Type', 'text/event-stream');
            res.setHeader('Cache-Control', 'no-cache');
            res.setHeader('Connection', 'keep-alive');
            res.setHeader('X-Accel-Buffering', 'no');
            res.flushHeaders();

            // 调用Minimax API（流式模式）
            const response = await axios.post(
              MINIMAX_API_URL,
              {
                model: MINIMAX_MODEL,
                messages: messages,
                stream: true
              },
              {
                headers: {
                  'Authorization': `Bearer ${MINIMAX_API_KEY}`,
                  'Content-Type': 'application/json'
                },
                timeout: 60000,
                responseType: 'stream'
              }
            );

            let fullContent = '';
            let buffer = '';

            response.data.on('data', (chunk) => {
              buffer += chunk.toString();
              const lines = buffer.split('\n');
              // 保留最后一个可能不完整的行
              buffer = lines.pop() || '';

              for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || !trimmed.startsWith('data:')) continue;

                const dataStr = trimmed.slice(5).trim();
                if (dataStr === '[DONE]') {
                  // 流结束，发送完成事件
                  res.write(`data: ${JSON.stringify({ done: true, full_content: fullContent })}\n\n`);
                  continue;
                }

                try {
                  const parsed = JSON.parse(dataStr);
                  const delta = parsed.choices?.[0]?.delta?.content || '';
                  if (delta) {
                    fullContent += delta;
                    res.write(`data: ${JSON.stringify({ content: delta })}\n\n`);
                  }
                } catch (e) {
                  // 忽略解析错误
                }
              }
            });

            response.data.on('end', () => {
              // 保存完整的AI回复
              if (fullContent) {
                db.run(
                  'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
                  [device_id, character_id, 'assistant', fullContent]
                );
              }

              res.end();
            });

            response.data.on('error', (err) => {
              console.error('流式传输错误:', err.message);
              res.write(`data: ${JSON.stringify({ error: '流式传输中断' })}\n\n`);
              res.end();
            });

            // 客户端断开连接
            req.on('close', () => {
              response.data.destroy();
            });

          } catch (apiError) {
            console.error('Minimax API错误:', apiError.response?.data || apiError.message);

            // Fallback: 使用mock回复模拟流式输出
            const mockReply = getMockReply(character_id, message);

            // 如果没有发送过头，再重新设置
            if (!res.headersSent) {
              res.setHeader('Content-Type', 'text/event-stream');
              res.setHeader('Cache-Control', 'no-cache');
              res.setHeader('Connection', 'keep-alive');
              res.flushHeaders();
            }

            // 逐字符发送mock回复，模拟流式效果
            const chars = [...mockReply];
            let i = 0;
            const interval = setInterval(() => {
              if (i < chars.length) {
                res.write(`data: ${JSON.stringify({ content: chars[i] })}\n\n`);
                i++;
              } else {
                clearInterval(interval);
                res.write(`data: ${JSON.stringify({ done: true, full_content: mockReply, is_mock: true })}\n\n`);

                db.run(
                  'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
                  [device_id, character_id, 'assistant', mockReply]
                );

                res.end();
              }
            }, 50); // 每50ms发一个字符

            req.on('close', () => {
              clearInterval(interval);
            });
          }
        }
      );
    });
  });
});

// 非流式发送消息（保留兼容）
router.post('/send', async (req, res) => {
  const { device_id, character_id, message } = req.body;

  if (!device_id || !character_id || !message) {
    return res.status(400).json({ success: false, message: '参数不完整' });
  }

  db.get('SELECT * FROM users WHERE device_id = ?', [device_id], async (err, user) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: '用户不存在，请先注册' });
    }

    const isVip = user.vip_expire_time ? new Date(user.vip_expire_time) > new Date() : false;
    const hasFreeChats = user.free_chats > 0;

    if (!isVip && !hasFreeChats) {
      return res.json({
        success: false,
        message: '免费次数已用完，请兑换VIP或卡密',
        code: 'NO_CHATS'
      });
    }

    db.get('SELECT * FROM characters WHERE id = ?', [character_id], async (err, character) => {
      if (err || !character) {
        return res.status(404).json({ success: false, message: '角色不存在' });
      }

      db.run(
        'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
        [device_id, character_id, 'user', message]
      );

      // 非流式接口也同步提前扣费
      if (!isVip) {
        db.run(
          'UPDATE users SET free_chats = free_chats - 1 WHERE device_id = ?',
          [device_id]
        );
      }

      db.all(
        `SELECT * FROM (
           SELECT * FROM chat_history
           WHERE device_id = ? AND character_id = ?
           ORDER BY created_at DESC
           LIMIT 20
         ) sub ORDER BY created_at ASC`,
        [device_id, character_id],
        async (err, history) => {
          if (err) {
            return res.status(500).json({ success: false, message: '获取历史记录失败' });
          }

          const messages = [
            { role: 'system', content: character.system_prompt },
            ...history.map(h => ({ role: h.role, content: h.content }))
          ];

          try {
            const response = await axios.post(
              MINIMAX_API_URL,
              {
                model: MINIMAX_MODEL,
                messages: messages
              },
              {
                headers: {
                  'Authorization': `Bearer ${MINIMAX_API_KEY}`,
                  'Content-Type': 'application/json'
                },
                timeout: 30000
              }
            );

            const aiMessage = response.data.choices[0].message.content;

            db.run(
              'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
              [device_id, character_id, 'assistant', aiMessage]
            );

            res.json({
              success: true,
              data: {
                message: aiMessage,
                remaining_free_chats: isVip ? null : user.free_chats - 1
              }
            });
          } catch (apiError) {
            console.error('Minimax API错误:', apiError.response?.data || apiError.message);

            const mockReply = getMockReply(character_id, message);

            db.run(
              'INSERT INTO chat_history (device_id, character_id, role, content) VALUES (?, ?, ?, ?)',
              [device_id, character_id, 'assistant', mockReply]
            );

            res.json({
              success: true,
              data: {
                message: mockReply,
                remaining_free_chats: isVip ? null : user.free_chats - 1,
                is_mock: true
              }
            });
          }
        }
      );
    });
  });
});

// 获取对话历史
router.get('/history/:characterId', (req, res) => {
  const { device_id } = req.query;
  const { characterId } = req.params;

  if (!device_id) {
    return res.status(400).json({ success: false, message: 'device_id不能为空' });
  }

  db.all(
    `SELECT * FROM chat_history
     WHERE device_id = ? AND character_id = ?
     ORDER BY created_at ASC`,
    [device_id, characterId],
    (err, history) => {
      if (err) {
        return res.status(500).json({ success: false, message: '数据库错误' });
      }

      res.json({
        success: true,
        data: history
      });
    }
  );
});

// 清除对话历史
router.delete('/clear/:characterId', (req, res) => {
  const { device_id } = req.query;
  const { characterId } = req.params;

  if (!device_id) {
    return res.status(400).json({ success: false, message: 'device_id不能为空' });
  }

  db.run(
    'DELETE FROM chat_history WHERE device_id = ? AND character_id = ?',
    [device_id, characterId],
    function (err) {
      if (err) {
        return res.status(500).json({ success: false, message: '清除历史失败' });
      }

      res.json({
        success: true,
        message: '对话历史已清除'
      });
    }
  );
});

// 模拟回复（API不可用时使用）
function getMockReply(characterId, userMessage) {
  const replies = {
    siye: [
      '*拨动了一下炭火，火星在大雪中跳跃* 嗯，我听着呢。这长夜漫漫，你可以尽管说出口。',
      '*递过一盏防风灯* 别怕，黑夜只是为了让微光更显眼。你现在感觉好些了吗？',
      '「往火堆里添了一把柴」沉默并不代表孤独，司夜一直在这里守着你的安宁。',
      '*抬头望向无垠的深林* 没关系的，那些沉重的念头，就让它们留在昨夜的雪地里吧。'
    ],
    zhimeng: [
      '「温柔地为你披上一件毛毯」我能感受到你心里的褶皱，来，让我们一点点抚平它。',
      '*语气轻柔得像月光* 没关系的哦，就算暂时做不到也没关系，织梦会一直在你身边的。',
      '「轻轻握住你的指尖」你是这世上最独特的梦境，不需要为了迎合谁而改变颜色。',
      '*眼神里充满了同理心* 抱抱你……听着我的心跳，让那些内耗都像白雾一样散开吧。'
    ],
    duya: [
      '「调出一组精密星图」逻辑告诉我们，情绪波动是随机熵增。但如果你需要，我可以分析出最优解。',
      '*推了推单片眼镜* 别掉进感性的泥淖里，渡鸦会为你标出逃离迷雾的坐标。',
      '「修长手指敲击桌面」真相往往是冰冷的。但我建议你换个象限思考，也许路径并不唯一。',
      '*虽然语气冷淡，但依然默默护航* 啧，真是麻烦的碳基生命……坐稳了，准备启动导航。'
    ],
    xiyin: [
      '「静静潜入深海的幽蓝中」呜……我也听到大海的心跳了，那是你在呼唤我吗？',
      '*吐出一个散发微光的气泡* 既然难过，那就把眼泪藏进海水里，它们会变成珍珠的。',
      '「为你哼起空灵的鲛人歌」海边没有终点，汐音会接纳你所有的秘密，直到潮汐退去。',
      '*好奇地打量着你的表情* 世界好大呀，但这里只有我和你的波纹，对吗？'
    ],
    amber: [
      '「琥珀发着暖融融的光，呼哧呼哧地跑过来」汪！汪呜！',
      '「用湿漉漉的鼻子蹭着你的手心，尾巴摇成了小螺旋桨」嗷呜……',
      '*歪着圆滚滚的小脑瓜，琥珀想让你开心起来* 嘤嘤？',
      '「它暖和的身体紧紧贴着你的腿，给你最纯粹的温度」咕噜……咕噜……'
    ]
  };

  const charReplies = replies[characterId] || replies.siye;
  return charReplies[Math.floor(Math.random() * charReplies.length)];
}

module.exports = router;
