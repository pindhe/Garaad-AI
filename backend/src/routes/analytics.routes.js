const express = require('express');
const analyticsController = require('../controllers/analytics.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/dashboard', authorize('admin'), analyticsController.getDashboard);
router.get('/progress', authorize('admin'), analyticsController.getStudentProgress);
router.get('/subscriptions', analyticsController.listSubscriptions);
router.post('/announcements', authorize('admin'), analyticsController.createAnnouncement);
router.get('/notifications', analyticsController.getNotifications);
router.put('/notifications/:id/read', analyticsController.markNotificationRead);

module.exports = router;
