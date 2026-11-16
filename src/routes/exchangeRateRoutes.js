import { Router } from 'express';
import { exchangeRateController } from '../controllers/exchangeRateController.js';
import { validate } from '../middlewares/validate.js';
import { convertCurrencySchema } from '../schemas/exchangeRateSchema.js';

const router = Router();

router.get('/', exchangeRateController.getRates);
router.post('/sync', exchangeRateController.syncRates);
router.post('/convert', validate(convertCurrencySchema), exchangeRateController.convert);

export default router;
