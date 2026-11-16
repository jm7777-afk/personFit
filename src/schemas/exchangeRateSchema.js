import { z } from 'zod';

export const convertCurrencySchema = z.object({
  amount: z.number().positive('El monto a convertir debe ser mayor a 0'),
  from: z.enum(['USD', 'VES', 'EUR', 'usd', 'ves', 'eur']).default('USD'),
  to: z.enum(['USD', 'VES', 'EUR', 'usd', 'ves', 'eur']).default('VES'),
  rate_type: z.enum(['oficial', 'paralelo']).default('oficial')
});
