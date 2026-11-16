import { dashboardService } from '../services/dashboardService.js';

export class DashboardController {
  getSummary = (req, res, next) => {
    try {
      const { month } = req.query; // opcional: 'YYYY-MM'
      const data = dashboardService.getDashboardData(month);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };
}

export const dashboardController = new DashboardController();
