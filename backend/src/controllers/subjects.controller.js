const db = require('../config/database');

async function listCategories(req, res) {
  try {
    const activeOnly = req.query.active === 'true';
    const sql = `
      SELECT s.id, s.name, s.description, s.icon, s.is_active, s.created_at,
             COUNT(DISTINCT c.id) AS course_count,
             COUNT(DISTINCT l.id) AS lesson_count
      FROM subjects s
      LEFT JOIN courses c ON c.subject = s.name
      LEFT JOIN lessons l ON l.course_id = c.id
      ${activeOnly ? 'WHERE s.is_active = TRUE' : ''}
      GROUP BY s.id, s.name, s.description, s.icon, s.is_active, s.created_at
      ORDER BY s.name
    `;
    const rows = await db.query(sql);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getCategory(req, res) {
  try {
    const [row] = await db.query(
      `SELECT s.id, s.name, s.description, s.icon, s.is_active, s.created_at,
              COUNT(DISTINCT c.id) AS course_count,
              COUNT(DISTINCT l.id) AS lesson_count
       FROM subjects s
       LEFT JOIN courses c ON c.subject = s.name
       LEFT JOIN lessons l ON l.course_id = c.id
       WHERE s.id = ?
       GROUP BY s.id, s.name, s.description, s.icon, s.is_active, s.created_at`,
      [req.params.id]
    );
    if (!row) return res.status(404).json({ error: 'Category not found' });

    const courses = await db.query(
      `SELECT c.id, c.title, c.is_published,
              (SELECT COUNT(*) FROM lessons WHERE course_id = c.id) AS lesson_count
       FROM courses c WHERE c.subject = ? ORDER BY c.created_at DESC`,
      [row.name]
    );
    res.json({ ...row, courses });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function createCategory(req, res) {
  try {
    const { name, description, icon, isActive } = req.body;
    if (!name?.trim()) return res.status(400).json({ error: 'Category name is required' });

    const result = await db.query(
      'INSERT INTO subjects (name, description, icon, is_active) VALUES (?, ?, ?, ?)',
      [name.trim(), description || null, icon || 'book', isActive ?? true]
    );
    const [row] = await db.query('SELECT * FROM subjects WHERE id = ?', [result.insertId]);
    res.status(201).json(row);
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'A category with this name already exists' });
    }
    res.status(500).json({ error: err.message });
  }
}

async function updateCategory(req, res) {
  try {
    const { name, description, icon, isActive } = req.body;
    const id = req.params.id;

    const [existing] = await db.query('SELECT * FROM subjects WHERE id = ?', [id]);
    if (!existing) return res.status(404).json({ error: 'Category not found' });

    await db.query(
      `UPDATE subjects SET
         name = COALESCE(?, name),
         description = COALESCE(?, description),
         icon = COALESCE(?, icon),
         is_active = COALESCE(?, is_active)
       WHERE id = ?`,
      [name?.trim() || null, description ?? null, icon || null, isActive ?? null, id]
    );

    if (name && name !== existing.name) {
      await db.query('UPDATE courses SET subject = ? WHERE subject = ?', [name.trim(), existing.name]);
    }

    const [row] = await db.query('SELECT * FROM subjects WHERE id = ?', [id]);
    res.json(row);
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'A category with this name already exists' });
    }
    res.status(500).json({ error: err.message });
  }
}

async function deleteCategory(req, res) {
  try {
    const id = req.params.id;
    const [existing] = await db.query('SELECT * FROM subjects WHERE id = ?', [id]);
    if (!existing) return res.status(404).json({ error: 'Category not found' });

    const courses = await db.query('SELECT id FROM courses WHERE subject = ? LIMIT 1', [existing.name]);
    if (courses.length) {
      return res.status(400).json({
        error: 'Category has linked courses. Deactivate it instead of deleting.',
      });
    }

    await db.query('DELETE FROM subjects WHERE id = ?', [id]);
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  listCategories,
  getCategory,
  createCategory,
  updateCategory,
  deleteCategory,
};
