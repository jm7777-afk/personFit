import { incomeRepository } from '../repositories/incomeRepository.js';
import { NotFoundError } from '../utils/errors.js';

export class IncomeService {
  getAllIncomes(filters, userId = null) {
    return incomeRepository.findAll(filters, userId);
  }

  getIncomeById(id, userId = null) {
    const income = incomeRepository.findById(id, userId);
    if (!income) {
      throw new NotFoundError(`Ingreso con id ${id} no encontrado`);
    }
    return income;
  }

  createIncome(data, userId = null) {
    return incomeRepository.create(data, userId);
  }

  updateIncome(id, data, userId = null) {
    this.getIncomeById(id, userId);
    return incomeRepository.update(id, data, userId);
  }

  deleteIncome(id, userId = null) {
    this.getIncomeById(id, userId);
    return incomeRepository.delete(id);
  }
}

export const incomeService = new IncomeService();
