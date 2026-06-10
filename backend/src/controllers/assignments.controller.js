const path = require('path');
const fs = require('fs');
const db = require('../config/database');
const aiService = require('../services/ai.service');
const config = require('../config');

async function listAssignments(req, res) {
  try {
    const courseId = req.query.courseId;
    const sql = courseId
      ? 'SELECT * FROM assignments WHERE course_id = ? ORDER BY created_at DESC'
      : 'SELECT * FROM assignments ORDER BY created_at DESC';
    const assignments = await db.query(sql, courseId ? [courseId] : []);
    res.json(assignments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createAssignment(req, res) {
  try {
    const { courseId, title, description, dueDate, maxScore } = req.body;
    const result = await db.query(
      'INSERT INTO assignments (course_id, title, description, due_date, max_score) VALUES (?, ?, ?, ?, ?)',
      [courseId, title, description, dueDate, maxScore || 100]
    );
    const [assignment] = await db.query('SELECT * FROM assignments WHERE id = ?', [result.insertId]);
    res.status(201).json(assignment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function submitAssignment(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const [assignment] = await db.query('SELECT * FROM assignments WHERE id = ?', [req.params.id]);
    if (!assignment) return res.status(404).json({ error: 'Assignment not found' });

    const content = req.body.content || '';
    const fileUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const result = await db.query(
      'INSERT INTO submissions (assignment_id, student_id, file_url, content, status) VALUES (?, ?, ?, ?, ?)',
      [assignment.id, student.id, fileUrl, content, 'pending']
    );

    const submissionContent = content || (fileUrl ? `File submitted: ${fileUrl}` : '');
    if (submissionContent) {
      const grade = await aiService.gradeSubmission(
        submissionContent,
        assignment.description || 'Grade based on completeness and accuracy',
        assignment.max_score,
        req.user.id
      );
      await db.query(
        'UPDATE submissions SET score = ?, ai_feedback = ?, status = ?, graded_at = NOW() WHERE id = ?',
        [grade.score, grade.feedback, 'graded', result.insertId]
      );
      return res.status(201).json({ submissionId: result.insertId, ...grade });
    }

    res.status(201).json({ submissionId: result.insertId, message: 'Submitted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function listSubmissions(req, res) {
  try {
    const assignmentId = req.query.assignmentId;
    const sql = assignmentId
      ? `SELECT s.*, u.first_name, u.last_name, u.email
         FROM submissions s
         JOIN students st ON st.id = s.student_id
         JOIN users u ON u.id = st.user_id
         WHERE s.assignment_id = ? ORDER BY s.submitted_at DESC`
      : `SELECT s.*, u.first_name, u.last_name, a.title AS assignment_title
         FROM submissions s
         JOIN students st ON st.id = s.student_id
         JOIN users u ON u.id = st.user_id
         JOIN assignments a ON a.id = s.assignment_id
         ORDER BY s.submitted_at DESC LIMIT 100`;
    const submissions = await db.query(sql, assignmentId ? [assignmentId] : []);
    res.json(submissions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = { listAssignments, createAssignment, submitAssignment, listSubmissions };
