import { Router } from 'express';
import { payrollController } from '../controllers/payrollController.js';

const router = Router();

router.get('/summary', payrollController.getSummary);
router.get('/calendar', payrollController.getCalendar);

export default router;
