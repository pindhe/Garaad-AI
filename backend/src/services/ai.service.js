const OpenAI = require('openai');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const db = require('../config/database');

let openai = null;

const PLACEHOLDER_KEY_PATTERN = /your.*key|sk-your|placeholder|change-me|xxx/i;

function isOpenAiConfigured() {
  const key = config.openai.apiKey;
  if (!key || key.trim().length < 20) return false;
  if (PLACEHOLDER_KEY_PATTERN.test(key)) return false;
  return true;
}

function gradeSubmissionLocal(submissionContent, rubric, maxScore) {
  const text = submissionContent.trim();
  const len = text.length;
  let score = Math.min(maxScore, Math.round(maxScore * 0.55));
  if (len > 80) score = Math.min(maxScore, Math.round(maxScore * 0.68));
  if (len > 250) score = Math.min(maxScore, Math.round(maxScore * 0.8));
  if (len > 600) score = Math.min(maxScore, Math.round(maxScore * 0.9));

  return {
    score,
    feedback:
      `Your submission was received (${len} characters).\n\n` +
      'Demo grading is active because OpenAI is not configured. ' +
      'Add a valid OPENAI_API_KEY to backend/.env for full AI feedback.\n\n' +
      `Assignment criteria: ${(rubric || 'Complete the task clearly.').slice(0, 300)}`,
    strengths: len > 120 ? ['Provided detailed written work'] : ['Submission recorded successfully'],
    improvements: ['Configure OPENAI_API_KEY in backend/.env for AI-powered grading'],
    demoMode: true,
  };
}

function getClient() {
  if (!isOpenAiConfigured()) return null;
  if (!openai) {
    openai = new OpenAI({ apiKey: config.openai.apiKey });
  }
  return openai;
}

async function getSystemPrompt() {
  const rows = await db.query(
    "SELECT setting_value FROM system_settings WHERE setting_key = 'ai_system_prompt'"
  );
  return rows[0]?.setting_value ||
    'You are MacallinAI, an expert autonomous AI teacher. Teach step-by-step with examples.';
}

async function isAiEnabled() {
  const rows = await db.query(
    "SELECT setting_value FROM system_settings WHERE setting_key = 'ai_teacher_enabled'"
  );
  if (rows[0]) return rows[0].setting_value === 'true';
  return config.aiTeacherEnabled;
}

async function logAiAction(userId, action, usage, model, requestData, responseSummary) {
  await db.query(
    `INSERT INTO ai_logs (user_id, action, prompt_tokens, completion_tokens, model, request_data, response_summary)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      action,
      usage?.prompt_tokens || 0,
      usage?.completion_tokens || 0,
      model,
      JSON.stringify(requestData),
      responseSummary?.slice(0, 500),
    ]
  );
}

async function chat(messages, userId, context = {}) {
  if (!isOpenAiConfigured()) {
    const last = messages.filter((m) => m.role === 'user').pop();
    return {
      content:
        'AI Teacher is in demo mode (OpenAI not configured). ' +
        `You asked: "${last?.content || ''}". ` +
        'Add a valid OPENAI_API_KEY to backend/.env for live answers.',
      usage: null,
      demoMode: true,
    };
  }

  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');
  if (!(await isAiEnabled())) throw new Error('AI Teacher is currently disabled');

  const systemPrompt = await getSystemPrompt();
  const fullMessages = [
    { role: 'system', content: systemPrompt },
    ...messages,
  ];

  try {
    const response = await client.chat.completions.create({
      model: config.openai.model,
      messages: fullMessages,
      temperature: 0.7,
      max_tokens: 2000,
    });

    const content = response.choices[0].message.content;
    await logAiAction(userId, 'chat', response.usage, config.openai.model, { context }, content);

    return { content, usage: response.usage };
  } catch (err) {
    const msg = err.message || String(err);
    if (/429|quota|rate limit|billing/i.test(msg)) {
      console.warn('[ai.service] OpenAI chat quota/rate limit:', msg.slice(0, 120));
      return {
        content:
          'AI Teacher is temporarily unavailable — your OpenAI account quota or rate limit was exceeded. ' +
          'Check billing at https://platform.openai.com/account/billing or try again later.',
        usage: null,
        demoMode: true,
      };
    }
    if (config.nodeEnv === 'development' || /401|API key|Incorrect API key/i.test(msg)) {
      return {
        content: 'AI Teacher demo mode: OpenAI request failed. Check OPENAI_API_KEY in backend/.env.',
        usage: null,
        demoMode: true,
      };
    }
    throw err;
  }
}

async function generateCourse(subject, level, topics, userId) {
  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');

  const prompt = `Generate a complete course structure for "${subject}" at ${level} level.
Topics to cover: ${topics.join(', ')}

Return valid JSON only:
{
  "title": "Course title",
  "description": "Course description",
  "lessons": [
    {
      "title": "Lesson title",
      "content": "Full lesson content with explanations",
      "examples": ["example1", "example2"],
      "notes": "Key notes summary",
      "duration_minutes": 20
    }
  ],
  "quiz": {
    "title": "Course quiz",
    "questions": [
      {
        "type": "mcq",
        "question": "Question text",
        "options": ["A", "B", "C", "D"],
        "correct_answer": 0
      }
    ]
  }
}`;

  const response = await client.chat.completions.create({
    model: config.openai.model,
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.7,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0].message.content;
  await logAiAction(userId, 'generate_course', response.usage, config.openai.model, { subject, level }, content);

  return JSON.parse(content);
}

async function generateQuiz(topic, count, difficulty, userId) {
  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');

  const prompt = `Generate ${count} ${difficulty} quiz questions about "${topic}".
Return valid JSON:
{
  "title": "Quiz title",
  "questions": [
    {
      "type": "mcq",
      "question": "Question",
      "options": ["A", "B", "C", "D"],
      "correct_answer": 0,
      "explanation": "Why this is correct"
    },
    {
      "type": "true_false",
      "question": "Statement",
      "correct_answer": true,
      "explanation": "Explanation"
    }
  ]
}`;

  const response = await client.chat.completions.create({
    model: config.openai.model,
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.7,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0].message.content;
  await logAiAction(userId, 'generate_quiz', response.usage, config.openai.model, { topic, count }, content);

  return JSON.parse(content);
}

async function gradeSubmission(submissionContent, rubric, maxScore, userId) {
  if (!isOpenAiConfigured()) {
    return gradeSubmissionLocal(submissionContent, rubric, maxScore);
  }

  const client = getClient();
  if (!client) return gradeSubmissionLocal(submissionContent, rubric, maxScore);

  const prompt = `Grade this student submission out of ${maxScore}.

Rubric: ${rubric}

Submission:
${submissionContent}

Return valid JSON:
{
  "score": 85,
  "feedback": "Detailed constructive feedback",
  "strengths": ["strength1"],
  "improvements": ["improvement1"]
}`;

  try {
    const response = await client.chat.completions.create({
      model: config.openai.model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0].message.content;
    await logAiAction(userId, 'grade', response.usage, config.openai.model, { maxScore }, content);

    return JSON.parse(content);
  } catch (err) {
    const msg = err.message || String(err);
    if (config.nodeEnv === 'development' || /401|429|quota|API key|Incorrect API key|rate limit/i.test(msg)) {
      console.warn('[ai.service] OpenAI grading unavailable, using demo grader:', msg.slice(0, 120));
      return gradeSubmissionLocal(submissionContent, rubric, maxScore);
    }
    throw err;
  }
}

function gradeQuizAnswersLocal(questions, studentAnswers) {
  let correct = 0;
  const details = [];

  questions.forEach((q, i) => {
    const expected = q.correct_answer;
    const ans = studentAnswers[i];
    const isCorrect = expected !== undefined && ans === expected;
    if (isCorrect) correct += 1;
    details.push({
      question_index: i,
      correct: isCorrect,
      explanation: isCorrect ? 'Correct answer!' : 'Review this topic in the lesson.',
    });
  });

  const total = questions.length;
  const score = total > 0 ? Math.round((correct / total) * 100) : 0;

  return {
    score,
    total: 100,
    correct_count: correct,
    feedback:
      `You scored ${correct}/${total} (${score}%). ` +
      (score >= 70 ? 'Great work!' : 'Keep studying and try again.'),
    details,
    demoMode: true,
  };
}

async function gradeQuizAnswers(questions, studentAnswers, userId) {
  if (!isOpenAiConfigured()) {
    return gradeQuizAnswersLocal(questions, studentAnswers);
  }

  const client = getClient();
  if (!client) return gradeQuizAnswersLocal(questions, studentAnswers);

  const prompt = `Grade these quiz answers. Questions: ${JSON.stringify(questions)}
Student answers: ${JSON.stringify(studentAnswers)}

Return valid JSON:
{
  "score": 75,
  "total": 100,
  "correct_count": 3,
  "feedback": "Overall feedback",
  "details": [{"question_index": 0, "correct": true, "explanation": "..."}]
}`;

  try {
    const response = await client.chat.completions.create({
      model: config.openai.model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0].message.content;
    await logAiAction(userId, 'grade_quiz', response.usage, config.openai.model, {}, content);

    return JSON.parse(content);
  } catch (err) {
    const msg = err.message || String(err);
    if (config.nodeEnv === 'development' || /401|429|quota|API key|Incorrect API key|rate limit/i.test(msg)) {
      console.warn('[ai.service] OpenAI quiz grading fallback:', msg.slice(0, 120));
      return gradeQuizAnswersLocal(questions, studentAnswers);
    }
    throw err;
  }
}

function newSessionId() {
  return uuidv4();
}

module.exports = {
  chat,
  generateCourse,
  generateQuiz,
  gradeSubmission,
  gradeQuizAnswers,
  isAiEnabled,
  newSessionId,
  getSystemPrompt,
};
