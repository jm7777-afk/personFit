import { expenseRepository } from '../repositories/expenseRepository.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { NotFoundError, BadRequestError } from '../utils/errors.js';

export class ExpenseService {
  getAllExpenses(filters) {
    return expenseRepository.findAll(filters);
  }

  getExpenseById(id) {
    const expense = expenseRepository.findById(id);
    if (!expense) {
      throw new NotFoundError(`Gasto con id ${id} no encontrado`);
    }
    return expense;
  }

  createExpense(data) {
    const category = categoryRepository.findById(data.category_id);
    if (!category) {
      throw new BadRequestError(`Categoría con id ${data.category_id} no existe`);
    }

    const expense = expenseRepository.create(data);

    // Auditoría de presupuesto para evitar desperdicio de dinero
    let budgetWarning = null;
    if (category.monthly_budget > 0) {
      const yearMonth = data.date.slice(0, 7);
      const categoryStats = expenseRepository.getMonthlyTotalByCategory(yearMonth)
        .find(c => c.category_id === category.id);

      const totalSpent = categoryStats ? categoryStats.total_spent : data.amount;
      const budgetPercent = Math.round((totalSpent / category.monthly_budget) * 100);

      if (budgetPercent >= 100) {
        budgetWarning = {
          level: 'critical',
          message: `🚨 ¡Atención! Has superado el presupuesto de "${category.name}". Has gastado ${budgetPercent}% del límite asignado.`,
          total_spent: totalSpent,
          monthly_budget: category.monthly_budget
        };
      } else if (budgetPercent >= 80) {
        budgetWarning = {
          level: 'warning',
          message: `⚠️ Cuidado: Has alcanzado el ${budgetPercent}% del presupuesto mensual para "${category.name}".`,
          total_spent: totalSpent,
          monthly_budget: category.monthly_budget
        };
      }
    }

    return {
      expense,
      budget_warning: budgetWarning
    };
  }

  updateExpense(id, data) {
    this.getExpenseById(id);
    if (data.category_id) {
      const category = categoryRepository.findById(data.category_id);
      if (!category) {
        throw new BadRequestError(`Categoría con id ${data.category_id} no existe`);
      }
    }
    return expenseRepository.update(id, data);
  }

  deleteExpense(id) {
    this.getExpenseById(id);
    return expenseRepository.delete(id);
  }

  markAsPaid(id) {
    this.getExpenseById(id);
    return expenseRepository.markAsPaid(id);
  }

  getUpcomingBills(days) {
    const d = days ? Number(days) : 15;
    return expenseRepository.findUpcomingBills(d);
  }
}

export const expenseService = new ExpenseService();
