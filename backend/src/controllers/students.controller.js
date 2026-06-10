const db = require('../config/database');

async function listStudents(req, res) {
  try {
    const students = await db.query(
      `SELECT u.id, u.email, u.first_name, u.last_name, u.is_active, u.created_at,
              s.id AS student_id, s.grade_level, s.class_name, s.subscription_plan, s.total_xp
       FROM users u
       JOIN students s ON s.user_id = u.id
       ORDER BY u.created_at DESC`
    );
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getStudent(req, res) {
  try {
    const [student] = await db.query(
      `SELECT u.id, u.email, u.first_name, u.last_name, u.is_active,
              s.id AS student_id, s.grade_level, s.class_name, s.subscription_plan, s.total_xp
       FROM users u
       JOIN students s ON s.user_id = u.id
       WHERE u.id = ?`,
      [req.params.id]
    );
    if (!student) return res.status(404).json({ error: 'Student not found' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function updateStudent(req, res) {
  try {
    const { firstName, lastName, gradeLevel, className, isActive } = req.body;
    const userId = req.params.id;

    if (firstName || lastName || isActive !== undefined) {
      await db.query(
        'UPDATE users SET first_name = COALESCE(?, first_name), last_name = COALESCE(?, last_name), is_active = COALESCE(?, is_active) WHERE id = ?',
        [firstName, lastName, isActive, userId]
      );
    }
    if (gradeLevel || className) {
      await db.query(
        'UPDATE students SET grade_level = COALESCE(?, grade_level), class_name = COALESCE(?, class_name) WHERE user_id = ?',
        [gradeLevel, className, userId]
      );
    }

    const [student] = await db.query(
      `SELECT u.id, u.email, u.first_name, u.last_name, u.is_active,
              s.grade_level, s.class_name
       FROM users u JOIN students s ON s.user_id = u.id WHERE u.id = ?`,
      [userId]
    );
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function deleteStudent(req, res) {
  try {
    await db.query('DELETE FROM users WHERE id = ? AND role = ?', [req.params.id, 'student']);
    res.json({ message: 'Student deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getMyProgress(req, res) {
  try {
    const [studentRow] = await db.query(
      'SELECT id, total_xp FROM students WHERE user_id = ?',
      [req.user.id]
    );
    if (!studentRow) return res.status(404).json({ error: 'Student profile not found' });

    const enrollments = await db.query(
      `SELECT e.*, c.title, c.thumbnail_url
       FROM enrollments e
       JOIN courses c ON c.id = e.course_id
       WHERE e.student_id = ?`,
      [studentRow.id]
    );

    const quizResults = await db.query(
      `SELECT qr.*, q.title AS quiz_title
       FROM quiz_results qr
       JOIN quizzes q ON q.id = qr.quiz_id
       WHERE qr.student_id = ?
       ORDER BY qr.submitted_at DESC LIMIT 10`,
      [studentRow.id]
    );

    res.json({ enrollments, quizResults, totalXp: studentRow.total_xp || 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = { listStudents, getStudent, updateStudent, deleteStudent, getMyProgress };
