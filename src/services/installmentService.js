import { db } from '../config/database.js';

function resolveSafeUserId(userId) {
  if (userId) return userId;
  const firstUser = db.prepare('SELECT id FROM users ORDER BY id ASC LIMIT 1').get();
  return firstUser ? firstUser.id : null;
}

export const installmentService = {
  getPlans(userId) {
    const uid = resolveSafeUserId(userId);
    if (!uid) {
      return {
        plans: [],
        upcoming_14_days_usd: 0,
        total_pending_usd: 0,
        active_plans_count: 0
      };
    }

    const plans = db.prepare(`
      SELECT * FROM installment_plans
      WHERE user_id = ?
      ORDER BY status ASC, created_at DESC
    `).all(uid);

    const today = new Date();
    const in15Days = new Date(today.getTime() + 15 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    let upcoming14DaysUsd = 0;
    let totalPendingUsd = 0;
    let activeCount = 0;

    const enrichedPlans = plans.map((p) => {
      const payments = db.prepare(`
        SELECT * FROM installment_payments
        WHERE plan_id = ?
        ORDER BY installment_number ASC
      `).all(p.id);

      const paidCount = payments.filter(pay => pay.is_paid === 1).length;
      const pendingPayments = payments.filter(pay => pay.is_paid === 0);
      const nextPayment = pendingPayments.length > 0 ? pendingPayments[0] : null;

      if (p.status === 'activa') {
        activeCount++;
        totalPendingUsd += p.remaining_amount;
        for (const pay of pendingPayments) {
          if (pay.due_date <= in15Days) {
            upcoming14DaysUsd += pay.amount;
          }
        }
      }

      return {
        ...p,
        paid_installments: paidCount,
        next_payment: nextPayment,
        payments
      };
    });

    return {
      plans: enrichedPlans,
      upcoming_14_days_usd: +upcoming14DaysUsd.toFixed(2),
      total_pending_usd: +totalPendingUsd.toFixed(2),
      active_plans_count: activeCount
    };
  },

  createPlan(userId, {
    provider = 'Cashea',
    merchant_name,
    title,
    total_amount,
    initial_paid,
    initial_percent,
    installments_count = 3,
    interval_days = 14,
    purchase_date,
    deduct_from_salary = true,
    notes
  }) {
    const uid = resolveSafeUserId(userId);
    if (!uid) throw new Error('Usuario no autenticado para crear plan de cuotas');

    const total = Number(total_amount);
    if (!total || total <= 0) throw new Error('El monto total debe ser mayor a 0');

    let initial = 0;
    if (initial_paid !== undefined && initial_paid !== null) {
      initial = Number(initial_paid);
    } else if (initial_percent !== undefined && initial_percent !== null) {
      initial = +((total * Number(initial_percent)) / 100).toFixed(2);
    } else {
      // Inicial estándar de Cashea Nivel 1: 40%
      initial = +(total * 0.40).toFixed(2);
    }

    const remaining = Math.max(0, +(total - initial).toFixed(2));
    const count = Math.max(1, Number(installments_count) || 3);
    const interval = Math.max(1, Number(interval_days) || 14);
    const startDateStr = purchase_date || new Date().toISOString().split('T')[0];

    const tx = db.transaction(() => {
      const stmt = db.prepare(`
        INSERT INTO installment_plans (
          user_id, provider, merchant_name, title, total_amount, initial_paid,
          remaining_amount, installments_count, interval_days, purchase_date,
          status, deduct_from_salary, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      const info = stmt.run(
        uid,
        provider,
        merchant_name || 'Comercio Aliado',
        title || `Compra en ${merchant_name || provider}`,
        total,
        initial,
        remaining,
        count,
        interval,
        startDateStr,
        remaining === 0 ? 'pagada' : 'activa',
        deduct_from_salary ? 1 : 0,
        notes || null
      );

      const planId = info.lastInsertRowid;

      // Generar las cuotas automáticas cada 14 días (o intervalo elegido)
      if (remaining > 0) {
        const baseInstallment = +(remaining / count).toFixed(2);
        const startDate = new Date(startDateStr + 'T12:00:00Z');
        const insertPay = db.prepare(`
          INSERT INTO installment_payments (plan_id, installment_number, amount, due_date, is_paid)
          VALUES (?, ?, ?, ?, 0)
        `);

        let accumulated = 0;
        for (let i = 1; i <= count; i++) {
          const due = new Date(startDate.getTime() + i * interval * 24 * 60 * 60 * 1000);
          const dueStr = due.toISOString().split('T')[0];
          const cuotaAmount = i === count ? +(remaining - accumulated).toFixed(2) : baseInstallment;
          accumulated += cuotaAmount;
          insertPay.run(planId, i, cuotaAmount, dueStr);
        }
      }

      return planId;
    });

    const planId = tx();
    const all = this.getPlans(uid);
    return all.plans.find(p => p.id === planId);
  },

  payInstallment(userId, paymentId) {
    const uid = resolveSafeUserId(userId);
    const payment = db.prepare(`
      SELECT ip.*, pl.user_id, pl.id as plan_id
      FROM installment_payments ip
      JOIN installment_plans pl ON pl.id = ip.plan_id
      WHERE ip.id = ? AND pl.user_id = ?
    `).get(paymentId, uid);

    if (!payment) return null;

    const tx = db.transaction(() => {
      const nextPaidState = payment.is_paid === 1 ? 0 : 1;
      db.prepare(`
        UPDATE installment_payments
        SET is_paid = ?, paid_at = ?
        WHERE id = ?
      `).run(nextPaidState, nextPaidState === 1 ? new Date().toISOString() : null, paymentId);

      // Recalcular saldo pendiente del plan
      const pendingRow = db.prepare(`
        SELECT COALESCE(SUM(amount), 0) as pending_sum, COUNT(*) as pending_count
        FROM installment_payments
        WHERE plan_id = ? AND is_paid = 0
      `).get(payment.plan_id);

      const newRemaining = +pendingRow.pending_sum.toFixed(2);
      const newStatus = pendingRow.pending_count === 0 ? 'pagada' : 'activa';

      db.prepare(`
        UPDATE installment_plans
        SET remaining_amount = ?, status = ?
        WHERE id = ?
      `).run(newRemaining, newStatus, payment.plan_id);
    });

    tx();
    const all = this.getPlans(uid);
    return all.plans.find(p => p.id === payment.plan_id);
  },

  deletePlan(userId, planId) {
    const uid = resolveSafeUserId(userId);
    const info = db.prepare('DELETE FROM installment_plans WHERE id = ? AND user_id = ?').run(planId, uid);
    return info.changes > 0;
  }
};
