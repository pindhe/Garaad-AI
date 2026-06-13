const db = require('../config/database');

async function getLesson(req, res) {
  try {
    const [lesson] = await db.query('SELECT * FROM lessons WHERE id = ?', [req.params.id]);
    if (!lesson) return res.status(404).json({ error: 'Lesson not found' });

    if (lesson.examples && typeof lesson.examples === 'string') {
      try { lesson.examples = JSON.parse(lesson.examples); } catch { lesson.examples = []; }
    }
    if (lesson.slides && typeof lesson.slides === 'string') {
      try { lesson.slides = JSON.parse(lesson.slides); } catch { lesson.slides = []; }
    }

    const [course] = await db.query('SELECT id, title, subject FROM courses WHERE id = ?', [lesson.course_id]);
    if (course) lesson.course = course;

    if (req.user?.role === 'student') {
      const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
      if (student) {
        const [prog] = await db.query(
          'SELECT is_completed, completed_at FROM lesson_progress WHERE student_id = ? AND lesson_id = ?',
          [student.id, lesson.id]
        );
        lesson.completed = prog?.is_completed === true || prog?.is_completed === 1;
        lesson.completed_at = prog?.completed_at || null;
      }
    }

    res.json(lesson);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createLesson(req, res) {
  try {
    const { courseId, title, content, examples, notes, slides, orderIndex, durationMinutes } = req.body;
    const result = await db.query(
      `INSERT INTO lessons (course_id, title, content, examples, notes, slides, order_index, duration_minutes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        courseId,
        title,
        content,
        JSON.stringify(examples || []),
        notes,
        JSON.stringify(slides || []),
        orderIndex || 0,
        durationMinutes || 15,
      ]
    );
    const [lesson] = await db.query('SELECT * FROM lessons WHERE id = ?', [result.insertId]);
    res.status(201).json(lesson);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function completeLesson(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(404).json({ error: 'Student profile not found' });

    await db.query(
      `INSERT INTO lesson_progress (student_id, lesson_id, is_completed, completed_at)
       VALUES (?, ?, TRUE, NOW())
       ON DUPLICATE KEY UPDATE is_completed = TRUE, completed_at = NOW()`,
      [student.id, req.params.id]
    );

    const [lesson] = await db.query('SELECT course_id FROM lessons WHERE id = ?', [req.params.id]);
    if (lesson) {
      const [progress] = await db.query(
        `SELECT COUNT(*) AS completed FROM lesson_progress lp
         JOIN lessons l ON l.id = lp.lesson_id
         WHERE lp.student_id = ? AND l.course_id = ? AND lp.is_completed = TRUE`,
        [student.id, lesson.course_id]
      );
      const [total] = await db.query(
        'SELECT COUNT(*) AS total FROM lessons WHERE course_id = ?',
        [lesson.course_id]
      );
      const percent = total.total > 0 ? (progress.completed / total.total) * 100 : 0;
      await db.query(
        'UPDATE enrollments SET progress_percent = ? WHERE student_id = ? AND course_id = ?',
        [percent, student.id, lesson.course_id]
      );
      if (percent >= 100) {
        await db.query(
          'UPDATE enrollments SET completed_at = NOW() WHERE student_id = ? AND course_id = ?',
          [student.id, lesson.course_id]
        );
      }
      await db.query('UPDATE students SET total_xp = total_xp + 10 WHERE id = ?', [student.id]);
    }

    res.json({ message: 'Lesson completed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = { getLesson, createLesson, completeLesson };
