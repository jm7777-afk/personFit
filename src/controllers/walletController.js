import { walletService } from '../services/walletService.js';

export const walletController = {
  getWallets(req, res, next) {
    try {
      const data = walletService.getWallets(req.user?.id);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  createWallet(req, res, next) {
    try {
      const data = walletService.createWallet(req.user?.id, req.body);
      res.status(201).json({ status: 'success', message: 'Billetera creada', data });
    } catch (err) {
      next(err);
    }
  },

  updateWallet(req, res, next) {
    try {
      const data = walletService.updateWallet(req.user?.id, Number(req.params.id), req.body);
      if (!data) return res.status(404).json({ status: 'fail', message: 'Billetera no encontrada' });
      res.status(200).json({ status: 'success', message: 'Saldo de billetera actualizado', data });
    } catch (err) {
      next(err);
    }
  },

  deleteWallet(req, res, next) {
    try {
      const deleted = walletService.deleteWallet(req.user?.id, Number(req.params.id));
      if (!deleted) return res.status(404).json({ status: 'fail', message: 'Billetera no encontrada' });
      res.status(200).json({ status: 'success', message: 'Billetera eliminada' });
    } catch (err) {
      next(err);
    }
  }
};
