require('dotenv').config();
const mysql = require('mysql2/promise');
const config = require('../src/config');

async function migrate() {
  const conn = await mysql.createConnection({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database,
  });

  try {
    await conn.query(
      'ALTER TABLE subjects ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE'
    );
  } catch {
    try {
      await conn.query('ALTER TABLE subjects ADD COLUMN is_active BOOLEAN DEFAULT TRUE');
    } catch {
      /* column may already exist */
    }
  }

  try {
    await conn.query(
      'ALTER TABLE subjects ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
    );
  } catch {
    try {
      await conn.query('ALTER TABLE subjects ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
    } catch {
      /* column may already exist */
    }
  }

  const seeds = [
    ['IT', 'Programming, software, and technology', 'code'],
    ['Language', 'English, Somali, and world languages', 'languages'],
    ['Sports', 'Physical education, fitness, and athletics', 'trophy'],
    ['Health', 'Nutrition, wellness, and medical basics', 'heart-pulse'],
  ];

  for (const [name, description, icon] of seeds) {
    await conn.query(
      `INSERT INTO subjects (name, description, icon, is_active) VALUES (?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE description = VALUES(description), icon = VALUES(icon)`,
      [name, description, icon]
    );
  }

  await conn.end();
  console.log('Subjects migration completed');
}

migrate().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
