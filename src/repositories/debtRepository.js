import { db } from '../config/database.js';

export class DebtRepository {
  findAll(status = null) {
    let sql = 'SELECT * FROM debts';
    const params = [];
    if (status) {
      sql += ' WHERE status = ?';
      params.push(status);
    }
    sql += ' ORDER BY next_due_date ASC';
    return db.prepare(sql).all(...params);
  }

  findById(id) {
    return db.prepare('SELECT * FROM debts WHERE id = ?').get(id);
  }

  create(data) {
    const currentBalance = data.current_balance !== undefined ? data.current_balance : data.total_amount;
    const stmt = db.prepare(`
      INSERT INTO debts (
        title, creditor, total_amount, current_balance, monthly_payment,
        interest_rate, due_day, next_due_date, status, notes
      ) VALUES (
        @title, @creditor, @total_amount, @current_balance, @monthly_payment,
        @interest_rate, @due_day, @next_due_date, @status, @notes
      )
    `);

    const result = stmt.run({
      title: data.title,
      creditor: data.creditor,
      total_amount: data.total_amount,
      current_balance: currentBalance,
      monthly_payment: data.monthly_payment,
      interest_rate: data.interest_rate || 0,
      due_day: data.due_day,
      next_due_date: data.next_due_date,
      status: data.status || 'activa',
      notes: data.notes || null
    });

    return this.findById(result.lastInsertRowid);
  }

  update(id, data) {
    const current = this.findById(id);
    if (!current) return null;

    const merged = { ...current, ...data };
    const stmt = db.prepare(`
      UPDATE debts
      SET title = @title, creditor = @creditor, total_amount = @total_amount,
          current_balance = @current_balance, monthly_payment = @monthly_payment,
          interest_rate = @interest_rate, due_day = @due_day,
          next_due_date = @next_due_date, status = @status, notes = @notes
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
      notes: merged.notes || null
    });

    return this.findById(id);
  }

  delete(id) {
    const stmt = db.prepare('DELETE FROM debts WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  findUpcoming(days = 15) {
    const stmt = db.prepare(`
      SELECT *,
        CAST(julianday(next_due_date) - julianday('now') AS INTEGER) AS days_remaining
      FROM debts
      WHERE status = 'activa'
        AND date(next_due_date) <= date('now', '+' || ? || ' days')
      ORDER BY next_due_date ASC
    `);
    return stmt.all(days);
  }

  recordPayment(debtId, paymentData) {
    const recordPaymentTx = db.transaction(() => {
      const debt = this.findById(debtId);
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
      const newStatus = newBalance === 0 ? 'pagada' : debt.status;

      // Avanzar fecha de vencimiento al siguiente mes si se cubrió al menos la cuota
      let nextDate = debt.next_due_date;
      if (paymentData.amount >= debt.monthly_payment && newBalance > 0) {
        const [year, month, day] = debt.next_due_date.split('-').map(Number);
        const d = new Date(year, month, day); // mes ya está 1-indexed en Date si pasamos month
        nextDate = d.toISOString().split('T')[0];
      }

      const stmtUpdate = db.prepare(`
        UPDATE debts
        SET current_balance = ?, status = ?, next_due_date = ?
        WHERE id = ?
      `);
      stmtUpdate.run(newBalance, newStatus, nextDate, debtId);

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

  getTotalOutstandingDebt() {
    const row = db.prepare(`
      SELECT COALESCE(SUM(current_balance), 0) as total
      FROM debts
      WHERE status = 'activa'
    `).get();
    return row ? row.total : 0;
  }
}

export const debtRepository = new DebtRepository();
