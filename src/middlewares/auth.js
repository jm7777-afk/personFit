import { verifyToken } from '../utils/auth.js';
import { AppError } from '../utils/errors.js';
import { db } from '../config/database.js';

export const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('Acceso denegado. Token no proporcionado', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);

    const user = db.prepare('SELECT id, name, email, avatar, created_at FROM users WHERE id = ?').get(decoded.id);
    if (!user) {
      throw new AppError('El usuario del token ya no existe', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return next(new AppError('Token inválido o expirado. Por favor inicia sesión nuevamente', 401));
    }
    next(error);
  }
};
