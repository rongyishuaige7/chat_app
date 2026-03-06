# AI角色扮演聊天App (猫箱类)

---

## 项目概述

开发一个类似猫箱的AI角色扮演聊天App，具备虚拟形象、角色设定、文字聊天、多轮对话记忆、沉浸式对话风格等核心功能。

---

## 技术栈

- **App端**: Flutter (iOS/Android)
- **后端**: Node.js + Express
- **数据库**: SQLite (轻量级)
- **AI**: Minimax M2.5
- **服务器**: Ubuntu

---

## 项目结构

```
/home/rongyi/桌面/chat_app/
├── backend/                   # Node.js后端
│   ├── server.js              # 主服务器
│   ├── database.js            # SQLite数据库
│   ├── admin.html             # Web管理后台
│   ├── chat.db                # 数据库文件
│   └── routes/                # API路由
│       ├── user.js            # 用户相关API
│       ├── card.js            # 卡密相关API
│       ├── chat.js            # 聊天API
│       ├── characters.js      # 角色API
│       └── ...
│
└── lib/                       # Flutter App
    ├── main.dart
    ├── models/                # 数据模型
    ├── providers/             # 状态管理
    ├── screens/               # 页面
    └── services/             # API服务
```

---

## 后端API

| 接口 | 方法 | 说明 |
|-----|------|------|
| `/api/user/register` | POST | 用户注册 |
| `/api/user/info` | GET | 获取用户信息 |
| `/api/card/verify` | POST | 兑换卡密 |
| `/api/card/types` | GET | 卡密类型列表 |
| `/api/card/generate` | POST | 生成卡密(管理员) |
| `/api/card/all` | GET | 所有卡密(管理员) |
| `/api/chat/send` | POST | 发送消息 |
| `/api/chat/history/:id` | GET | 对话历史 |
| `/api/chat/clear/:id` | DELETE | 清除历史 |
| `/api/characters` | GET | 角色列表 |
| `/api/user/all` | GET | 所有用户(管理员) |

---

## 预设角色

| ID | 名称 | 头像 | 性格 |
|----|------|------|------|
| `mia` | 咪娅 | bottts | 傲娇猫娘，偶尔傲娇但其实关心主人 |
| `haruko` | 晴子 | avataaars | 温柔知心大姐姐，善解人意 |
| `momoko` | 小桃 | fun-emoji | 元气少女，活泼开朗 |

---

## VIP卡密

| 类型 | 时长 | 说明 |
|------|------|------|
| `nb001` | 3天 | 3天VIP |
| `nb002` | 7天 | 7天VIP |
| `nb003` | 30天 | 30天VIP |

**管理员密钥**: `admin_secret_key`

---

## 启动后端

```bash
cd /home/rongyi/桌面/chat_app/backend

# 设置Minimax API Key
export MINIMAX_API_KEY="你的API Key"

# 启动服务 (默认端口3002)
PORT=3002 node server.js
```

---

## 生成卡密

```bash
# 命令行方式
curl -X POST 'http://192.168.1.23:3002/api/card/generate' \
  -H 'Content-Type: application/json' \
  -d '{"card_type":"nb001","count":5,"admin_key":"admin_secret_key"}'
```

**参数说明：**
- `card_type`: 卡密类型 (nb001/nb002/nb003)
- `count`: 生成数量
- `admin_key`: 管理员密钥

---

## 管理后台

在浏览器中打开：
```
http://192.168.1.23:3002/admin.html
```
##端口被占用
# 查找占用 3002 端口的进程                                                    
lsof -i :3002
                                                                                
# 或者直接杀掉 node 进程                                  
pkill -f "node server.js"


功能：
- 生成卡密
- 查看卡密列表
- 查看用户统计

---

## App配置

### API地址配置

文件: `chat_app/lib/services/api_service.dart`

```dart
static const String baseUrl = 'http://192.168.1.23:3002/api';
```

### 编译Android APK

```bash
cd /home/rongyi/桌面/chat_app
flutter build apk --debug

### 直接运行安装到安卓手机

flutter run -d 22041216C

```

APK输出位置: `build/app/outputs/flutter-apk/app-debug.apk`

---

## Minimax API配置

- **API地址**: `https://api.minimaxi.com/v1/text/chatcompletion_v2`
- **模型**: `MiniMax-M2.5`

文件: `backend/routes/chat.js`

```javascript
const MINIMAX_API_URL = 'https://api.minimaxi.com/v1/text/chatcompletion_v2';
const MINIMAX_MODEL = 'MiniMax-M2.5';
```

---

## 用户权益

| 权益 | 免费用户 | VIP用户 |
|------|---------|--------|
| 免费次数 | 10次 | 无限 |
| 广告 | 有 | 无 |
| 专属功能 | - | 优先体验 |

---

## 常用命令

```bash
# 查看所有卡密
curl 'http://192.168.1.23:3002/api/card/all?admin_key=admin_secret_key'

# 查看所有用户
curl 'http://192.168.1.23:3002/api/user/all?admin_key=admin_secret_key'

# 查看卡密类型
curl 'http://192.168.1.23:3002/api/card/types'

# 测试聊天API
curl -X POST 'http://192.168.1.23:3002/api/chat/send' \
  -H 'Content-Type: application/json' \
  -d '{"device_id":"test","character_id":"mia","message":"你好"}'
```

---

## 数据库表结构

### users - 用户表
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT UNIQUE NOT NULL,
  free_chats INTEGER DEFAULT 10,
  vip_expire_time DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### card_keys - 卡密表
```sql
CREATE TABLE card_keys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_key TEXT UNIQUE NOT NULL,
  card_type TEXT NOT NULL,
  duration_days INTEGER NOT NULL,
  used_by TEXT,
  used_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### chat_history - 对话历史表
```sql
CREATE TABLE chat_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT NOT NULL,
  character_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### characters - 角色表
```sql
CREATE TABLE characters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  avatar TEXT NOT NULL,
  description TEXT,
  system_prompt TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## 文件位置汇总

| 文件 | 路径 |
|------|------|
| 后端主文件 | `/home/rongyi/桌面/chat_app/backend/server.js` |
| 数据库 | `/home/rongyi/桌面/chat_app/backend/chat.db` |
| 管理后台 | `/home/rongyi/桌面/chat_app/backend/admin.html` |
| Flutter入口 | `/home/rongyi/桌面/chat_app/lib/main.dart` |
| API服务 | `/home/rongyi/桌面/chat_app/lib/services/api_service.dart` |
| Android APK | `/home/rongyi/桌面/chat_app/build/app/outputs/flutter-apk/app-debug.apk` |

---

## 注意事项

1. 手机连接电脑热点或同一局域网才能访问后端
2. 卡密兑换后VIP时间会累加
3. 免费次数用完后需要兑换VIP继续使用
4. API Key需从 MiniMax 开放平台获取

---

文档更新于: 2026-03-04
