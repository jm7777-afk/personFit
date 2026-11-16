import { Router } from 'express';
import incomeRoutes from './incomeRoutes.js';
import debtRoutes from './debtRoutes.js';
import categoryRoutes from './categoryRoutes.js';
import expenseRoutes from './expenseRoutes.js';
import savingsRoutes from './savingsRoutes.js';
import dashboardRoutes from './dashboardRoutes.js';

const apiRouter = Router();

apiRouter.use('/incomes', incomeRoutes);
apiRouter.use('/debts', debtRoutes);
apiRouter.use('/categories', categoryRoutes);
apiRouter.use('/expenses', expenseRoutes);
apiRouter.use('/savings', savingsRoutes);
apiRouter.use('/dashboard', dashboardRoutes);

export default apiRouter;
