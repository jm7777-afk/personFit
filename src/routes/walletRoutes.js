import { Router } from 'express';
import { walletController } from '../controllers/walletController.js';

const router = Router();

router.get('/', walletController.getWallets);
router.post('/', walletController.createWallet);
router.put('/:id', walletController.updateWallet);
router.delete('/:id', walletController.deleteWallet);

export default router;
