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
    const quizzes = await db.query(
      'SELECT id, title, time_limit_minutes, passing_score FROM quizzes WHERE course_id = ? ORDER BY created_at',
      [course.id]
    );
    const exams = await db.query(
      req.user?.role === 'admin'
        ? 'SELECT id, title, time_limit_minutes, passing_score, is_published FROM exams WHERE course_id = ? ORDER BY created_at'
        : 'SELECT id, title, time_limit_minutes, passing_score FROM exams WHERE course_id = ? AND is_published = TRUE ORDER BY created_at',
      [course.id]
    );
    const assignments = await db.query(
      'SELECT id, title, description, due_date, max_score FROM assignments WHERE course_id = ? ORDER BY created_at DESC',
      [course.id]
    );

    let enrollmentCount = 0;
    if (req.user?.role === 'admin') {
      const [{ count }] = await db.query(
        'SELECT COUNT(*) AS count FROM enrollments WHERE course_id = ?',
        [course.id]
      );
      enrollmentCount = count;
    }

    let enrollment = null;
    if (req.user?.role === 'student') {
      const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
      if (student) {
        const [row] = await db.query(
          'SELECT id, progress_percent, enrolled_at, completed_at FROM enrollments WHERE student_id = ? AND course_id = ?',
          [student.id, course.id]
        );
        enrollment = row || null;

        if (lessons.length) {
          const lessonIds = lessons.map((l) => l.id);
          const placeholders = lessonIds.map(() => '?').join(',');
          const progressRows = await db.query(
            `SELECT lesson_id, is_completed FROM lesson_progress
             WHERE student_id = ? AND lesson_id IN (${placeholders})`,
            [student.id, ...lessonIds]
          );
          const completedMap = {};
          progressRows.forEach((p) => {
            completedMap[p.lesson_id] = p.is_completed === true || p.is_completed === 1;
          });
          lessons.forEach((l) => {
            l.completed = completedMap[l.id] === true;
          });
        }
      }
    }

    res.json({ ...course, lessons, quizzes, exams, assignments, enrollmentCount, enrollment });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createCourse(req, res) {
  try {
    const { title, description, subject, categoryId, thumbnailUrl, isPublished } = req.body;
    if (!title?.trim()) return res.status(400).json({ error: 'Course title is required' });

    let subjectName = subject?.trim() || null;
    if (categoryId) {
      const [cat] = await db.query('SELECT id, name FROM subjects WHERE id = ?', [categoryId]);
      if (!cat) return res.status(400).json({ error: 'Category not found' });
      subjectName = cat.name;
    }

    const result = await db.query(
      'INSERT INTO courses (title, description, subject, thumbnail_url, is_published, created_by) VALUES (?, ?, ?, ?, ?, ?)',
      [
        title.trim(),
        description?.trim() || null,
        subjectName,
        thumbnailUrl?.trim() || null,
        isPublished ?? false,
        req.user.id,
      ]
    );

    if (categoryId) {
      await db.query(
        'INSERT IGNORE INTO course_subjects (course_id, subject_id) VALUES (?, ?)',
        [result.insertId, categoryId]
      );
    }

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
