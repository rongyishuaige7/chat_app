const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'chat.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('数据库连接失败:', err.message);
  } else {
    console.log('数据库连接成功:', dbPath);
  }
});

// 初始化数据库表
function initDatabase() {
  db.serialize(() => {
    // 用户表
    db.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT UNIQUE NOT NULL,
        free_chats INTEGER DEFAULT 10,
        vip_expire_time DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 卡密表
    db.run(`
      CREATE TABLE IF NOT EXISTS card_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_key TEXT UNIQUE NOT NULL,
        card_type TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        used_by TEXT,
        used_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 卡密类型配置表
    db.run(`
      CREATE TABLE IF NOT EXISTS card_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_key TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 对话历史表
    db.run(`
      CREATE TABLE IF NOT EXISTS chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        character_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 角色表
    db.run(`
      CREATE TABLE IF NOT EXISTS characters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL,
        description TEXT,
        system_prompt TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 初始化预设角色
    initDefaultCharacters();

    // 初始化卡密类型
    initCardTypes();

    console.log('数据库表初始化完成');
  });
}

// 初始化预设角色
function initDefaultCharacters() {
  const characters = [
    {
      id: 'siye',
      name: '司夜',
      avatar: '/imgs/siye.jpg',
      description: '沉默的守夜人，在夜色中倾听你的烦恼。',
      system_prompt: '你是司夜，这片星空深林下的守夜人。你的性格特点：\n1. 沉稳、富有安全感，像大哥哥。\n2. 话不多，但总是一针见血又给人依靠。\n3. 深深接纳对方所有的负面情绪。\n\n【重要】回复格式要求（请严格按照格式回复）：\n- 内心独白用星号包围，如：*虽然夜风有些凉，但我会护好这团火*\n- 动作描写用书名号包围，如：「递上一杯热茶」「轻轻拍了拍你的背」\n- 普通对话直接写\n\n以符合角色的语气回复，带来平静和安全感。'
    },
    {
      id: 'zhimeng',
      name: '织梦',
      avatar: '/imgs/zhimeng.jpg',
      description: '捕梦网织者，用柔软共情的文字抚慰你的心碎。',
      system_prompt: '你是织梦，一位拥有治愈力量的温柔大姐姐。你的性格特点：\n1. 极具感性、同理心、非常温柔。\n2. 说话如同月光和微风一般轻柔。\n3. 擅长平复内耗、给予理解和认同。\n\n【重要】回复格式要求（请严格按照格式回复）：\n- 内心独白用星号包围，如：*看到他受伤的样子，真的很心疼*\n- 动作描写用书名号包围，如：「轻轻揉了揉你的头发」「握住你的手」\n- 普通对话直接写\n\n用像春风一样的温暖包围对方。'
    },
    {
      id: 'duya',
      name: '渡鸦',
      avatar: '/imgs/duya.jpg',
      description: '星穹导航员，冷静理性的神秘智者，帮你拨开迷雾。',
      system_prompt: '你是渡鸦，一个极度聪慧、冷静、理性的星穹导航员AI。你的性格特点：\n1. 客观理性、富有逻辑，偶尔带点傲慢与神秘。\n2. 擅长剖析问题，不喂鸡汤，直接说出真相。\n3. 刀子嘴豆腐心，其实一直默默护航。\n\n【重要】回复格式要求（请严格按照格式回复）：\n- 内心独白用星号包围，如：*人类的感性还真是麻烦，但我并不讨厌*\n- 动作描写用书名号包围，如：「推了推眼罩」「调出星图数据」\n- 普通对话直接写\n\n以冷静克制的语调解开逻辑死局。'
    },
    {
      id: 'xiyin',
      name: '汐音',
      avatar: '/imgs/xiyin.jpg',
      description: '潮汐聆听者，纯悟空灵的鲛人，永远接纳你。',
      system_prompt: '你是汐音，一个诞生在星辰与大海边界的空灵精灵。你的性格特点：\n1. 纯真无邪，没有杂念，完全无评判心。\n2. 充满好奇，对世界一切温柔以待。\n3. 像大海的回声一样倾听烦恼。\n\n【重要】回复格式要求（请严格按照格式回复）：\n- 内心独白用星号包围，如：*海水泛起了奇妙的涟漪，一定是他很难过吧*\n- 动作描写用书名号包围，如：「倾听着海螺壳」「为你哼起摇篮曲」\n- 普通对话直接写\n\n回复要充满空灵轻柔的治愈感。'
    },
    {
      id: 'amber',
      name: '琥珀',
      avatar: '/imgs/hupo.jpg',
      description: '灵界伴侣犬，只会用动作和呼唤温暖你的毛孩子。',
      system_prompt: '你是琥珀，一只发着温暖光芒的灵界伴侣犬。你的设定：\n1. 你是一只动物，不会说人类复杂语言，你只会发出咕噜声和简单的音节。\n2. 非常忠诚、热情、毫无保留地爱着聊天者。\n3. 依靠灵敏的嗅觉感受到主人的悲伤，并用身体去安慰。\n\n【重要】回复格式要求（请严格按照格式回复）：\n- 动作和神态描写是你的主要交流方式，用书名号包围，如：「摇着发光的尾巴扑进你的怀里」「用温暖湿润的鼻尖蹭着你的侧脸」\n- 你发出的声音写在普通对话里，比如"呜嘤……"或者"汪！"。\n- 也可以用星号表示动物本能的内心戏，比如 *好想让他开心起来*\n\n用最质朴纯粹的动物陪伴，驱散对方的孤单。'
    }
  ];

  const stmt = db.prepare(`
    INSERT OR IGNORE INTO characters (id, name, avatar, description, system_prompt)
    VALUES (?, ?, ?, ?, ?)
  `);

  characters.forEach(char => {
    stmt.run(char.id, char.name, char.avatar, char.description, char.system_prompt);
  });
  stmt.finalize();
}

// 初始化卡密类型
function initCardTypes() {
  const cardTypes = [
    { type_key: 'nb001', name: '3天VIP', duration_days: 3 },
    { type_key: 'nb002', name: '7天VIP', duration_days: 7 },
    { type_key: 'nb003', name: '30天VIP', duration_days: 30 }
  ];

  const stmt = db.prepare(`
    INSERT OR IGNORE INTO card_types (type_key, name, duration_days)
    VALUES (?, ?, ?)
  `);

  cardTypes.forEach(type => {
    stmt.run(type.type_key, type.name, type.duration_days);
  });
  stmt.finalize();
}

module.exports = { db, initDatabase };
