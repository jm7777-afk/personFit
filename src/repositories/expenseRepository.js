import { db } from '../config/database.js';

export class ExpenseRepository {
  findAll(filters = {}) {
    let sql = `
      SELECT e.*, c.name as category_name, c.type as category_type, c.icon as category_icon, c.monthly_budget
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE 1=1
    `;
    const params = [];

    if (filters.month) {
      sql += " AND strftime('%Y-%m', e.date) = ?";
      params.push(filters.month);
    }

    if (filters.category_id) {
      sql += ' AND e.category_id = ?';
      params.push(filters.category_id);
    }

    if (filters.is_paid !== undefined && filters.is_paid !== null) {
      sql += ' AND e.is_paid = ?';
      params.push(filters.is_paid);
    }

    if (filters.type) {
      sql += ' AND c.type = ?';
      params.push(filters.type);
    }

    if (filters.period) {
      const p = String(filters.period).toLowerCase();
      if (p === 'diario' || p === 'today') {
        sql += " AND date(e.date) = date('now', 'localtime')";
      } else if (p === 'semanal' || p === 'week') {
        sql += " AND date(e.date) >= date('now', '-6 days', 'localtime')";
      } else if (p === 'mensual' || p === 'month') {
        sql += " AND strftime('%Y-%m', e.date) = strftime('%Y-%m', 'now', 'localtime')";
      }
    }

    sql += ' ORDER BY e.date DESC, e.created_at DESC';
    return db.prepare(sql).all(...params);
  }

  findById(id) {
    const sql = `
      SELECT e.*, c.name as category_name, c.type as category_type, c.icon as category_icon, c.monthly_budget
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.id = ?
    `;
    return db.prepare(sql).get(id);
  }

  create(data) {
    const stmt = db.prepare(`
      INSERT INTO expenses (
        title, amount, category_id, date, due_date, is_paid, payment_method, currency, notes, user_id
      ) VALUES (
        @title, @amount, @category_id, @date, @due_date, @is_paid, @payment_method, @currency, @notes, @user_id
      )
    `);

    const result = stmt.run({
      title: data.title,
      amount: data.amount,
      category_id: data.category_id,
      date: data.date,
      due_date: data.due_date || null,
      is_paid: data.is_paid !== undefined ? data.is_paid : 1,
      payment_method: data.payment_method || 'efectivo',
      currency: data.currency || 'USD',
      notes: data.notes || null,
      user_id: data.user_id || null
    });

    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = this.findById(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE expenses
      SET title = @title, amount = @amount, category_id = @category_id,
          date = @date, due_date = @due_date, is_paid = @is_paid,
          payment_method = @payment_method, notes = @notes
      WHERE id = @id
    `);

    stmt.run({
      id,
      title: merged.title,
      amount: merged.amount,
      category_id: merged.category_id,
      date: merged.date,
      due_date: merged.due_date,
      is_paid: merged.is_paid,
      payment_method: merged.payment_method,
      notes: merged.notes
    });

    return this.findById(id);
  }

  delete(id) {
    const stmt = db.prepare('DELETE FROM expenses WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  markAsPaid(id) {
    const stmt = db.prepare(`
      UPDATE expenses
      SET is_paid = 1
      WHERE id = ?
    `);
    stmt.run(id);
    return this.findById(id);
  }

  findUpcomingBills(days = 15) {
    const stmt = db.prepare(`
      SELECT e.*, c.name as category_name, c.icon as category_icon,
        CAST(julianday(e.due_date) - julianday('now') AS INTEGER) AS days_remaining
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.is_paid = 0
        AND e.due_date IS NOT NULL
        AND date(e.due_date) <= date('now', '+' || ? || ' days')
      ORDER BY e.due_date ASC
    `);
    return stmt.all(days);
  }

  getMonthlyTotalByCategory(yearMonth) {
    const stmt = db.prepare(`
      SELECT 
        c.id as category_id,
        c.name as category_name,
        c.type as category_type,
        c.icon as category_icon,
        c.monthly_budget,
        COALESCE(SUM(e.amount), 0) as total_spent
      FROM categories c
      LEFT JOIN expenses e ON c.id = e.category_id AND strftime('%Y-%m', e.date) = ?
      GROUP BY c.id
      ORDER BY total_spent DESC
    `);
    return stmt.all(yearMonth);
  }

  getTotalByMonth(yearMonth) {
    const row = db.prepare(`
      SELECT COALESCE(SUM(amount), 0) as total
      FROM expenses
      WHERE strftime('%Y-%m', date) = ?
    `).get(yearMonth);
    return row ? row.total : 0;
  }
}

export const expenseRepository = new ExpenseRepository();
