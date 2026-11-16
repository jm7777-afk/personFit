import { savingsRepository } from '../repositories/savingsRepository.js';
import { NotFoundError } from '../utils/errors.js';

export class SavingsService {
  getAllGoals() {
    return savingsRepository.findAll();
  }

  getGoalById(id) {
    const goal = savingsRepository.findById(id);
    if (!goal) {
      throw new NotFoundError(`Meta de ahorro con id ${id} no encontrada`);
    }
    return goal;
  }

  createGoal(data) {
    return savingsRepository.create(data);
  }

  updateGoal(id, data) {
    this.getGoalById(id);
    return savingsRepository.update(id, data);
  }

  deleteGoal(id) {
    this.getGoalById(id);
    return savingsRepository.delete(id);
  }

  recordTransaction(id, txData) {
    this.getGoalById(id);
    return savingsRepository.recordTransaction(id, txData);
  }

  getTransactions(id) {
    this.getGoalById(id);
    return savingsRepository.getTransactions(id);
  }
}

export const savingsService = new SavingsService();
