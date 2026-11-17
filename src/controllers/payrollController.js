import { payrollService } from '../services/payrollService.js';

export const payrollController = {
  getSummary(req, res, next) {
    try {
      const data = payrollService.getPayrollSummary(req.user?.id);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  getCalendar(req, res, next) {
    try {
      const count = Number(req.query.count) || 6;
      const data = payrollService.getPayrollCalendar(req.user?.id, count);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  }
};
