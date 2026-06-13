const mysql = require('mysql2/promise');
const config = require('./index');

const pool = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
});

function sanitizeParams(params) {
  return params.map((value) => (value === undefined ? null : value));
}

async function query(sql, params = []) {
  const [rows] = await pool.execute(sql, sanitizeParams(params));
  return rows;
}

async function testConnection() {
  const conn = await pool.getConnection();
  conn.release();
  return true;
}

module.exports = { pool, query, testConnection };
