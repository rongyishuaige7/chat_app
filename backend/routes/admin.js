const express = require('express');
const router = express.Router();
const { db } = require('../database');

// 获取所有卡密
router.get('/card/all', (req, res) => {
  const { admin_key } = req.query;

  const validAdminKey = process.env.ADMIN_KEY || 'admin_secret_key';
  if (admin_key !== validAdminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  db.all('SELECT * FROM card_keys ORDER BY created_at DESC', [], (err, cards) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    res.json({
      success: true,
      data: cards
    });
  });
});

// 获取所有用户
router.get('/user/all', (req, res) => {
  const { admin_key } = req.query;

  if (admin_key !== 'admin_secret_key') {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  db.all('SELECT id, device_id, free_chats, vip_expire_time, created_at FROM users ORDER BY created_at DESC', [], (err, users) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    res.json({
      success: true,
      data: users
    });
  });
});

module.exports = router;
