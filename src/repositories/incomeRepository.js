import { db } from '../config/database.js';

export class IncomeRepository {
  findAll(filters = {}, userId = null) {
    let sql = 'SELECT * FROM incomes WHERE 1=1';
    const params = [];

    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }

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

  findById(id, userId = null) {
    let sql = 'SELECT * FROM incomes WHERE id = ?';
    const params = [id];
    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }
    return db.prepare(sql).get(...params);
  }

  create(data, userId = null) {
    const stmt = db.prepare(`
      INSERT INTO incomes (title, amount, source, frequency, date, notes, user_id, currency, next_payout_date, day_of_month)
      VALUES (@title, @amount, @source, @frequency, @date, @notes, @user_id, @currency, @next_payout_date, @day_of_month)
    `);
    const result = stmt.run({
      title: data.title,
      amount: data.amount,
      source: data.source,
      frequency: data.frequency || 'mensual',
      date: data.date,
      notes: data.notes || null,
      user_id: userId,
      currency: data.currency || 'USD',
      next_payout_date: data.next_payout_date || null,
      day_of_month: data.day_of_month || null
    });
    return this.findById(result.lastInsertRowid);
  }

  update(id, data, userId = null) {
    const current = this.findById(id, userId);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE incomes
      SET title = @title, amount = @amount, source = @source,
          frequency = @frequency, date = @date, notes = @notes,
          currency = @currency, next_payout_date = @next_payout_date, day_of_month = @day_of_month
      WHERE id = @id
    `);
    stmt.run({
      id,
      title: merged.title,
      amount: merged.amount,
      source: merged.source,
      frequency: merged.frequency,
      date: merged.date,
      notes: merged.notes || null,
      currency: merged.currency || 'USD',
      next_payout_date: merged.next_payout_date || null,
      day_of_month: merged.day_of_month || null
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
