import { Router } from 'express';
import { authController } from '../controllers/authController.js';
import { validate } from '../middlewares/validate.js';
import { registerSchema, loginSchema, updateProfileSchema } from '../schemas/authSchema.js';
import { authenticate } from '../middlewares/auth.js';

const router = Router();

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);

router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), authController.updateProfile);

export default router;
