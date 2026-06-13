const db = require('../config/database');

async function getStats(req, res) {
  try {
    const [[{ totalStudents }]] = await db.pool.query('SELECT COUNT(*) AS totalStudents FROM students');
    const [[{ totalCourses }]] = await db.pool.query('SELECT COUNT(*) AS totalCourses FROM courses WHERE is_published = TRUE');
    const [[{ activeUsers }]] = await db.pool.query('SELECT COUNT(*) AS activeUsers FROM users WHERE is_active = TRUE');
    const [[{ aiSessionsToday }]] = await db.pool.query(
      'SELECT COUNT(*) AS aiSessionsToday FROM ai_logs WHERE DATE(created_at) = CURDATE()'
    );

    res.json({
      totalStudents,
      totalCourses,
      activeUsers,
      aiSessionsToday,
      tagline: 'Your AI Teacher Anytime',
      platform: 'MacallinAI',
    });
  } catch (err) {
    res.status(503).json({
      totalStudents: 0,
      totalCourses: 0,
      activeUsers: 0,
      aiSessionsToday: 0,
      tagline: 'Your AI Teacher Anytime',
      platform: 'MacallinAI',
      offline: true,
    });
  }
}

module.exports = { getStats };
