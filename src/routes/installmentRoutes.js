import { Router } from 'express';
import { installmentController } from '../controllers/installmentController.js';

const router = Router();

router.get('/', installmentController.getPlans);
router.post('/', installmentController.createPlan);
router.patch('/payments/:paymentId/toggle', installmentController.payInstallment);
router.delete('/:id', installmentController.deletePlan);

export default router;
