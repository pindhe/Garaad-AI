const express = require('express');
const studentsController = require('../controllers/students.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/progress', authenticate, authorize('student'), studentsController.getMyProgress);
router.get('/', authenticate, authorize('admin'), studentsController.listStudents);
router.get('/:id', authenticate, authorize('admin'), studentsController.getStudent);
router.put('/:id', authenticate, authorize('admin'), studentsController.updateStudent);
router.delete('/:id', authenticate, authorize('admin'), studentsController.deleteStudent);

module.exports = router;
