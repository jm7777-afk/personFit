import { db } from '../config/database.js';

export class CategoryRepository {
  findAll(type = null) {
    let sql = 'SELECT * FROM categories';
    const params = [];
    if (type) {
      sql += ' WHERE type = ?';
      params.push(type);
    }
    sql += ' ORDER BY name ASC';
    return db.prepare(sql).all(...params);
  }

  findById(id) {
    return db.prepare('SELECT * FROM categories WHERE id = ?').get(id);
  }

  findByName(name) {
    return db.prepare('SELECT * FROM categories WHERE name = ?').get(name);
  }

  create(data) {
    const stmt = db.prepare(`
      INSERT INTO categories (name, type, icon, monthly_budget)
      VALUES (@name, @type, @icon, @monthly_budget)
    `);
    const result = stmt.run({
      name: data.name,
      type: data.type,
      icon: data.icon || 'tag',
      monthly_budget: data.monthly_budget || 0
    });
    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = this.findById(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE categories
      SET name = @name, type = @type, icon = @icon, monthly_budget = @monthly_budget
      WHERE id = @id
    `);
    stmt.run({
      id,
      name: merged.name,
      type: merged.type,
      icon: merged.icon,
      monthly_budget: merged.monthly_budget
    });
    return this.findById(id);
  }

  delete(id) {
    const stmt = db.prepare('DELETE FROM categories WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }
}

export const categoryRepository = new CategoryRepository();
