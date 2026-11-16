import { debtRepository } from '../repositories/debtRepository.js';
import { NotFoundError, BadRequestError } from '../utils/errors.js';

export class DebtService {
  getAllDebts(status, userId = null) {
    return debtRepository.findAll(status, userId);
  }

  getDebtById(id, userId = null) {
    const debt = debtRepository.findById(id, userId);
    if (!debt) {
      throw new NotFoundError(`Deuda con id ${id} no encontrada`);
    }
    return debt;
  }

  createDebt(data, userId = null) {
    return debtRepository.create(data, userId);
  }

  updateDebt(id, data, userId = null) {
    this.getDebtById(id, userId);
    return debtRepository.update(id, data, userId);
  }

  deleteDebt(id, userId = null) {
    this.getDebtById(id, userId);
    return debtRepository.delete(id, userId);
  }

  getUpcomingDebts(days, userId = null) {
    const d = days ? Number(days) : 15;
    return debtRepository.findUpcoming(d, userId);
  }

  getPaidHistory(userId = null) {
    return debtRepository.findPaidHistory(userId);
  }

  recordPayment(debtId, paymentData, userId = null) {
    const debt = this.getDebtById(debtId, userId);
    if (debt.status === 'pagada') {
      throw new BadRequestError('Esta deuda ya está completamente pagada');
    }
    return debtRepository.recordPayment(debtId, paymentData, userId);
  }

  getPayments(debtId, userId = null) {
    this.getDebtById(debtId, userId);
    return debtRepository.getPayments(debtId);
  }

  getPayoffStrategies(userId = null) {
    const activeDebts = debtRepository.findAll('activa', userId);
    const totalBalance = activeDebts.reduce((acc, d) => acc + d.current_balance, 0);
    const totalMonthlyCommitment = activeDebts.reduce((acc, d) => acc + d.monthly_payment, 0);

    const avalanche = [...activeDebts].sort((a, b) => b.interest_rate - a.interest_rate);
    const snowball = [...activeDebts].sort((a, b) => a.current_balance - b.current_balance);

    return {
      summary: {
        total_active_debts: activeDebts.length,
        total_outstanding_balance: totalBalance,
        total_monthly_commitment: totalMonthlyCommitment
      },
      strategies: {
        avalanche: {
          name: 'Método Avalancha (Recomendado matemáticamente)',
          description: 'Paga el mínimo en todas y enfoca cualquier dinero extra en la de MAYOR tasa de interés. Ahorra el máximo dinero en intereses.',
          priority_order: avalanche.map(d => ({
            id: d.id,
            title: d.title,
            creditor: d.creditor,
            interest_rate: `${d.interest_rate}%`,
            current_balance: d.current_balance,
            monthly_payment: d.monthly_payment
          }))
        },
        snowball: {
          name: 'Método Bola de Nieve (Recomendado para impulso psicológico)',
          description: 'Paga el mínimo en todas y enfoca dinero extra en la de MENOR saldo. Liquidarás la primera deuda rápido, liberando flujo mensual.',
          priority_order: snowball.map(d => ({
            id: d.id,
            title: d.title,
            creditor: d.creditor,
            current_balance: d.current_balance,
            monthly_payment: d.monthly_payment
          }))
        }
      }
    };
  }
}

export const debtService = new DebtService();
