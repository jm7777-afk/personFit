import { Router } from 'express';
import { notificationController } from '../controllers/notificationController.js';

const router = Router();

router.get('/', notificationController.getAll);

export default router;
