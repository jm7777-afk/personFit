import { env } from '../config/env.js';

export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const status = err.status || 'error';

  const response = {
    status,
    message: err.message || 'Error interno del servidor'
  };

  if (err.details) {
    response.details = err.details;
  }

  if (env.NODE_ENV === 'development') {
    response.stack = err.stack;
  }

  if (statusCode === 500) {
    console.error('💥 ERROR INESPERADO:', err);
  }

  res.status(statusCode).json(response);
};
