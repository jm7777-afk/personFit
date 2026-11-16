import { savingsService } from '../services/savingsService.js';

export class SavingsController {
  getAll = (req, res, next) => {
    try {
      const data = savingsService.getAllGoals();
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getById = (req, res, next) => {
    try {
      const data = savingsService.getGoalById(Number(req.params.id));
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  create = (req, res, next) => {
    try {
      const data = savingsService.createGoal(req.body);
      res.status(201).json({ status: 'success', message: 'Meta de ahorro creada', data });
    } catch (err) {
      next(err);
    }
  };

  update = (req, res, next) => {
    try {
      const data = savingsService.updateGoal(Number(req.params.id), req.body);
      res.status(200).json({ status: 'success', message: 'Meta de ahorro actualizada', data });
    } catch (err) {
      next(err);
    }
  };

  delete = (req, res, next) => {
    try {
      savingsService.deleteGoal(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Meta de ahorro eliminada' });
    } catch (err) {
      next(err);
    }
  };

  recordTransaction = (req, res, next) => {
    try {
      const data = savingsService.recordTransaction(Number(req.params.id), req.body);
      res.status(201).json({ status: 'success', message: 'Movimiento registrado', data });
    } catch (err) {
      next(err);
    }
  };

  getTransactions = (req, res, next) => {
    try {
      const data = savingsService.getTransactions(Number(req.params.id));
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };
}

export const savingsController = new SavingsController();
