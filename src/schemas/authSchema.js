import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string().min(2, 'El nombre debe tener al menos 2 caracteres').max(100),
  email: z.string().email('Correo electrónico inválido').toLowerCase().trim(),
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres').max(100)
});

export const loginSchema = z.object({
  email: z.string().email('Correo electrónico inválido').toLowerCase().trim(),
  password: z.string().min(1, 'La contraseña es requerida')
});

export const updateProfileSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  avatar: z.string().optional().nullable(),
  current_password: z.string().optional(),
  new_password: z.string().min(6, 'La nueva contraseña debe tener al menos 6 caracteres').optional()
});
