import { Router } from 'express';
import { savingsController } from '../controllers/savingsController.js';
import { validate } from '../middlewares/validate.js';
import {
  createSavingsGoalSchema,
  updateSavingsGoalSchema,
  createSavingsTransactionSchema
} from '../schemas/savingsSchema.js';

const router = Router();

router.route('/')
  .get(savingsController.getAll)
  .post(validate(createSavingsGoalSchema), savingsController.create);

router.route('/:id')
  .get(savingsController.getById)
  .put(validate(updateSavingsGoalSchema), savingsController.update)
  .delete(savingsController.delete);

// Aportes o retiros de ahorro
router.route('/:id/transactions')
  .get(savingsController.getTransactions)
  .post(validate(createSavingsTransactionSchema), savingsController.recordTransaction);

export default router;
