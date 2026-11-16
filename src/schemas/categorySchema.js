import { z } from 'zod';

export const createCategorySchema = z.object({
  name: z.string().min(2, 'El nombre debe tener al menos 2 caracteres').max(50),
  type: z.enum(['servicio', 'compra', 'obligatorio', 'deseo']),
  icon: z.string().max(30).optional().default('tag'),
  monthly_budget: z.number().nonnegative('El presupuesto no puede ser negativo').default(0)
});

export const updateCategorySchema = createCategorySchema.partial();
