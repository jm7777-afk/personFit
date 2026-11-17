import { db } from '../config/database.js';

export class DebtRepository {
  findAll(status = null, userId = null) {
    let sql = 'SELECT * FROM debts WHERE 1=1';
    const params = [];

    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }

    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }

    sql += ' ORDER BY next_due_date ASC';
    return db.prepare(sql).all(...params);
  }

  findById(id, userId = null) {
    let sql = 'SELECT * FROM debts WHERE id = ?';
    const params = [id];
    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }
    return db.prepare(sql).get(...params);
  }

  create(data, userId = null) {
    const currentBalance = data.current_balance !== undefined ? data.current_balance : data.total_amount;
    const stmt = db.prepare(`
      INSERT INTO debts (
        title, creditor, total_amount, current_balance, monthly_payment,
        interest_rate, due_day, next_due_date, status, notes, user_id,
        currency, deduct_from_salary, is_borrowed
      ) VALUES (
        @title, @creditor, @total_amount, @current_balance, @monthly_payment,
        @interest_rate, @due_day, @next_due_date, @status, @notes, @user_id,
        @currency, @deduct_from_salary, @is_borrowed
      )
    `);

    const result = stmt.run({
      title: data.title,
      creditor: data.creditor,
      total_amount: data.total_amount,
      current_balance: currentBalance,
      monthly_payment: data.monthly_payment || currentBalance,
      interest_rate: data.interest_rate || 0,
      due_day: data.due_day || new Date().getDate(),
      next_due_date: data.next_due_date || new Date().toISOString().split('T')[0],
      status: data.status || 'activa',
      notes: data.notes || null,
      user_id: userId,
      currency: data.currency || 'USD',
      deduct_from_salary: data.deduct_from_salary ? 1 : 0,
      is_borrowed: data.is_borrowed ? 1 : 0
    });

    return this.findById(result.lastInsertRowid);
  }

  update(id, data, userId = null) {
    const current = this.findById(id, userId);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE debts
      SET title = @title, creditor = @creditor, total_amount = @total_amount,
          current_balance = @current_balance, monthly_payment = @monthly_payment,
          interest_rate = @interest_rate, due_day = @due_day,
          next_due_date = @next_due_date, status = @status, notes = @notes,
          currency = @currency, deduct_from_salary = @deduct_from_salary, is_borrowed = @is_borrowed
      WHERE id = @id
    `);

    stmt.run({
      id,
      title: merged.title,
      creditor: merged.creditor,
      total_amount: merged.total_amount,
      current_balance: merged.current_balance,
      monthly_payment: merged.monthly_payment,
      interest_rate: merged.interest_rate,
      due_day: merged.due_day,
      next_due_date: merged.next_due_date,
      status: merged.status,
      notes: merged.notes,
      currency: merged.currency || 'USD',
      deduct_from_salary: merged.deduct_from_salary ? 1 : 0,
      is_borrowed: merged.is_borrowed ? 1 : 0
    });

    return this.findById(id);
  }

  delete(id, userId = null) {
    let sql = 'DELETE FROM debts WHERE id = ?';
    const params = [id];
    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }
    const result = db.prepare(sql).run(...params);
    return result.changes > 0;
  }

  findUpcoming(days = 15, userId = null) {
    let sql = `
      SELECT *,
        CAST(julianday(next_due_date) - julianday('now') AS INTEGER) AS days_remaining
      FROM debts
      WHERE status = 'activa'
        AND date(next_due_date) <= date('now', '+' || ? || ' days')
    `;
    const params = [days];
    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }
    sql += ' ORDER BY next_due_date ASC';
    return db.prepare(sql).all(...params);
  }

  recordPayment(debtId, paymentData, userId = null) {
    const recordPaymentTx = db.transaction(() => {
      const debt = this.findById(debtId, userId);
      if (!debt) return null;

      // 1. Insertar el abono
      const stmtPayment = db.prepare(`
        INSERT INTO debt_payments (debt_id, amount, payment_date, notes)
        VALUES (@debt_id, @amount, @payment_date, @notes)
      `);
      stmtPayment.run({
        debt_id: debtId,
        amount: paymentData.amount,
        payment_date: paymentData.payment_date,
        notes: paymentData.notes || null
      });

      // 2. Actualizar el saldo de la deuda
      const newBalance = Math.max(0, debt.current_balance - paymentData.amount);
      const isPaidNow = newBalance === 0;
      const newStatus = isPaidNow ? 'pagada' : debt.status;
      const paidAt = isPaidNow ? new Date().toISOString() : debt.paid_at;

      // Avanzar fecha de vencimiento al siguiente mes si se cubrió al menos la cuota
      let nextDate = debt.next_due_date;
      if (paymentData.amount >= debt.monthly_payment && newBalance > 0) {
        const [year, month, day] = debt.next_due_date.split('-').map(Number);
        const d = new Date(year, month, day);
        nextDate = d.toISOString().split('T')[0];
      }

      const stmtUpdate = db.prepare(`
        UPDATE debts
        SET current_balance = ?, status = ?, next_due_date = ?, paid_at = ?
        WHERE id = ?
      `);
      stmtUpdate.run(newBalance, newStatus, nextDate, paidAt, debtId);

      return {
        debt: this.findById(debtId),
        payment: {
          debt_id: debtId,
          amount: paymentData.amount,
          payment_date: paymentData.payment_date,
          notes: paymentData.notes
        }
      };
    });

    return recordPaymentTx();
  }

  getPayments(debtId) {
    return db.prepare(`
      SELECT * FROM debt_payments
      WHERE debt_id = ?
      ORDER BY payment_date DESC
    `).all(debtId);
  }

  findPaidHistory(userId = null) {
    let sql = `
      SELECT d.*,
        COUNT(dp.id) as payments_count,
        COALESCE(SUM(dp.amount), 0) as total_repaid
      FROM debts d
      LEFT JOIN debt_payments dp ON d.id = dp.debt_id
      WHERE d.status = 'pagada'
    `;
    const params = [];
    if (userId) {
      sql += ' AND d.user_id = ?';
      params.push(userId);
    }
    sql += ' GROUP BY d.id ORDER BY d.paid_at DESC, d.created_at DESC';
    return db.prepare(sql).all(...params);
  }

  getTotalOutstandingDebt(userId = null) {
    let sql = `
      SELECT COALESCE(SUM(current_balance), 0) as total
      FROM debts
      WHERE status = 'activa'
    `;
    const params = [];
    if (userId) {
      sql += ' AND user_id = ?';
      params.push(userId);
    }
    const row = db.prepare(sql).get(...params);
    return row ? row.total : 0;
  }
}

export const debtRepository = new DebtRepository();
