const express = require('express');
const router = express.Router();
const { db } = require('../database');

// 注册/获取设备ID
router.post('/register', (req, res) => {
  const { device_id } = req.body;

  if (!device_id) {
    return res.status(400).json({ success: false, message: 'device_id不能为空' });
  }

  // 检查用户是否存在
  db.get('SELECT * FROM users WHERE device_id = ?', [device_id], (err, user) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (user) {
      // 用户已存在，返回用户信息
      return res.json({
        success: true,
        data: {
          device_id: user.device_id,
          free_chats: user.free_chats,
          vip_expire_time: user.vip_expire_time,
          is_vip: user.vip_expire_time ? new Date(user.vip_expire_time) > new Date() : false
        }
      });
    }

    // 创建新用户
    db.run(
      'INSERT INTO users (device_id, free_chats) VALUES (?, ?)',
      [device_id, 10],
      function (err) {
        if (err) {
          return res.status(500).json({ success: false, message: '创建用户失败' });
        }

        res.json({
          success: true,
          data: {
            device_id: device_id,
            free_chats: 10,
            vip_expire_time: null,
            is_vip: false
          }
        });
      }
    );
  });
});

// 获取用户信息
router.get('/info', (req, res) => {
  const { device_id } = req.query;

  if (!device_id) {
    return res.status(400).json({ success: false, message: 'device_id不能为空' });
  }

  db.get('SELECT * FROM users WHERE device_id = ?', [device_id], (err, user) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: '用户不存在' });
    }

    const isVip = user.vip_expire_time ? new Date(user.vip_expire_time) > new Date() : false;

    res.json({
      success: true,
      data: {
        device_id: user.device_id,
        free_chats: user.free_chats,
        vip_expire_time: user.vip_expire_time,
        is_vip: isVip
      }
    });
  });
});

module.exports = router;
