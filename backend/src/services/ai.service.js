const OpenAI = require('openai');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const db = require('../config/database');

let openai = null;

function getClient() {
  if (!openai && config.openai.apiKey) {
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
  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');
  if (!(await isAiEnabled())) throw new Error('AI Teacher is currently disabled');

  const systemPrompt = await getSystemPrompt();
  const fullMessages = [
    { role: 'system', content: systemPrompt },
    ...messages,
  ];

  const response = await client.chat.completions.create({
    model: config.openai.model,
    messages: fullMessages,
    temperature: 0.7,
    max_tokens: 2000,
  });

  const content = response.choices[0].message.content;
  await logAiAction(userId, 'chat', response.usage, config.openai.model, { context }, content);

  return { content, usage: response.usage };
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
  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');

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

  const response = await client.chat.completions.create({
    model: config.openai.model,
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.3,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0].message.content;
  await logAiAction(userId, 'grade', response.usage, config.openai.model, { maxScore }, content);

  return JSON.parse(content);
}

async function gradeQuizAnswers(questions, studentAnswers, userId) {
  const client = getClient();
  if (!client) throw new Error('OpenAI API key not configured');

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

  const response = await client.chat.completions.create({
    model: config.openai.model,
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.2,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0].message.content;
  await logAiAction(userId, 'grade_quiz', response.usage, config.openai.model, {}, content);

  return JSON.parse(content);
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
