import { Router } from 'express';
import { debtController } from '../controllers/debtController.js';
import { validate } from '../middlewares/validate.js';
import { createDebtSchema, updateDebtSchema, createDebtPaymentSchema } from '../schemas/debtSchema.js';

const router = Router();

// Rutas especiales (antes de /:id para evitar colisiones)
router.get('/upcoming', debtController.getUpcoming);
router.get('/strategies', debtController.getStrategies);

router.route('/')
  .get(debtController.getAll)
  .post(validate(createDebtSchema), debtController.create);

router.route('/:id')
  .get(debtController.getById)
  .put(validate(updateDebtSchema), debtController.update)
  .delete(debtController.delete);

// Abonos a deudas
router.route('/:id/payments')
  .get(debtController.getPayments)
  .post(validate(createDebtPaymentSchema), debtController.recordPayment);

export default router;
