const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const rateLimit = require('express-rate-limit'); // 引入防护
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
// 配置 CORS: 如果只给App用，可以留空 '*'，但在生产中最好改成具体的域名或者禁止外部跨域
app.use(cors({
  origin: '*' // 后期如有web端可改为 ['https://yourdomain.com']
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 如果部署在 Nginx 等反向代理后面，必须开启 trust proxy，否则限流器会把所有请求都算作 Nginx 的 IP
app.set('trust proxy', 1);

// 第一层防线：全局基础拉黑/限流 (保护服务器被DDoS)
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 300, // 限制每个 IP 15分钟内最多请求 300 次
  message: { success: false, message: '请求过于频繁，请稍后重试' }
});

// 第二层防线：严格对话防刷 (保护大模型 API 余额被恶意利用)
const chatLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,  // 1分钟
  max: 15, // 限制每个 IP 每分钟只能发 15 条消息（防机器人恶意自动化刷词）
  message: { success: false, message: '说话太快啦，让 AI 休息一会吧' }
});

app.use('/api/', globalLimiter); // 作用于所有 /api/ 开头的接口

// 静态文件
app.use(express.static(__dirname));
app.use('/imgs', express.static(path.join(__dirname, '../imgs')));

// 初始化数据库
initDatabase();

// API路由
app.use('/api/user', userRoutes);
app.use('/api/card', cardRoutes);
app.use('/api/chat', chatLimiter, chatRoutes); // 特别给 chat 接口加上严格限制
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
