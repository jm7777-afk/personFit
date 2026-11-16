import { db } from '../config/database.js';

export class SavingsRepository {
  findAll() {
    return db.prepare(`
      SELECT *,
        ROUND((current_amount / target_amount) * 100, 1) as progress_percentage,
        MAX(0, target_amount - current_amount) as remaining_amount
      FROM savings_goals
      ORDER BY 
        CASE priority 
          WHEN 'alta' THEN 1 
          WHEN 'media' THEN 2 
          WHEN 'baja' THEN 3 
        END,
        created_at DESC
    `).all();
  }

  findById(id) {
    return db.prepare(`
      SELECT *,
        ROUND((current_amount / target_amount) * 100, 1) as progress_percentage,
        MAX(0, target_amount - current_amount) as remaining_amount
      FROM savings_goals
      WHERE id = ?
    `).get(id);
  }

  create(data) {
    const stmt = db.prepare(`
      INSERT INTO savings_goals (title, target_amount, current_amount, target_date, priority, notes)
      VALUES (@title, @target_amount, @current_amount, @target_date, @priority, @notes)
    `);
    const result = stmt.run({
      title: data.title,
      target_amount: data.target_amount,
      current_amount: data.current_amount || 0,
      target_date: data.target_date || null,
      priority: data.priority || 'media',
      notes: data.notes || null
    });
    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = this.findById(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE savings_goals
      SET title = @title, target_amount = @target_amount, current_amount = @current_amount,
          target_date = @target_date, priority = @priority, notes = @notes
      WHERE id = @id
    `);
    stmt.run({
      id,
      title: merged.title,
      target_amount: merged.target_amount,
      current_amount: merged.current_amount,
      target_date: merged.target_date,
      priority: merged.priority,
      notes: merged.notes
    });
    return this.findById(id);
  }

  delete(id) {
    const stmt = db.prepare('DELETE FROM savings_goals WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  recordTransaction(goalId, txData) {
    const transaction = db.transaction(() => {
      const goal = this.findById(goalId);
      if (!goal) return null;

      // 1. Registrar transacción
      const stmtTx = db.prepare(`
        INSERT INTO savings_transactions (goal_id, amount, date, notes)
        VALUES (@goal_id, @amount, @date, @notes)
      `);
      stmtTx.run({
        goal_id: goalId,
        amount: txData.amount,
        date: txData.date,
        notes: txData.notes || null
      });

      // 2. Actualizar monto actual en la meta
      const newAmount = Math.max(0, goal.current_amount + txData.amount);
      const stmtUpdate = db.prepare('UPDATE savings_goals SET current_amount = ? WHERE id = ?');
      stmtUpdate.run(newAmount, goalId);

      return this.findById(goalId);
    });

    return transaction();
  }

  getTransactions(goalId) {
    return db.prepare(`
      SELECT * FROM savings_transactions
      WHERE goal_id = ?
      ORDER BY date DESC, created_at DESC
    `).all(goalId);
  }

  getTotalSavings() {
    const row = db.prepare(`
      SELECT COALESCE(SUM(current_amount), 0) as total
      FROM savings_goals
    `).get();
    return row ? row.total : 0;
  }
}

export const savingsRepository = new SavingsRepository();
