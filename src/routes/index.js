import { Router } from 'express';
import { optionalAuthenticate } from '../middlewares/auth.js';
import authRoutes from './authRoutes.js';
import incomeRoutes from './incomeRoutes.js';
import debtRoutes from './debtRoutes.js';
import categoryRoutes from './categoryRoutes.js';
import expenseRoutes from './expenseRoutes.js';
import savingsRoutes from './savingsRoutes.js';
import dashboardRoutes from './dashboardRoutes.js';
import notificationRoutes from './notificationRoutes.js';
import exchangeRateRoutes from './exchangeRateRoutes.js';
import groceryRoutes from './groceryRoutes.js';
import payrollRoutes from './payrollRoutes.js';
import shareRoutes from './shareRoutes.js';
import walletRoutes from './walletRoutes.js';
import installmentRoutes from './installmentRoutes.js';

const apiRouter = Router();

// Inyectar req.user automáticamente en todas las rutas si el cliente envía Bearer token
apiRouter.use(optionalAuthenticate);

apiRouter.use('/auth', authRoutes);
apiRouter.use('/incomes', incomeRoutes);
apiRouter.use('/debts', debtRoutes);
apiRouter.use('/categories', categoryRoutes);
apiRouter.use('/expenses', expenseRoutes);
apiRouter.use('/savings', savingsRoutes);
apiRouter.use('/dashboard', dashboardRoutes);
apiRouter.use('/notifications', notificationRoutes);
apiRouter.use('/rates', exchangeRateRoutes);
apiRouter.use('/groceries', groceryRoutes);
apiRouter.use('/payroll', payrollRoutes);
apiRouter.use('/profile', shareRoutes);
apiRouter.use('/wallets', walletRoutes);
apiRouter.use('/installments', installmentRoutes);

export default apiRouter;
