import { incomeRepository } from '../repositories/incomeRepository.js';
import { expenseRepository } from '../repositories/expenseRepository.js';
import { debtRepository } from '../repositories/debtRepository.js';
import { savingsRepository } from '../repositories/savingsRepository.js';

export class DashboardService {
  getDashboardData(selectedMonth) {
    const today = new Date();
    const currentMonth = selectedMonth || today.toISOString().slice(0, 7); // 'YYYY-MM'

    // 1. Ingresos y Gastos del mes
    const totalIncome = incomeRepository.getTotalByMonth(currentMonth);
    const totalExpenses = expenseRepository.getTotalByMonth(currentMonth);
    const netBalance = totalIncome - totalExpenses;

    // 2. Desglose de gastos por categorías
    const categoryStats = expenseRepository.getMonthlyTotalByCategory(currentMonth);
    const expensesBreakdown = categoryStats.map(cat => ({
      category_id: cat.category_id,
      name: cat.category_name,
      type: cat.category_type,
      icon: cat.category_icon,
      monthly_budget: cat.monthly_budget,
      total_spent: cat.total_spent,
      percentage_of_total: totalExpenses > 0 ? Number(((cat.total_spent / totalExpenses) * 100).toFixed(1)) : 0,
      is_over_budget: cat.monthly_budget > 0 && cat.total_spent > cat.monthly_budget
    }));

    // 3. Evaluación de la regla presupuestaria 50/30/20
    const needsSpent = categoryStats
      .filter(c => c.category_type === 'obligatorio' || c.category_type === 'servicio')
      .reduce((sum, c) => sum + c.total_spent, 0);

    const wantsSpent = categoryStats
      .filter(c => c.category_type === 'deseo' || c.category_type === 'compra')
      .reduce((sum, c) => sum + c.total_spent, 0);

    const budget503020 = {
      needs: {
        category: 'Necesidades Básicas y Servicios (50%)',
        target_amount: Number((totalIncome * 0.50).toFixed(2)),
        actual_spent: Number(needsSpent.toFixed(2)),
        percentage_of_income: totalIncome > 0 ? Number(((needsSpent / totalIncome) * 100).toFixed(1)) : 0,
        status: needsSpent <= (totalIncome * 0.50) ? 'en_presupuesto' : 'excedido'
      },
      wants: {
        category: 'Estilo de Vida y Compras (30%)',
        target_amount: Number((totalIncome * 0.30).toFixed(2)),
        actual_spent: Number(wantsSpent.toFixed(2)),
        percentage_of_income: totalIncome > 0 ? Number(((wantsSpent / totalIncome) * 100).toFixed(1)) : 0,
        status: wantsSpent <= (totalIncome * 0.30) ? 'en_presupuesto' : 'excedido'
      },
      savings_and_debts: {
        category: 'Ahorro y Reducción de Deudas (20%)',
        target_amount: Number((totalIncome * 0.20).toFixed(2)),
        actual_available: Number(Math.max(0, netBalance).toFixed(2)),
        status: netBalance >= (totalIncome * 0.20) ? 'optimo' : 'atencion'
      }
    };

    // 4. Deudas y Radar de Pagos Urgentes (Próximos 15 días)
    const totalOutstandingDebt = debtRepository.getTotalOutstandingDebt();
    const upcomingDebts = debtRepository.findUpcoming(15);
    const upcomingBills = expenseRepository.findUpcomingBills(15);

    // 5. Ahorros
    const totalSavings = savingsRepository.getTotalSavings();
    const savingsGoals = savingsRepository.findAll();

    // 6. Cálculo del Score de Salud Financiera (0 a 100)
    let score = 70; // Base inicial
    const recommendations = [];

    // Factor 1: Balance neto
    if (totalIncome > 0) {
      const expenseRatio = totalExpenses / totalIncome;
      if (expenseRatio <= 0.70) score += 15;
      else if (expenseRatio <= 0.85) score += 5;
      else if (expenseRatio > 1.0) {
        score -= 25;
        recommendations.push('🚨 Tus gastos superan tus ingresos del mes. Estás viviendo con déficit financiero.');
      }
    } else {
      recommendations.push('ℹ️ Registra los ingresos de tu empleo para calcular tu salud financiera completa.');
    }

    // Factor 2: Control de deudas
    if (totalOutstandingDebt === 0) {
      score += 15;
      recommendations.push('🏆 ¡Excelente! No tienes deudas activas pendientes.');
    } else {
      if (upcomingDebts.length > 0) {
        recommendations.push(`📅 Tienes ${upcomingDebts.length} pago(s) de deuda con vencimiento en los próximos 15 días.`);
      }
    }

    // Factor 3: Fugas en deseos/compras
    if (totalIncome > 0 && (wantsSpent / totalIncome) > 0.35) {
      score -= 10;
      recommendations.push('⚠️ Alerta de fugas: Estás destinando más del 35% de tus ingresos a compras o entretenimiento. Revisa tus gastos hormiga.');
    }

    // Factor 4: Ahorro
    if (totalSavings > 0) {
      score = Math.min(100, score + 5);
    } else {
      recommendations.push('💡 Recomendación: Crea tu primera meta para el "Fondo de Emergencia" (mínimo 1 mes de gastos básicos).');
    }

    score = Math.max(0, Math.min(100, score));

    let status = 'Saludable';
    if (score >= 85) status = 'Excelente';
    else if (score >= 70) status = 'Saludable';
    else if (score >= 50) status = 'Alerta / Cuidado';
    else status = 'Crítico';

    return {
      month: currentMonth,
      cashflow: {
        total_income: Number(totalIncome.toFixed(2)),
        total_expenses: Number(totalExpenses.toFixed(2)),
        net_balance: Number(netBalance.toFixed(2)),
        savings_rate: totalIncome > 0 ? Number(((Math.max(0, netBalance) / totalIncome) * 100).toFixed(1)) : 0
      },
      financial_health: {
        score,
        status,
        recommendations
      },
      budget_rule_50_30_20: budget503020,
      debts_overview: {
        total_outstanding_debt: Number(totalOutstandingDebt.toFixed(2)),
        urgent_debts_count: upcomingDebts.length,
        upcoming_debts: upcomingDebts
      },
      upcoming_bills_radar: {
        urgent_bills_count: upcomingBills.length,
        upcoming_bills: upcomingBills
      },
      savings_overview: {
        total_accumulated_savings: Number(totalSavings.toFixed(2)),
        active_goals_count: savingsGoals.length,
        goals: savingsGoals
      },
      expenses_breakdown: expensesBreakdown
    };
  }
}

export const dashboardService = new DashboardService();
