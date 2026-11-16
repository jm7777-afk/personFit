import { Router } from 'express';
import { expenseController } from '../controllers/expenseController.js';
import { validate } from '../middlewares/validate.js';
import { createExpenseSchema, updateExpenseSchema } from '../schemas/expenseSchema.js';

const router = Router();

// Rutas especiales
router.get('/upcoming-bills', expenseController.getUpcomingBills);

router.route('/')
  .get(expenseController.getAll)
  .post(validate(createExpenseSchema), expenseController.create);

router.route('/:id')
  .get(expenseController.getById)
  .put(validate(updateExpenseSchema), expenseController.update)
  .delete(expenseController.delete);

router.patch('/:id/pay', expenseController.markAsPaid);

export default router;
