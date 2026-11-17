import { db } from '../config/database.js';

export const payrollService = {
  // Obtiene el estado actual del próximo cobro de nómina, cuenta regresiva y sueldo restante
  getPayrollSummary(userId) {
    // 1. Obtener los ingresos registrados del usuario
    const incomes = db.prepare(`
      SELECT * FROM incomes 
      WHERE user_id = ? 
      ORDER BY date DESC
    `).all(userId);

    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];

    // Obtener la tasa de cambio oficial actual para conversiones
    const bcvRateObj = db.prepare("SELECT rate FROM exchange_rates WHERE id = 'usd_oficial'").get();
    const bcvRate = bcvRateObj ? bcvRateObj.rate : 914.02;

    if (incomes.length === 0) {
      return {
        has_income_configured: false,
        message: 'No tienes registrado un salario o ingreso recurrente. Configúralo seleccionando Quincenal, Semanal o Diario.',
        days_remaining: 0,
        next_payout_date: todayStr,
        expected_salary_usd: 0,
        expected_salary_bs: 0,
        deductions_usd: 0,
        deductions_bs: 0,
        net_remaining_usd: 0,
        net_remaining_bs: 0,
        deductions_breakdown: []
      };
    }

    // Tomar el ingreso principal o el más representativo
    const primaryIncome = incomes[0];
    const freq = (primaryIncome.frequency || 'mensual').toLowerCase();
    const incomeAmount = primaryIncome.amount;
    const isBs = (primaryIncome.currency || 'USD').toUpperCase() === 'VES';

    const grossAmountUsd = isBs ? +(incomeAmount / bcvRate).toFixed(2) : incomeAmount;
    const grossAmountBs = isBs ? incomeAmount : +(incomeAmount * bcvRate).toFixed(2);

    // 2. Calcular la próxima fecha de cobro de acuerdo a la periodicidad
    const nextPayoutDate = this.calculateNextPayoutDate(freq, primaryIncome.date, primaryIncome.day_of_month);
    const nextPayoutStr = nextPayoutDate.toISOString().split('T')[0];

    // Días restantes para cobrar
    const msDiff = nextPayoutDate.getTime() - now.getTime();
    const daysRemaining = Math.max(0, Math.ceil(msDiff / (1000 * 60 * 60 * 24)));

    // 3. Calcular deducciones comprometidas antes o en la fecha de cobro:
    // a) Deudas con opción "deduct_from_salary = 1" o préstamos tomados recientemente
    const salaryDebts = db.prepare(`
      SELECT id, title, creditor, monthly_payment, current_balance, currency, deduct_from_salary, is_borrowed, next_due_date
      FROM debts
      WHERE user_id = ? AND status = 'activa' AND (deduct_from_salary = 1 OR is_borrowed = 1)
    `).all(userId);

    // b) Gastos y servicios obligatorios pendientes por pagar antes de cobrar
    const pendingExpenses = db.prepare(`
      SELECT id, title, amount, due_date
      FROM expenses
      WHERE user_id = ? AND is_paid = 0 AND due_date <= ?
    `).all(userId, nextPayoutStr);

    let totalDeductionsUsd = 0;
    const deductionsBreakdown = [];

    for (const d of salaryDebts) {
      const isDebtBs = (d.currency || 'USD').toUpperCase() === 'VES';
      // Monto a deducir en este ciclo (o pago mensual o saldo si es menor)
      const payAmount = d.is_borrowed === 1 ? d.current_balance : (d.monthly_payment || d.current_balance);
      const payUsd = isDebtBs ? +(payAmount / bcvRate).toFixed(2) : payAmount;
      const payBs = isDebtBs ? payAmount : +(payAmount * bcvRate).toFixed(2);

      totalDeductionsUsd += payUsd;
      deductionsBreakdown.push({
        type: d.is_borrowed === 1 ? 'prestamo_tomado' : 'deuda_programada',
        title: d.is_borrowed === 1 ? `Préstamo de ${d.creditor}` : d.title,
        creditor: d.creditor,
        amount_usd: payUsd,
        amount_bs: payBs,
        due_date: d.next_due_date
      });
    }

    for (const exp of pendingExpenses) {
      const expUsd = +(exp.amount).toFixed(2);
      const expBs = +(expUsd * bcvRate).toFixed(2);
      totalDeductionsUsd += expUsd;
      deductionsBreakdown.push({
        type: 'gasto_servicio_pendiente',
        title: exp.title,
        amount_usd: expUsd,
        amount_bs: expBs,
        due_date: exp.due_date
      });
    }

    totalDeductionsUsd = +totalDeductionsUsd.toFixed(2);
    const totalDeductionsBs = +(totalDeductionsUsd * bcvRate).toFixed(2);

    // Sueldo neto libre que va quedando sin cobrar
    const netRemainingUsd = Math.max(0, +(grossAmountUsd - totalDeductionsUsd).toFixed(2));
    const netRemainingBs = Math.max(0, +(grossAmountBs - totalDeductionsBs).toFixed(2));

    const percentFree = grossAmountUsd > 0 ? +((netRemainingUsd / grossAmountUsd) * 100).toFixed(1) : 0;

    return {
      has_income_configured: true,
      income_title: primaryIncome.title,
      frequency: freq,
      frequency_label: this.getFrequencyLabel(freq),
      days_remaining: daysRemaining,
      next_payout_date: nextPayoutStr,
      expected_salary_usd: grossAmountUsd,
      expected_salary_bs: grossAmountBs,
      total_deductions_usd: totalDeductionsUsd,
      total_deductions_bs: totalDeductionsBs,
      net_remaining_usd: netRemainingUsd,
      net_remaining_bs: netRemainingBs,
      percent_free: percentFree,
      deductions_breakdown: deductionsBreakdown
    };
  },

  // Calendario de fechas de cobro proyectadas (próximos 3 meses)
  getPayrollCalendar(userId, count = 6) {
    const incomes = db.prepare('SELECT * FROM incomes WHERE user_id = ? ORDER BY date DESC').all(userId);
    if (incomes.length === 0) return [];

    const primary = incomes[0];
    const freq = (primary.frequency || 'mensual').toLowerCase();
    const schedule = [];
    let curDate = new Date();

    for (let i = 0; i < count; i++) {
      const nextDate = this.calculateNextPayoutDate(freq, curDate.toISOString().split('T')[0], primary.day_of_month, i);
      schedule.push({
        payout_number: i + 1,
        date: nextDate.toISOString().split('T')[0],
        frequency: freq,
        frequency_label: this.getFrequencyLabel(freq),
        expected_amount: primary.amount,
        currency: primary.currency || 'USD'
      });
    }

    return schedule;
  },

  calculateNextPayoutDate(freq, referenceDateStr, customDay, offset = 0) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    if (freq === 'diario') {
      const d = new Date(today);
      d.setDate(d.getDate() + 1 + offset);
      return d;
    }

    if (freq === 'semanal') {
      // Cada semana (por ejemplo el próximo viernes o cada 7 días)
      const d = new Date(today);
      const dayOfWeek = d.getDay(); // 0 domingo, 5 viernes
      const diffToFriday = (5 - dayOfWeek + 7) % 7 || 7;
      d.setDate(d.getDate() + diffToFriday + (offset * 7));
      return d;
    }

    if (freq === 'quincenal') {
      // Quincenal estándar: día 15 y último día del mes
      const curYear = today.getFullYear();
      const curMonth = today.getMonth();
      const curDay = today.getDate();

      const lastDayOfMonth = new Date(curYear, curMonth + 1, 0).getDate();

      const candidateDates = [];
      // Generar fechas candidatas para este mes y el siguiente
      for (let m = 0; m <= 3; m++) {
        const y = curMonth + m > 11 ? curYear + 1 : curYear;
        const targetMonth = (curMonth + m) % 12;
        const lastDay = new Date(y, targetMonth + 1, 0).getDate();

        candidateDates.push(new Date(y, targetMonth, 15));
        candidateDates.push(new Date(y, targetMonth, lastDay));
      }

      const futureDates = candidateDates.filter(d => d.getTime() > today.getTime());
      if (futureDates.length > offset) {
        return futureDates[offset];
      }
      return futureDates[0] || new Date(curYear, curMonth, 15);
    }

    // Mensual por defecto (día 30 o customDay)
    const targetDay = customDay || 30;
    const curYear = today.getFullYear();
    const curMonth = today.getMonth();
    const m = curMonth + offset;
    const y = curYear + Math.floor(m / 12);
    const month = m % 12;

    const maxDay = new Date(y, month + 1, 0).getDate();
    const day = Math.min(targetDay, maxDay);
    const targetDate = new Date(y, month, day);

    if (targetDate <= today && offset === 0) {
      // Si la fecha de este mes ya pasó, ir al próximo mes
      const nextMonth = (curMonth + 1) % 12;
      const nextYear = curMonth === 11 ? curYear + 1 : curYear;
      const nextMaxDay = new Date(nextYear, nextMonth + 1, 0).getDate();
      return new Date(nextYear, nextMonth, Math.min(targetDay, nextMaxDay));
    }

    return targetDate;
  },

  getFrequencyLabel(freq) {
    switch (freq) {
      case 'diario': return 'Diario';
      case 'semanal': return 'Semanal';
      case 'quincenal': return 'Quincenal (Día 15 y Fin de Mes)';
      case 'mensual': return 'Mensual';
      default: return 'Mensual';
    }
  }
};
