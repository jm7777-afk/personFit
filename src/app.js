import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env.js';
import { errorHandler } from './middlewares/errorHandler.js';
import { NotFoundError } from './utils/errors.js';
import apiRouter from './routes/index.js';

export const createApp = () => {
  const app = express();

  // Middlewares de seguridad y observabilidad
  app.use(helmet());
  app.use(cors({ origin: env.CORS_ORIGIN }));
  app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Endpoint de salud (Crítico para monitor de Render y DevOps)
  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      environment: env.NODE_ENV
    });
  });

  // Ruta raíz informativa
  app.get('/', (req, res) => {
    res.status(200).json({
      name: 'Personal Finance API',
      version: '1.0.0',
      description: 'API de gestión financiera personal y móvil',
      documentation: '/api/v1',
      endpoints: {
        health: '/health',
        dashboard: '/api/v1/dashboard',
        incomes: '/api/v1/incomes',
        debts: '/api/v1/debts',
        categories: '/api/v1/categories',
        expenses: '/api/v1/expenses',
        savings: '/api/v1/savings'
      }
    });
  });

  // Rutas de la API (v1)
  app.use('/api/v1', apiRouter);

  // Manejo de rutas inexistentes (404)
  app.use((req, res, next) => {
    next(new NotFoundError(`Ruta no encontrada: ${req.method} ${req.originalUrl}`));
  });

  // Middleware de error centralizado
  app.use(errorHandler);

  return app;
};
