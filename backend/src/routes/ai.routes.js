const express = require('express');
const aiController = require('../controllers/ai.controller');
const { authenticate, authorize } = require('../middleware/auth');
const { aiLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

router.use(authenticate);

router.post('/chat', aiLimiter, authorize('student'), aiController.chat);
router.get('/chat/:sessionId', authorize('student'), aiController.getChatHistory);
router.post('/generate-course', aiLimiter, authorize('admin'), aiController.generateCourse);
router.post('/generate-quiz', aiLimiter, authorize('admin'), aiController.generateQuiz);
router.post('/grade', aiLimiter, authorize('admin'), aiController.gradeSubmission);
router.get('/status', aiController.getAiStatus);
router.put('/toggle', authorize('admin'), aiController.toggleAi);
router.get('/logs', authorize('admin'), aiController.getAiLogs);

module.exports = router;
