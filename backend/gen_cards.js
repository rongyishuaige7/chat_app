const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// 连接数据库
const dbPath = path.join(__dirname, 'chat.db');
const db = new sqlite3.Database(dbPath);

// 提取命令行参数，例如: node gen_cards.js 30 nb001
const count = parseInt(process.argv[2]) || 5;
const card_type = process.argv[3] || 'nb001';

// 所有的卡密类型字典
const CARD_TYPES = {
    'nb001': 3, // 体验卡 3天
    'nb002': 7, // 周卡 7天
    'nb003': 30 // 月卡 30天
};

const duration_days = CARD_TYPES[card_type];

if (!duration_days) {
    console.log(`❌ 错误: 未知的卡密类型 '${card_type}'`);
    console.log(`支持的卡密类型: nb001 (3天体验), nb002 (7天周卡), nb003 (30天月卡)`);
    process.exit(1);
}

const generatedCards = [];
const insertStmt = db.prepare('INSERT INTO card_keys (card_key, card_type, duration_days) VALUES (?, ?, ?)');

console.log(`\n⏳ 正在生成 ${count} 张 [${card_type}] 类型的星辰秘钥 (有效新增 ${duration_days} 天) ...\n`);

db.serialize(() => {
    for (let i = 0; i < count; i++) {
        // 生成混淆防伪卡密: e.g. nb003-169824...-A2E4B1
        const randomHex = Math.random().toString(36).substr(2, 6).toUpperCase();
        const timestamp = Date.now().toString().slice(-6); // 截取时间戳后6位
        const cardKey = `LUMINA-${card_type.toUpperCase()}-${timestamp}-${randomHex}`;

        insertStmt.run(cardKey, card_type, duration_days);
        generatedCards.push(cardKey);
    }

    insertStmt.finalize();

    generatedCards.forEach((c, index) => {
        console.log(`[${index + 1}] ${c}`);
    });

    console.log(`\n✅ 成功生成 ${count} 张卡密！将其复制给用户即可。`);
    db.close();
});
