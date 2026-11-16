import { userRepository } from '../repositories/userRepository.js';
import { hashPassword, comparePassword, generateToken } from '../utils/auth.js';
import { AppError, ConflictError, NotFoundError } from '../utils/errors.js';

export class AuthService {
  async register(data) {
    const existing = userRepository.findByEmail(data.email);
    if (existing) {
      throw new ConflictError('Ya existe una cuenta con este correo electrónico');
    }

    const passwordHash = await hashPassword(data.password);
    const user = userRepository.create({
      name: data.name,
      email: data.email,
      password_hash: passwordHash,
      avatar: data.avatar || null
    });

    const token = generateToken({ id: user.id, email: user.email });

    return { user, token };
  }

  async login(email, password) {
    const user = userRepository.findByEmail(email);
    if (!user) {
      throw new AppError('Credenciales incorrectas', 401);
    }

    const isValid = await comparePassword(password, user.password_hash);
    if (!isValid) {
      throw new AppError('Credenciales incorrectas', 401);
    }

    const token = generateToken({ id: user.id, email: user.email });
    const userSafe = {
      id: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      created_at: user.created_at
    };

    return { user: userSafe, token };
  }

  async updateProfile(userId, data) {
    const user = userRepository.findById(userId);
    if (!user) throw new NotFoundError('Usuario no encontrado');

    const updateData = {};
    if (data.name) updateData.name = data.name;
    if (data.avatar !== undefined) updateData.avatar = data.avatar;

    if (data.new_password) {
      if (!data.current_password) {
        throw new AppError('Debes ingresar tu contraseña actual para cambiarla', 400);
      }
      const fullUser = userRepository.findByEmail(user.email);
      const isMatch = await comparePassword(data.current_password, fullUser.password_hash);
      if (!isMatch) {
        throw new AppError('La contraseña actual es incorrecta', 400);
      }
      updateData.password_hash = await hashPassword(data.new_password);
    }

    return userRepository.update(userId, updateData);
  }
}

export const authService = new AuthService();
