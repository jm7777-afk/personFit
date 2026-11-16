import { notificationService } from '../services/notificationService.js';

export class NotificationController {
  getAll = (req, res, next) => {
    try {
      const data = notificationService.getNotifications(req.user?.id);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };
}

export const notificationController = new NotificationController();
