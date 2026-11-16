import { authService } from '../services/authService.js';

export class AuthController {
  register = async (req, res, next) => {
    try {
      const result = await authService.register(req.body);
      res.status(201).json({
        status: 'success',
        message: 'Usuario registrado exitosamente',
        data: result
      });
    } catch (err) {
      next(err);
    }
  };

  login = async (req, res, next) => {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      res.status(200).json({
        status: 'success',
        message: 'Sesión iniciada correctamente',
        data: result
      });
    } catch (err) {
      next(err);
    }
  };

  getProfile = (req, res) => {
    res.status(200).json({
      status: 'success',
      data: { user: req.user }
    });
  };

  updateProfile = async (req, res, next) => {
    try {
      const updated = await authService.updateProfile(req.user.id, req.body);
      res.status(200).json({
        status: 'success',
        message: 'Perfil actualizado exitosamente',
        data: { user: updated }
      });
    } catch (err) {
      next(err);
    }
  };
}

export const authController = new AuthController();
