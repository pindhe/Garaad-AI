const express = require('express');
const coursesController = require('../controllers/courses.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/subjects/list', coursesController.listSubjects);
router.get('/', authenticate, coursesController.listCourses);
router.get('/:id', authenticate, coursesController.getCourse);
router.post('/', authenticate, authorize('admin'), coursesController.createCourse);
router.put('/:id', authenticate, authorize('admin'), coursesController.updateCourse);
router.delete('/:id', authenticate, authorize('admin'), coursesController.deleteCourse);
router.post('/:id/enroll', authenticate, authorize('student'), coursesController.enrollCourse);

module.exports = router;
