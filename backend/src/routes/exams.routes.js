const express = require('express');
const examsController = require('../controllers/exams.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/quizzes', examsController.listQuizzes);
router.get('/quizzes/:id', examsController.getQuiz);
router.post('/quizzes/:id/submit', authorize('student'), examsController.submitQuiz);
router.get('/certificates', authorize('student'), examsController.getCertificates);
router.post('/certificates/:courseId', authorize('student'), examsController.issueCertificate);
router.get('/', examsController.listExams);
router.get('/:id', examsController.getExam);
router.post('/', authorize('admin'), examsController.createExam);
router.post('/:id/submit', authorize('student'), examsController.submitExam);

module.exports = router;
