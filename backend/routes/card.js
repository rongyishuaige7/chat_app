const express = require('express');
const router = express.Router();
const { db } = require('../database');

// 验证并使用卡密
router.post('/verify', (req, res) => {
  const { card_key, device_id } = req.body;

  if (!card_key || !device_id) {
    return res.status(400).json({ success: false, message: '卡密和设备ID不能为空' });
  }

  // 查找卡密
  db.get('SELECT * FROM card_keys WHERE card_key = ?', [card_key], (err, card) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (!card) {
      return res.json({ success: false, message: '卡密不存在' });
    }

    if (card.used_by) {
      return res.json({ success: false, message: '卡密已被使用' });
    }

    // 获取卡密类型信息
    db.get('SELECT * FROM card_types WHERE type_key = ?', [card.card_type], (err, cardType) => {
      if (err || !cardType) {
        return res.status(500).json({ success: false, message: '卡密类型错误' });
      }

      // 更新卡密使用状态
      db.run(
        'UPDATE card_keys SET used_by = ?, used_at = datetime("now") WHERE id = ?',
        [device_id, card.id],
        function (err) {
          if (err) {
            return res.status(500).json({ success: false, message: '更新卡密失败' });
          }

          // 计算VIP到期时间
          const expireTime = new Date();
          expireTime.setDate(expireTime.getDate() + cardType.duration_days);

          // 检查用户是否存在
          db.get('SELECT * FROM users WHERE device_id = ?', [device_id], (err, user) => {
            if (err) {
              return res.status(500).json({ success: false, message: '数据库错误' });
            }

            if (user) {
              // 用户存在，VIP时间累加
              let newExpireTime;
              if (user.vip_expire_time && new Date(user.vip_expire_time) > new Date()) {
                // 已有VIP时间，在现有基础上累加
                const currentExpire = new Date(user.vip_expire_time);
                currentExpire.setDate(currentExpire.getDate() + cardType.duration_days);
                newExpireTime = currentExpire;
              } else {
                // 没有VIP或已过期，从现在开始计算
                newExpireTime = expireTime;
              }

              db.run(
                'UPDATE users SET vip_expire_time = ?, updated_at = datetime("now") WHERE device_id = ?',
                [newExpireTime.toISOString(), device_id],
                function (err) {
                  if (err) {
                    return res.status(500).json({ success: false, message: '更新用户VIP失败' });
                  }

                  res.json({
                    success: true,
                    message: `兑换成功！获得${cardType.name}资格`,
                    data: {
                      vip_expire_time: newExpireTime.toISOString()
                    }
                  });
                }
              );
            } else {
              // 用户不存在，先创建用户
              db.run(
                'INSERT INTO users (device_id, vip_expire_time) VALUES (?, ?)',
                [device_id, expireTime.toISOString()],
                function (err) {
                  if (err) {
                    return res.status(500).json({ success: false, message: '创建用户失败' });
                  }

                  res.json({
                    success: true,
                    message: `兑换成功！获得${cardType.name}资格`,
                    data: {
                      vip_expire_time: expireTime.toISOString()
                    }
                  });
                }
              );
            }
          });
        }
      );
    });
  });
});

// 获取卡密类型列表
router.get('/types', (req, res) => {
  db.all('SELECT * FROM card_types ORDER BY duration_days', [], (err, types) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    res.json({
      success: true,
      data: types
    });
  });
});

// 生成新卡密（管理员）
router.post('/generate', (req, res) => {
  const { card_type, count = 1, admin_key } = req.body;

  // 简单管理员验证（生产环境应使用更安全的方式）
  const validAdminKey = process.env.ADMIN_KEY || 'admin_secret_key';
  if (admin_key !== validAdminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  if (!card_type) {
    return res.status(400).json({ success: false, message: '卡密类型不能为空' });
  }

  // 获取卡密类型
  db.get('SELECT * FROM card_types WHERE type_key = ?', [card_type], (err, cardType) => {
    if (err || !cardType) {
      return res.status(400).json({ success: false, message: '卡密类型不存在' });
    }

    const generatedCards = [];
    for (let i = 0; i < count; i++) {
      const cardKey = `${card_type}-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`;
      generatedCards.push(cardKey);

      db.run(
        'INSERT INTO card_keys (card_key, card_type, duration_days) VALUES (?, ?, ?)',
        [cardKey, card_type, cardType.duration_days]
      );
    }

    res.json({
      success: true,
      message: `成功生成${count}个卡密`,
      data: generatedCards
    });
  });
});

module.exports = router;
