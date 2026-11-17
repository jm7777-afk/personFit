import { Router } from 'express';
import { shareController } from '../controllers/shareController.js';
import { authenticate } from '../middlewares/auth.js';

const router = Router();

// Endpoint público con token temporal (verifica expiración estricta)
router.get('/shared/:token', shareController.getSharedProfile);

// Endpoints autenticados del usuario dueño
router.post('/share', authenticate, shareController.createShare);
router.get('/shares', authenticate, shareController.getUserShares);
router.post('/shares/:token/revoke', authenticate, shareController.revokeShare);

export default router;
