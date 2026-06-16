const express = require('express');
const subjectsController = require('../controllers/subjects.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticate, subjectsController.listCategories);
router.get('/:id', authenticate, subjectsController.getCategory);
router.post('/', authenticate, authorize('admin'), subjectsController.createCategory);
router.put('/:id', authenticate, authorize('admin'), subjectsController.updateCategory);
router.delete('/:id', authenticate, authorize('admin'), subjectsController.deleteCategory);

module.exports = router;
