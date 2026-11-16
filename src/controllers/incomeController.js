import { incomeService } from '../services/incomeService.js';

export class IncomeController {
  getAll = (req, res, next) => {
    try {
      const { month, source } = req.query;
      const data = incomeService.getAllIncomes({ month, source });
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getById = (req, res, next) => {
    try {
      const data = incomeService.getIncomeById(Number(req.params.id));
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  create = (req, res, next) => {
    try {
      const data = incomeService.createIncome(req.body);
      res.status(201).json({ status: 'success', message: 'Ingreso registrado exitosamente', data });
    } catch (err) {
      next(err);
    }
  };

  update = (req, res, next) => {
    try {
      const data = incomeService.updateIncome(Number(req.params.id), req.body);
      res.status(200).json({ status: 'success', message: 'Ingreso actualizado', data });
    } catch (err) {
      next(err);
    }
  };

  delete = (req, res, next) => {
    try {
      incomeService.deleteIncome(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Ingreso eliminado' });
    } catch (err) {
      next(err);
    }
  };
}

export const incomeController = new IncomeController();
