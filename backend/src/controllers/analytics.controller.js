const db = require('../config/database');

async function getDashboard(req, res) {
  try {
    const [[{ totalStudents }]] = await db.pool.query(
      'SELECT COUNT(*) AS totalStudents FROM students'
    );
    const [[{ activeUsers }]] = await db.pool.query(
      'SELECT COUNT(*) AS activeUsers FROM users WHERE is_active = TRUE'
    );
    const [[{ totalCourses }]] = await db.pool.query(
      'SELECT COUNT(*) AS totalCourses FROM courses'
    );
    const [[{ aiRequestsToday }]] = await db.pool.query(
      'SELECT COUNT(*) AS aiRequestsToday FROM ai_logs WHERE DATE(created_at) = CURDATE()'
    );
    const [[{ totalRevenue }]] = await db.pool.query(
      "SELECT COALESCE(SUM(amount), 0) AS totalRevenue FROM payments WHERE status = 'completed'"
    );

    const enrollmentsByMonth = await db.query(
      `SELECT DATE_FORMAT(enrolled_at, '%Y-%m') AS month, COUNT(*) AS count
       FROM enrollments WHERE enrolled_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
       GROUP BY month ORDER BY month`
    );

    const aiUsageByAction = await db.query(
      `SELECT action, COUNT(*) AS count FROM ai_logs
       WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
       GROUP BY action ORDER BY count DESC`
    );

    const topCourses = await db.query(
      `SELECT c.title, COUNT(e.id) AS enrollments
       FROM courses c LEFT JOIN enrollments e ON e.course_id = c.id
       GROUP BY c.id ORDER BY enrollments DESC LIMIT 5`
    );

    res.json({
      stats: { totalStudents, activeUsers, totalCourses, aiRequestsToday, totalRevenue },
      enrollmentsByMonth,
      aiUsageByAction,
      topCourses,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getStudentProgress(req, res) {
  try {
    const progress = await db.query(
      `SELECT u.first_name, u.last_name, c.title AS course_title, e.progress_percent, e.enrolled_at
       FROM enrollments e
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       JOIN courses c ON c.id = e.course_id
       ORDER BY e.progress_percent DESC LIMIT 50`
    );
    res.json(progress);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function listSubscriptions(req, res) {
  try {
    const subs = await db.query('SELECT * FROM subscriptions ORDER BY price_monthly');
    res.json(subs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createAnnouncement(req, res) {
  try {
    const { title, message, userIds } = req.body;
    const targets = userIds?.length
      ? userIds
      : (await db.query('SELECT id FROM users WHERE role = ?', ['student'])).map((u) => u.id);

    for (const userId of targets) {
      await db.query(
        "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, 'announcement')",
        [userId, title, message]
      );
    }
    res.status(201).json({ message: `Announcement sent to ${targets.length} users` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getNotifications(req, res) {
  try {
    const notifications = await db.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function markNotificationRead(req, res) {
  try {
    await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  getDashboard,
  getStudentProgress,
  listSubscriptions,
  createAnnouncement,
  getNotifications,
  markNotificationRead,
};
