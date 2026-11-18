import { z } from 'zod';

export const createIncomeSchema = z.object({
  title: z.string().min(2, 'El título debe tener al menos 2 caracteres').max(100),
  amount: z.number().positive('El monto debe ser mayor a 0'),
  source: z.string().max(50).default('empleo_principal'),
  frequency: z.enum(['mensual', 'quincenal', 'semanal', 'diario', 'unico']).default('quincenal'),
  currency: z.enum(['USD', 'VES', 'EUR', 'USDT']).default('USD'),
  day_of_month: z.number().int().min(1).max(31).optional().nullable(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)'),
  notes: z.string().max(500).optional().nullable()
});

export const updateIncomeSchema = createIncomeSchema.partial();
