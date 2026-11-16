import { db } from '../config/database.js';

export class IncomeRepository {
  findAll(filters = {}) {
    let sql = 'SELECT * FROM incomes WHERE 1=1';
    const params = [];

    if (filters.month) {
      sql += " AND strftime('%Y-%m', date) = ?";
      params.push(filters.month);
    }

    if (filters.source) {
      sql += ' AND source = ?';
      params.push(filters.source);
    }

    sql += ' ORDER BY date DESC';
    return db.prepare(sql).all(...params);
  }

  findById(id) {
    return db.prepare('SELECT * FROM incomes WHERE id = ?').get(id);
  }

  create(data) {
    const stmt = db.prepare(`
      INSERT INTO incomes (title, amount, source, frequency, date, notes)
      VALUES (@title, @amount, @source, @frequency, @date, @notes)
    `);
    const result = stmt.run({
      title: data.title,
      amount: data.amount,
      source: data.source,
      frequency: data.frequency,
      date: data.date,
      notes: data.notes || null
    });
    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = this.findById(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE incomes
      SET title = @title, amount = @amount, source = @source,
          frequency = @frequency, date = @date, notes = @notes
      WHERE id = @id
    `);
    stmt.run({
      id,
      title: merged.title,
      amount: merged.amount,
      source: merged.source,
      frequency: merged.frequency,
      date: merged.date,
      notes: merged.notes || null
    });
    return this.findById(id);
  }

  delete(id) {
    const stmt = db.prepare('DELETE FROM incomes WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  getTotalByMonth(yearMonth) {
    const row = db.prepare(`
      SELECT COALESCE(SUM(amount), 0) as total
      FROM incomes
      WHERE strftime('%Y-%m', date) = ?
    `).get(yearMonth);
    return row ? row.total : 0;
  }
}

export const incomeRepository = new IncomeRepository();
