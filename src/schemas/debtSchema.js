import { z } from 'zod';

export const createDebtSchema = z.object({
  title: z.string().min(2, 'El título debe tener al menos 2 caracteres').max(100),
  creditor: z.string().min(2, 'El acreedor/banco es requerido').max(100),
  total_amount: z.number().positive('El monto total debe ser mayor a 0'),
  current_balance: z.number().nonnegative('El balance pendiente no puede ser negativo').optional(),
  monthly_payment: z.number().positive('La cuota mensual debe ser mayor a 0'),
  interest_rate: z.number().min(0, 'La tasa no puede ser negativa').default(0),
  due_day: z.number().int().min(1).max(31, 'El día de pago debe estar entre 1 y 31').default(15),
  next_due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)'),
  status: z.enum(['activa', 'pagada', 'refinanciada']).default('activa'),
  currency: z.enum(['USD', 'VES', 'EUR', 'USDT']).default('USD'),
  deduct_from_salary: z.union([z.boolean(), z.number()]).optional().default(false),
  is_borrowed: z.union([z.boolean(), z.number()]).optional().default(false),
  payment_method_type: z.string().max(60).optional().nullable(),
  payment_details: z.string().max(500).optional().nullable(),
  notes: z.string().max(500).optional().nullable()
});

export const updateDebtSchema = createDebtSchema.partial();

export const createDebtPaymentSchema = z.object({
  amount: z.number().positive('El monto del abono debe ser mayor a 0'),
  payment_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)'),
  notes: z.string().max(500).optional().nullable()
});
