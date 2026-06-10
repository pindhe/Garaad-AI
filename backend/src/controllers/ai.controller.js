const aiService = require('../services/ai.service');
const db = require('../config/database');

async function chat(req, res) {
  try {
    const { message, sessionId, history = [] } = req.body;
    if (!message) return res.status(400).json({ error: 'Message is required' });

    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const sid = sessionId || aiService.newSessionId();
    const messages = [
      ...history.map((h) => ({ role: h.role, content: h.content })),
      { role: 'user', content: message },
    ];

    const result = await aiService.chat(messages, req.user.id);

    await db.query(
      'INSERT INTO ai_chats (student_id, session_id, role, content) VALUES (?, ?, ?, ?), (?, ?, ?, ?)',
      [student.id, sid, 'user', message, student.id, sid, 'assistant', result.content]
    );

    res.json({ reply: result.content, sessionId: sid, usage: result.usage });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function generateCourse(req, res) {
  try {
    const { subject, level, topics } = req.body;
    if (!subject || !topics?.length) {
      return res.status(400).json({ error: 'Subject and topics are required' });
    }

    const generated = await aiService.generateCourse(subject, level || 'beginner', topics, req.user.id);

    const courseResult = await db.query(
      'INSERT INTO courses (title, description, subject, is_published, created_by, ai_generated) VALUES (?, ?, ?, FALSE, ?, TRUE)',
      [generated.title, generated.description, subject, req.user.id]
    );
    const courseId = courseResult.insertId;

    for (let i = 0; i < generated.lessons.length; i++) {
      const lesson = generated.lessons[i];
      await db.query(
        `INSERT INTO lessons (course_id, title, content, examples, notes, order_index, duration_minutes)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          courseId,
          lesson.title,
          lesson.content,
          JSON.stringify(lesson.examples || []),
          lesson.notes,
          i,
          lesson.duration_minutes || 15,
        ]
      );
    }

    if (generated.quiz) {
      await db.query(
        'INSERT INTO quizzes (course_id, title, questions) VALUES (?, ?, ?)',
        [courseId, generated.quiz.title, JSON.stringify(generated.quiz.questions)]
      );
    }

    res.status(201).json({ courseId, ...generated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function generateQuiz(req, res) {
  try {
    const { topic, count = 5, difficulty = 'medium', courseId, lessonId } = req.body;
    if (!topic) return res.status(400).json({ error: 'Topic is required' });

    const generated = await aiService.generateQuiz(topic, count, difficulty, req.user.id);

    const result = await db.query(
      'INSERT INTO quizzes (course_id, lesson_id, title, questions) VALUES (?, ?, ?, ?)',
      [courseId || null, lessonId || null, generated.title, JSON.stringify(generated.questions)]
    );

    res.status(201).json({ quizId: result.insertId, ...generated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function gradeSubmission(req, res) {
  try {
    const { content, rubric, maxScore = 100 } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });

    const result = await aiService.gradeSubmission(content, rubric || 'Standard grading', maxScore, req.user.id);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getAiStatus(req, res) {
  try {
    const enabled = await aiService.isAiEnabled();
    const systemPrompt = await aiService.getSystemPrompt();
    res.json({ enabled, systemPrompt });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function toggleAi(req, res) {
  try {
    const { enabled } = req.body;
    await db.query(
      `INSERT INTO system_settings (setting_key, setting_value) VALUES ('ai_teacher_enabled', ?)
       ON DUPLICATE KEY UPDATE setting_value = ?`,
      [String(enabled), String(enabled)]
    );
    res.json({ enabled });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getAiLogs(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 50;
    const logs = await db.query(
      `SELECT al.*, u.email, u.first_name, u.last_name
       FROM ai_logs al
       LEFT JOIN users u ON u.id = al.user_id
       ORDER BY al.created_at DESC LIMIT ?`,
      [limit]
    );
    res.json(logs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getChatHistory(req, res) {
  try {
    const [student] = await db.query('SELECT id FROM students WHERE user_id = ?', [req.user.id]);
    if (!student) return res.status(403).json({ error: 'Students only' });

    const chats = await db.query(
      'SELECT * FROM ai_chats WHERE student_id = ? AND session_id = ? ORDER BY created_at',
      [student.id, req.params.sessionId]
    );
    res.json(chats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  chat,
  generateCourse,
  generateQuiz,
  gradeSubmission,
  getAiStatus,
  toggleAi,
  getAiLogs,
  getChatHistory,
};
