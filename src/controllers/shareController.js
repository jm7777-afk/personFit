import { shareService } from '../services/shareService.js';

export const shareController = {
  createShare(req, res, next) {
    try {
      const { duration_minutes } = req.body;
      const data = shareService.createShareToken(req.user?.id, duration_minutes);
      res.status(201).json({ status: 'success', message: 'Enlace temporal generado', data });
    } catch (err) {
      next(err);
    }
  },

  getSharedProfile(req, res, next) {
    try {
      const { token } = req.params;
      const data = shareService.getSharedProfile(token);
      if (!data.is_valid) {
        return res.status(data.is_expired ? 410 : 404).json({ status: 'fail', message: data.message, data });
      }
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  getUserShares(req, res, next) {
    try {
      const data = shareService.getUserShares(req.user?.id);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  },

  revokeShare(req, res, next) {
    try {
      const { token } = req.params;
      const data = shareService.revokeShare(req.user?.id, token);
      res.status(200).json({ status: 'success', message: 'Acceso revocado exitosamente', data });
    } catch (err) {
      next(err);
    }
  }
};
