const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');
const config = require('./config');
const { apiLimiter } = require('./middleware/rateLimiter');

const authRoutes = require('./routes/auth.routes');
const studentsRoutes = require('./routes/students.routes');
const coursesRoutes = require('./routes/courses.routes');
const lessonsRoutes = require('./routes/lessons.routes');
const aiRoutes = require('./routes/ai.routes');
const examsRoutes = require('./routes/exams.routes');
const assignmentsRoutes = require('./routes/assignments.routes');
const analyticsRoutes = require('./routes/analytics.routes');

const uploadDir = path.join(__dirname, '..', config.upload.dir);
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

const corsOptions =
  config.nodeEnv === 'development'
    ? {
        origin: (origin, callback) => {
          if (
            !origin ||
            /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin) ||
            origin === config.corsOrigin
          ) {
            callback(null, true);
          } else {
            callback(null, true);
          }
        },
        credentials: true,
      }
    : { origin: config.corsOrigin, credentials: true };

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(apiLimiter);
app.use('/uploads', express.static(uploadDir));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'MacallinAI API', version: '1.0.0' });
});

app.use('/auth', authRoutes);
app.use('/students', studentsRoutes);
app.use('/courses', coursesRoutes);
app.use('/lessons', lessonsRoutes);
app.use('/ai', aiRoutes);
app.use('/exams', examsRoutes);
app.use('/assignments', assignmentsRoutes);
app.use('/analytics', analyticsRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

module.exports = app;
