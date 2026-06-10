const db = require('../config/database');

async function listCourses(req, res) {
  try {
    const isAdmin = req.user?.role === 'admin';
    const sql = isAdmin
      ? 'SELECT * FROM courses ORDER BY created_at DESC'
      : 'SELECT * FROM courses WHERE is_published = TRUE ORDER BY created_at DESC';
    const courses = await db.query(sql);
    res.json(courses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getCourse(req, res) {
  try {
    const [course] = await db.query('SELECT * FROM courses WHERE id = ?', [req.params.id]);
    if (!course) return res.status(404).json({ error: 'Course not found' });

    const lessons = await db.query(
      'SELECT id, title, order_index, duration_minutes FROM lessons WHERE course_id = ? ORDER BY order_index',
      [course.id]
    );
    res.json({ ...course, lessons });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createCourse(req, res) {
  try {
    const { title, description, subject, thumbnailUrl, isPublished } = req.body;
    const result = await db.query(
      'INSERT INTO courses (title, description, subject, thumbnail_url, is_published, created_by) VALUES (?, ?, ?, ?, ?, ?)',
      [title, description, subject, thumbnailUrl, isPublished ?? false, req.user.id]
    );
    const [course] = await db.query('SELECT * FROM courses WHERE id = ?', [result.insertId]);
    res.status(201).json(course);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function updateCourse(req, res) {
  try {
    const { title, description, subject, thumbnailUrl, isPublished } = req.body;
    await db.query(
      `UPDATE courses SET title = COALESCE(?, title), description = COALESCE(?, description),
       subject = COALESCE(?, subject), thumbnail_url = COALESCE(?, thumbnail_url),
       is_published = COALESCE(?, is_published) WHERE id = ?`,
      [title, description, subject, thumbnailUrl, isPublished, req.params.id]
    );
    const [course] = await db.query('SELECT * FROM courses WHERE id = ?', [req.params.id]);
    res.json(course);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function deleteCourse(req, res) {
  try {
    await db.query('DELETE FROM courses WHERE id = ?', [req.params.id]);
    res.json({ message: 'Course deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function enrollCourse(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(404).json({ error: 'Student profile not found' });

    await db.query(
      'INSERT IGNORE INTO enrollments (student_id, course_id) VALUES (?, ?)',
      [student.id, req.params.id]
    );
    res.status(201).json({ message: 'Enrolled successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function listSubjects(req, res) {
  try {
    const subjects = await db.query('SELECT * FROM subjects ORDER BY name');
    res.json(subjects);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  listCourses,
  getCourse,
  createCourse,
  updateCourse,
  deleteCourse,
  enrollCourse,
  listSubjects,
};
