const express = require('express');
const authController = require('../controllers/auth.controller');
const { authenticate, authorize } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

router.post('/register', authController.registerValidation, authController.register);
router.post('/login', authLimiter, authController.loginValidation, authController.login);
router.get('/me', authenticate, authController.me);

module.exports = router;
