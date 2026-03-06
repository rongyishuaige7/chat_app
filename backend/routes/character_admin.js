const express = require('express');
const router = express.Router();
const { db } = require('../database');

// 添加角色（管理员）
router.post('/character/add', (req, res) => {
  const { admin_key } = req.query;
  const { id, name, avatar, description, system_prompt } = req.body;

  const validAdminKey = process.env.ADMIN_KEY || 'admin_secret_key';
  if (admin_key !== validAdminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  if (!id || !name || !system_prompt) {
    return res.status(400).json({ success: false, message: '缺少必填字段' });
  }

  const avatarUrl = avatar || `https://api.dicebear.com/9.x/avataaars/png?seed=${id}`;

  db.run(
    `INSERT OR REPLACE INTO characters (id, name, avatar, description, system_prompt) VALUES (?, ?, ?, ?, ?)`,
    [id, name, avatarUrl, description || '', system_prompt],
    function (err) {
      if (err) {
        return res.status(500).json({ success: false, message: '添加角色失败' });
      }

      res.json({
        success: true,
        message: '角色添加成功'
      });
    }
  );
});

// 删除角色（管理员）
router.delete('/character/:id', (req, res) => {
  const { admin_key } = req.query;
  const { id } = req.params;

  if (admin_key !== 'admin_secret_key') {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  db.run('DELETE FROM characters WHERE id = ?', [id], function (err) {
    if (err) {
      return res.status(500).json({ success: false, message: '删除角色失败' });
    }

    res.json({
      success: true,
      message: '角色删除成功'
    });
  });
});

module.exports = router;
