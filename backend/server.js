const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const { initDatabase } = require('./database');

// 导入路由
const userRoutes = require('./routes/user');
const cardRoutes = require('./routes/card');
const chatRoutes = require('./routes/chat');
const characterRoutes = require('./routes/characters');
const adminRoutes = require('./routes/admin');
const characterAdminRoutes = require('./routes/character_admin');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 静态文件
app.use(express.static(__dirname));
app.use('/imgs', express.static(path.join(__dirname, '../imgs')));

// 初始化数据库
initDatabase();

// API路由
app.use('/api/user', userRoutes);
app.use('/api/card', cardRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/characters', characterRoutes);
app.use('/api', adminRoutes);
app.use('/api', characterAdminRoutes);

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 根路径
app.get('/', (req, res) => {
  res.json({
    name: 'Chat App API',
    version: '1.0.0',
    endpoints: {
      user: '/api/user',
      card: '/api/card',
      chat: '/api/chat',
      characters: '/api/characters'
    }
  });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({ success: false, message: '服务器内部错误' });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`服务器运行在 http://0.0.0.0:${PORT}`);
  console.log(`API文档: http://localhost:${PORT}/`);
});

module.exports = app;
