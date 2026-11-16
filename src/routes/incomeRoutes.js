import { Router } from 'express';
import { incomeController } from '../controllers/incomeController.js';
import { validate } from '../middlewares/validate.js';
import { createIncomeSchema, updateIncomeSchema } from '../schemas/incomeSchema.js';

const router = Router();

router.route('/')
  .get(incomeController.getAll)
  .post(validate(createIncomeSchema), incomeController.create);

router.route('/:id')
  .get(incomeController.getById)
  .put(validate(updateIncomeSchema), incomeController.update)
  .delete(incomeController.delete);

export default router;
