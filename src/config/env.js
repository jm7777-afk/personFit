import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().default('./data/finance.db'),
  CORS_ORIGIN: z.string().default('*'),
  JWT_SECRET: z.string().default('personfit_super_secret_jwt_key_2026_finance'),
  JWT_EXPIRES_IN: z.string().default('30d')
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Error de validación en variables de entorno:', parsedEnv.error.format());
  process.exit(1);
}

export const env = parsedEnv.data;
