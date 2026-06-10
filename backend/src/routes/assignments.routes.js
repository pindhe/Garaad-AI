const express = require('express');
const multer = require('multer');
const path = require('path');
const assignmentsController = require('../controllers/assignments.controller');
const { authenticate, authorize } = require('../middleware/auth');
const config = require('../config');

const storage = multer.diskStorage({
  destination: config.upload.dir,
  filename: (_req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: config.upload.maxSize },
  fileFilter: (_req, file, cb) => {
    const allowed = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, allowed.includes(ext));
  },
});

const router = express.Router();

router.use(authenticate);

router.get('/', assignmentsController.listAssignments);
router.get('/submissions', authorize('admin'), assignmentsController.listSubmissions);
router.post('/', authorize('admin'), assignmentsController.createAssignment);
router.post('/:id/submit', authorize('student'), upload.single('file'), assignmentsController.submitAssignment);

module.exports = router;
