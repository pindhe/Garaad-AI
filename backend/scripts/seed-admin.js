require('dotenv').config();
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const config = require('../src/config');

async function seedAdmin() {
  const email = process.argv[2] || 'admin@macallinai.com';
  const password = process.argv[3] || 'admin123';
  const passwordHash = await bcrypt.hash(password, 12);

  const conn = await mysql.createConnection({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database,
  });

  const [existing] = await conn.execute('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length) {
    console.log('Admin already exists:', email);
    await conn.end();
    return;
  }

  const [result] = await conn.execute(
    'INSERT INTO users (email, password_hash, role, first_name, last_name) VALUES (?, ?, ?, ?, ?)',
    [email, passwordHash, 'admin', 'Admin', 'MacallinAI']
  );
  await conn.execute('INSERT INTO admins (user_id) VALUES (?)', [result.insertId]);
  await conn.end();

  console.log('Admin created:', email, '/', password);
}

seedAdmin().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
