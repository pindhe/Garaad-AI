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
    subs.forEach((sub) => {
      if (typeof sub.features === 'string') {
        try {
          sub.features = JSON.parse(sub.features);
        } catch {
          sub.features = [];
        }
      }
    });
    res.json(subs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

const PLAN_TYPES = ['free', 'pro', 'school', 'university'];

function normalizeFeatures(features) {
  if (Array.isArray(features)) return features.filter(Boolean);
  if (typeof features === 'string') {
    const trimmed = features.trim();
    if (!trimmed) return [];
    if (trimmed.startsWith('[')) {
      try {
        const parsed = JSON.parse(trimmed);
        return Array.isArray(parsed) ? parsed.filter(Boolean) : [];
      } catch {
        return trimmed.split('\n').map((f) => f.trim()).filter(Boolean);
      }
    }
    return trimmed.split('\n').map((f) => f.trim()).filter(Boolean);
  }
  return [];
}

async function createSubscription(req, res) {
  try {
    const { name, planType, priceMonthly, features, isActive } = req.body;
    if (!name?.trim()) return res.status(400).json({ error: 'Name is required' });
    if (!planType || !PLAN_TYPES.includes(planType)) {
      return res.status(400).json({ error: 'Valid planType is required (free, pro, school, university)' });
    }

    const existing = await db.query('SELECT id FROM subscriptions WHERE plan_type = ?', [planType]);
    if (existing.length) {
      return res.status(400).json({ error: 'A plan with this type already exists' });
    }

    const result = await db.query(
      'INSERT INTO subscriptions (name, plan_type, price_monthly, features, is_active) VALUES (?, ?, ?, ?, ?)',
      [name.trim(), planType, priceMonthly ?? 0, JSON.stringify(normalizeFeatures(features)), isActive ?? true]
    );
    const [sub] = await db.query('SELECT * FROM subscriptions WHERE id = ?', [result.insertId]);
    if (typeof sub.features === 'string') sub.features = JSON.parse(sub.features);
    res.status(201).json(sub);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function updateSubscriptionPlan(req, res) {
  try {
    const { name, planType, priceMonthly, features, isActive } = req.body;
    const id = req.params.id;

    const [existing] = await db.query('SELECT * FROM subscriptions WHERE id = ?', [id]);
    if (!existing) return res.status(404).json({ error: 'Subscription not found' });

    if (planType && planType !== existing.plan_type) {
      if (!PLAN_TYPES.includes(planType)) {
        return res.status(400).json({ error: 'Invalid planType' });
      }
      const duplicate = await db.query(
        'SELECT id FROM subscriptions WHERE plan_type = ? AND id != ?',
        [planType, id]
      );
      if (duplicate.length) {
        return res.status(400).json({ error: 'Another plan already uses this type' });
      }
    }

    await db.query(
      `UPDATE subscriptions SET
         name = COALESCE(?, name),
         plan_type = COALESCE(?, plan_type),
         price_monthly = COALESCE(?, price_monthly),
         features = COALESCE(?, features),
         is_active = COALESCE(?, is_active)
       WHERE id = ?`,
      [
        name?.trim() || null,
        planType || null,
        priceMonthly ?? null,
        features !== undefined ? JSON.stringify(normalizeFeatures(features)) : null,
        isActive ?? null,
        id,
      ]
    );

    const [sub] = await db.query('SELECT * FROM subscriptions WHERE id = ?', [id]);
    if (typeof sub.features === 'string') sub.features = JSON.parse(sub.features);
    res.json(sub);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function deleteSubscriptionPlan(req, res) {
  try {
    const id = req.params.id;
    const [existing] = await db.query('SELECT * FROM subscriptions WHERE id = ?', [id]);
    if (!existing) return res.status(404).json({ error: 'Subscription not found' });

    const payments = await db.query('SELECT id FROM payments WHERE subscription_id = ? LIMIT 1', [id]);
    if (payments.length) {
      return res.status(400).json({
        error: 'Cannot delete a plan with payment history. Deactivate it instead.',
      });
    }

    await db.query('DELETE FROM subscriptions WHERE id = ?', [id]);
    res.json({ message: 'Subscription deleted' });
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

async function getSettings(req, res) {
  try {
    const rows = await db.query('SELECT setting_key, setting_value FROM system_settings ORDER BY setting_key');
    const settings = {};
    rows.forEach((r) => { settings[r.setting_key] = r.setting_value; });
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function updateSettings(req, res) {
  try {
    const { settings } = req.body;
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ error: 'Settings object required' });
    }
    for (const [key, value] of Object.entries(settings)) {
      await db.query(
        `INSERT INTO system_settings (setting_key, setting_value) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE setting_value = ?`,
        [key, String(value), String(value)]
      );
    }
    res.json({ message: 'Settings updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  getDashboard,
  getStudentProgress,
  listSubscriptions,
  createSubscription,
  updateSubscriptionPlan,
  deleteSubscriptionPlan,
  createAnnouncement,
  getNotifications,
  markNotificationRead,
  getSettings,
  updateSettings,
};
