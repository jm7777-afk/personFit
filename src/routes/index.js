import { Router } from 'express';
import authRoutes from './authRoutes.js';
import incomeRoutes from './incomeRoutes.js';
import debtRoutes from './debtRoutes.js';
import categoryRoutes from './categoryRoutes.js';
import expenseRoutes from './expenseRoutes.js';
import savingsRoutes from './savingsRoutes.js';
import dashboardRoutes from './dashboardRoutes.js';
import notificationRoutes from './notificationRoutes.js';
import exchangeRateRoutes from './exchangeRateRoutes.js';

const apiRouter = Router();

apiRouter.use('/auth', authRoutes);
apiRouter.use('/incomes', incomeRoutes);
apiRouter.use('/debts', debtRoutes);
apiRouter.use('/categories', categoryRoutes);
apiRouter.use('/expenses', expenseRoutes);
apiRouter.use('/savings', savingsRoutes);
apiRouter.use('/dashboard', dashboardRoutes);
apiRouter.use('/notifications', notificationRoutes);
apiRouter.use('/rates', exchangeRateRoutes);

export default apiRouter;
