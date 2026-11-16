import { z } from 'zod';

export const createExpenseSchema = z.object({
  title: z.string().min(2, 'El título debe tener al menos 2 caracteres').max(100),
  amount: z.number().positive('El monto debe ser mayor a 0'),
  category_id: z.number().int().positive('ID de categoría inválido'),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)'),
  due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato de fecha inválido (YYYY-MM-DD)').optional().nullable(),
  is_paid: z.number().int().min(0).max(1).default(1), // 1 = pagado, 0 = pendiente
  payment_method: z.enum(['efectivo', 'tarjeta_debito', 'tarjeta_credito', 'transferencia']).default('efectivo'),
  notes: z.string().max(500).optional().nullable()
});

export const updateExpenseSchema = createExpenseSchema.partial();
