const { body } = require('express-validator');
const authService = require('../services/auth.service');
const { validate } = require('../middleware/validate');

async function register(req, res) {
  try {
    const { email, password, firstName, lastName, role, gradeLevel, className } = req.body;
    const user = await authService.register({
      email,
      password,
      firstName,
      lastName,
      role: role || 'student',
      gradeLevel,
      className,
    });
    res.status(201).json({ message: 'Registration successful', user });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    res.json(result);
  } catch (err) {
    res.status(401).json({ error: err.message });
  }
}

async function me(req, res) {
  try {
    const user = await authService.getUserById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('firstName').trim().notEmpty(),
  body('lastName').trim().notEmpty(),
  validate,
];

const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  validate,
];

module.exports = { register, login, me, registerValidation, loginValidation };
