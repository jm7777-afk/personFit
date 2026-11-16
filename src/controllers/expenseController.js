import { expenseService } from '../services/expenseService.js';

export class ExpenseController {
  getAll = (req, res, next) => {
    try {
      const { month, category_id, is_paid, type } = req.query;
      const data = expenseService.getAllExpenses({
        month,
        category_id: category_id ? Number(category_id) : undefined,
        is_paid: is_paid !== undefined ? Number(is_paid) : undefined,
        type
      });
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getById = (req, res, next) => {
    try {
      const data = expenseService.getExpenseById(Number(req.params.id));
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  create = (req, res, next) => {
    try {
      const result = expenseService.createExpense(req.body);
      res.status(201).json({
        status: 'success',
        message: 'Gasto registrado',
        data: result.expense,
        budget_warning: result.budget_warning
      });
    } catch (err) {
      next(err);
    }
  };

  update = (req, res, next) => {
    try {
      const data = expenseService.updateExpense(Number(req.params.id), req.body);
      res.status(200).json({ status: 'success', message: 'Gasto actualizado', data });
    } catch (err) {
      next(err);
    }
  };

  delete = (req, res, next) => {
    try {
      expenseService.deleteExpense(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Gasto eliminado' });
    } catch (err) {
      next(err);
    }
  };

  markAsPaid = (req, res, next) => {
    try {
      const data = expenseService.markAsPaid(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Servicio/factura marcada como pagada', data });
    } catch (err) {
      next(err);
    }
  };

  getUpcomingBills = (req, res, next) => {
    try {
      const { days } = req.query;
      const data = expenseService.getUpcomingBills(days);
      res.status(200).json({ status: 'success', count: data.length, data });
    } catch (err) {
      next(err);
    }
  };
}

export const expenseController = new ExpenseController();
