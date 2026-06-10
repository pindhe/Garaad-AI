const db = require('../config/database');
const aiService = require('../services/ai.service');
const { v4: uuidv4 } = require('uuid');

async function listExams(req, res) {
  try {
    const courseId = req.query.courseId;
    const sql = courseId
      ? 'SELECT * FROM exams WHERE course_id = ? ORDER BY created_at DESC'
      : 'SELECT * FROM exams ORDER BY created_at DESC';
    const exams = await db.query(sql, courseId ? [courseId] : []);
    exams.forEach((e) => {
      if (typeof e.questions === 'string') e.questions = JSON.parse(e.questions);
    });
    res.json(exams);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getExam(req, res) {
  try {
    const [exam] = await db.query('SELECT * FROM exams WHERE id = ?', [req.params.id]);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    if (typeof exam.questions === 'string') exam.questions = JSON.parse(exam.questions);

    if (req.user.role === 'student') {
      exam.questions = exam.questions.map((q) => {
        const { correct_answer, explanation, ...rest } = q;
        return rest;
      });
    }
    res.json(exam);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createExam(req, res) {
  try {
    const { courseId, title, questions, timeLimitMinutes, passingScore, startDate, endDate } = req.body;
    const result = await db.query(
      `INSERT INTO exams (course_id, title, questions, time_limit_minutes, passing_score, start_date, end_date)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [courseId, title, JSON.stringify(questions), timeLimitMinutes || 60, passingScore || 60, startDate, endDate]
    );
    const [exam] = await db.query('SELECT * FROM exams WHERE id = ?', [result.insertId]);
    res.status(201).json(exam);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function submitExam(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const [exam] = await db.query('SELECT * FROM exams WHERE id = ?', [req.params.id]);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });

    const questions = typeof exam.questions === 'string' ? JSON.parse(exam.questions) : exam.questions;
    const { answers, timeTakenSeconds } = req.body;

    const gradeResult = await aiService.gradeQuizAnswers(questions, answers, req.user.id);

    await db.query(
      `INSERT INTO exam_results (student_id, exam_id, score, answers, ai_feedback, time_taken_seconds)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [student.id, exam.id, gradeResult.score, JSON.stringify(answers), gradeResult.feedback, timeTakenSeconds]
    );

    res.json(gradeResult);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function listQuizzes(req, res) {
  try {
    const courseId = req.query.courseId;
    const sql = courseId
      ? 'SELECT id, course_id, lesson_id, title, time_limit_minutes, passing_score FROM quizzes WHERE course_id = ?'
      : 'SELECT id, course_id, lesson_id, title, time_limit_minutes, passing_score FROM quizzes';
    const quizzes = await db.query(sql, courseId ? [courseId] : []);
    res.json(quizzes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getQuiz(req, res) {
  try {
    const [quiz] = await db.query('SELECT * FROM quizzes WHERE id = ?', [req.params.id]);
    if (!quiz) return res.status(404).json({ error: 'Quiz not found' });
    if (typeof quiz.questions === 'string') quiz.questions = JSON.parse(quiz.questions);

    if (req.user.role === 'student') {
      quiz.questions = quiz.questions.map((q) => {
        const { correct_answer, explanation, ...rest } = q;
        return rest;
      });
    }
    res.json(quiz);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function submitQuiz(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const [quiz] = await db.query('SELECT * FROM quizzes WHERE id = ?', [req.params.id]);
    if (!quiz) return res.status(404).json({ error: 'Quiz not found' });

    const questions = typeof quiz.questions === 'string' ? JSON.parse(quiz.questions) : quiz.questions;
    const { answers, timeTakenSeconds } = req.body;

    const gradeResult = await aiService.gradeQuizAnswers(questions, answers, req.user.id);

    await db.query(
      `INSERT INTO quiz_results (student_id, quiz_id, score, answers, ai_feedback, time_taken_seconds)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [student.id, quiz.id, gradeResult.score, JSON.stringify(answers), gradeResult.feedback, timeTakenSeconds]
    );

    res.json(gradeResult);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getCertificates(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const certs = await db.query(
      `SELECT c.*, co.title AS course_title
       FROM certificates c
       JOIN courses co ON co.id = c.course_id
       WHERE c.student_id = ?`,
      [student.id]
    );
    res.json(certs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function issueCertificate(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const courseId = req.params.courseId;
    const [enrollment] = await db.query(
      'SELECT * FROM enrollments WHERE student_id = ? AND course_id = ? AND progress_percent >= 100',
      [student.id, courseId]
    );
    if (!enrollment) return res.status(400).json({ error: 'Course not completed' });

    const code = uuidv4().slice(0, 8).toUpperCase();
    await db.query(
      'INSERT INTO certificates (student_id, course_id, certificate_code) VALUES (?, ?, ?)',
      [student.id, courseId, code]
    );

    res.status(201).json({ certificateCode: code, message: 'Certificate issued' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  listExams,
  getExam,
  createExam,
  submitExam,
  listQuizzes,
  getQuiz,
  submitQuiz,
  getCertificates,
  issueCertificate,
};
