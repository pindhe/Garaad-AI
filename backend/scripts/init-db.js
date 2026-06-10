require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../src/config');

async function initDb() {
  const schemaPath = path.join(__dirname, '..', 'database', 'schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf8');

  const connection = await mysql.createConnection({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    multipleStatements: true,
  });

  console.log('Running schema...');
  await connection.query(schema);
  await connection.end();
  console.log('Database initialized successfully');
}

initDb().catch((err) => {
  console.error('Database init failed:', err.message);
  process.exit(1);
});
