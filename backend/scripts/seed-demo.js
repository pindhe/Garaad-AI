require('dotenv').config();
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const config = require('../src/config');

async function seedDemo() {
  const conn = await mysql.createConnection({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database,
  });

  const [courses] = await conn.execute('SELECT id FROM courses LIMIT 1');
  if (courses.length) {
    console.log('Demo data already exists');
    await conn.end();
    return;
  }

  const [courseResult] = await conn.execute(
    'INSERT INTO courses (title, description, subject, is_published) VALUES (?, ?, ?, TRUE)',
    ['Introduction to Mathematics', 'Learn algebra, equations, and problem solving step by step.', 'Mathematics']
  );
  const courseId = courseResult.insertId;

  const lessons = [
    ['What is Algebra?', 'Algebra is the branch of mathematics that uses letters and symbols to represent numbers and quantities in formulas and equations.', 0],
    ['Linear Equations', 'A linear equation is an equation where the highest power of the variable is 1. Example: 2x + 3 = 7.', 1],
    ['Quadratic Equations', 'A quadratic equation has the form ax² + bx + c = 0. We solve using factoring, completing the square, or the quadratic formula.', 2],
  ];

  for (const [title, content, order] of lessons) {
    await conn.execute(
      'INSERT INTO lessons (course_id, title, content, order_index, duration_minutes) VALUES (?, ?, ?, ?, 20)',
      [courseId, title, content, order]
    );
  }

  const quizQuestions = JSON.stringify([
    { type: 'mcq', question: 'What is the value of x in 2x + 3 = 7?', options: ['1', '2', '3', '4'], correct_answer: 1 },
    { type: 'true_false', question: 'A linear equation has a variable with power 2.', correct_answer: false },
    { type: 'mcq', question: 'Which is a quadratic equation?', options: ['x + 2 = 5', 'x² - 4 = 0', '3x = 9', 'x/2 = 1'], correct_answer: 1 },
  ]);

  await conn.execute(
    'INSERT INTO quizzes (course_id, title, questions, time_limit_minutes) VALUES (?, ?, ?, 15)',
    [courseId, 'Algebra Basics Quiz', quizQuestions]
  );

  const examQuestions = JSON.stringify([
    { type: 'mcq', question: 'Solve: 3x - 5 = 10', options: ['3', '5', '7', '15'], correct_answer: 1 },
    { type: 'mcq', question: 'Factor: x² - 9', options: ['(x-3)(x+3)', '(x-9)(x+1)', '(x-3)²', 'x(x-9)'], correct_answer: 0 },
    { type: 'true_false', question: 'Every quadratic has two real roots.', correct_answer: false },
  ]);

  await conn.execute(
    'INSERT INTO exams (course_id, title, questions, time_limit_minutes, is_published) VALUES (?, ?, ?, 30, TRUE)',
    [courseId, 'Midterm Exam', examQuestions]
  );

  await conn.execute(
    'INSERT INTO assignments (course_id, title, description, max_score) VALUES (?, ?, ?, 100)',
    [courseId, 'Algebra Problem Set', 'Solve 5 linear equations and explain your steps. Submit your work as text or PDF.']
  );

  console.log('Demo course created with lessons, quiz, exam, and assignment (course id:', courseId, ')');
  await conn.end();
}

seedDemo().catch((err) => {
  console.error('Demo seed failed:', err.message || err);
  console.error('Make sure XAMPP MySQL is running, then run: npm run db:init && npm run seed:demo');
  process.exit(1);
});
