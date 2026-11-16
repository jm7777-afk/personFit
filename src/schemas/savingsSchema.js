import { z } from 'zod';

export const createSavingsGoalSchema = z.object({
  title: z.string().min(2, 'El título debe tener al menos 2 caracteres').max(100),
  target_amount: z.number().positive('La meta debe ser mayor a 0'),
  current_amount: z.number().nonnegative('El monto acumulado no puede ser negativo').default(0),
  target_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)').optional().nullable(),
  priority: z.enum(['alta', 'media', 'baja']).default('media'),
  notes: z.string().max(500).optional().nullable()
});

export const updateSavingsGoalSchema = createSavingsGoalSchema.partial();

export const createSavingsTransactionSchema = z.object({
  amount: z.number().refine(val => val !== 0, 'El monto no puede ser 0'), // positivo = depósito, negativo = retiro
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)'),
  notes: z.string().max(500).optional().nullable()
});
