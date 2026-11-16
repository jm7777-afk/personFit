import { debtService } from '../services/debtService.js';

export class DebtController {
  getAll = (req, res, next) => {
    try {
      const { status } = req.query;
      const data = debtService.getAllDebts(status);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getById = (req, res, next) => {
    try {
      const data = debtService.getDebtById(Number(req.params.id));
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  create = (req, res, next) => {
    try {
      const data = debtService.createDebt(req.body);
      res.status(201).json({ status: 'success', message: 'Deuda registrada exitosamente', data });
    } catch (err) {
      next(err);
    }
  };

  update = (req, res, next) => {
    try {
      const data = debtService.updateDebt(Number(req.params.id), req.body);
      res.status(200).json({ status: 'success', message: 'Deuda actualizada', data });
    } catch (err) {
      next(err);
    }
  };

  delete = (req, res, next) => {
    try {
      debtService.deleteDebt(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Deuda eliminada' });
    } catch (err) {
      next(err);
    }
  };

  getUpcoming = (req, res, next) => {
    try {
      const { days } = req.query;
      const data = debtService.getUpcomingDebts(days);
      res.status(200).json({ status: 'success', count: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  recordPayment = (req, res, next) => {
    try {
      const result = debtService.recordPayment(Number(req.params.id), req.body);
      res.status(201).json({
        status: 'success',
        message: 'Abono a deuda registrado exitosamente',
        data: result
      });
    } catch (err) {
      next(err);
    }
  };

  getPayments = (req, res, next) => {
    try {
      const data = debtService.getPayments(Number(req.params.id));
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getStrategies = (req, res, next) => {
    try {
      const data = debtService.getPayoffStrategies();
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };
}

export const debtController = new DebtController();
