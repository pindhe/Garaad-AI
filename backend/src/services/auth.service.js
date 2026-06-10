const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const config = require('../config');

async function register({ email, password, firstName, lastName, role = 'student', gradeLevel, className }) {
  const existing = await db.query('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length) throw new Error('Email already registered');

  const passwordHash = await bcrypt.hash(password, 12);
  const result = await db.query(
    'INSERT INTO users (email, password_hash, role, first_name, last_name) VALUES (?, ?, ?, ?, ?)',
    [email, passwordHash, role, firstName, lastName]
  );

  const userId = result.insertId;

  if (role === 'student') {
    await db.query(
      'INSERT INTO students (user_id, grade_level, class_name) VALUES (?, ?, ?)',
      [userId, gradeLevel || null, className || null]
    );
  } else if (role === 'admin') {
    await db.query('INSERT INTO admins (user_id) VALUES (?)', [userId]);
  }

  return getUserById(userId);
}

async function login(email, password) {
  const users = await db.query(
    'SELECT id, email, password_hash, role, first_name, last_name, is_active FROM users WHERE email = ?',
    [email]
  );
  const user = users[0];
  if (!user) throw new Error('Invalid credentials');
  if (!user.is_active) throw new Error('Account suspended');

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) throw new Error('Invalid credentials');

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );

  const profile = await getUserById(user.id);
  return { token, user: profile };
}

async function getUserById(id) {
  const users = await db.query(
    `SELECT u.id, u.email, u.role, u.first_name, u.last_name, u.avatar_url, u.is_active, u.created_at
     FROM users u WHERE u.id = ?`,
    [id]
  );
  const user = users[0];
  if (!user) return null;

  if (user.role === 'student') {
    const students = await db.query(
      'SELECT id, grade_level, class_name, subscription_plan, total_xp FROM students WHERE user_id = ?',
      [id]
    );
    user.student = students[0];
  } else if (user.role === 'admin') {
    const admins = await db.query('SELECT id, permissions FROM admins WHERE user_id = ?', [id]);
    user.admin = admins[0];
  }

  return user;
}

module.exports = { register, login, getUserById };
