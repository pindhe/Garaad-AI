const express = require('express');
const lessonsController = require('../controllers/lessons.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/:id', authenticate, lessonsController.getLesson);
router.post('/', authenticate, authorize('admin'), lessonsController.createLesson);
router.post('/:id/complete', authenticate, authorize('student'), lessonsController.completeLesson);

module.exports = router;
