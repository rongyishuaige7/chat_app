const express = require('express');
const router = express.Router();
const { db } = require('../database');

// 获取角色列表
router.get('/', (req, res) => {
  db.all('SELECT * FROM characters ORDER BY created_at', [], (err, characters) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    res.json({
      success: true,
      data: characters
    });
  });
});

// 获取单个角色详情
router.get('/:id', (req, res) => {
  const { id } = req.params;

  db.get('SELECT * FROM characters WHERE id = ?', [id], (err, character) => {
    if (err) {
      return res.status(500).json({ success: false, message: '数据库错误' });
    }

    if (!character) {
      return res.status(404).json({ success: false, message: '角色不存在' });
    }

    res.json({
      success: true,
      data: character
    });
  });
});

module.exports = router;
