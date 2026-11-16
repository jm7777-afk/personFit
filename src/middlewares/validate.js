import { BadRequestError } from '../utils/errors.js';

/**
 * Middleware para validar esquemas Zod en body, query o params.
 * @param {import('zod').ZodSchema} schema 
 * @param {'body' | 'query' | 'params'} source 
 */
export const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      const formattedErrors = result.error.errors.map(err => ({
        field: err.path.join('.'),
        message: err.message
      }));
      return next(new BadRequestError('Validación de datos fallida', formattedErrors));
    }

    req[source] = result.data;
    next();
  };
};
