import { installmentService } from '../services/installmentService.js';

export const installmentController = {
  getPlans(req, res, next) {
    try {
      const data = installmentService.getPlans(req.user?.id);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  createPlan(req, res, next) {
    try {
      const data = installmentService.createPlan(req.user?.id, req.body);
      res.status(201).json({ status: 'success', message: 'Compra en cuotas registrada', data });
    } catch (err) {
      next(err);
    }
  },

  payInstallment(req, res, next) {
    try {
      const data = installmentService.payInstallment(req.user?.id, Number(req.params.paymentId));
      if (!data) return res.status(404).json({ status: 'fail', message: 'Cuota no encontrada' });
      res.status(200).json({ status: 'success', message: 'Estado de cuota actualizado', data });
    } catch (err) {
      next(err);
    }
  },

  deletePlan(req, res, next) {
    try {
      const deleted = installmentService.deletePlan(req.user?.id, Number(req.params.id));
      if (!deleted) return res.status(404).json({ status: 'fail', message: 'Plan no encontrado' });
      res.status(200).json({ status: 'success', message: 'Plan eliminado' });
    } catch (err) {
      next(err);
    }
  }
};
