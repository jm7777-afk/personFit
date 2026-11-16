import { incomeRepository } from '../repositories/incomeRepository.js';
import { NotFoundError } from '../utils/errors.js';

export class IncomeService {
  getAllIncomes(filters) {
    return incomeRepository.findAll(filters);
  }

  getIncomeById(id) {
    const income = incomeRepository.findById(id);
    if (!income) {
      throw new NotFoundError(`Ingreso con id ${id} no encontrado`);
    }
    return income;
  }

  createIncome(data) {
    return incomeRepository.create(data);
  }

  updateIncome(id, data) {
    this.getIncomeById(id);
    return incomeRepository.update(id, data);
  }

  deleteIncome(id) {
    this.getIncomeById(id);
    return incomeRepository.delete(id);
  }
}

export const incomeService = new IncomeService();
