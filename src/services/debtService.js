import { debtRepository } from '../repositories/debtRepository.js';
import { NotFoundError, BadRequestError } from '../utils/errors.js';

export class DebtService {
  getAllDebts(status) {
    return debtRepository.findAll(status);
  }

  getDebtById(id) {
    const debt = debtRepository.findById(id);
    if (!debt) {
      throw new NotFoundError(`Deuda con id ${id} no encontrada`);
    }
    return debt;
  }

  createDebt(data) {
    return debtRepository.create(data);
  }

  updateDebt(id, data) {
    this.getDebtById(id);
    return debtRepository.update(id, data);
  }

  deleteDebt(id) {
    this.getDebtById(id);
    return debtRepository.delete(id);
  }

  getUpcomingDebts(days) {
    const d = days ? Number(days) : 15;
    return debtRepository.findUpcoming(d);
  }

  recordPayment(debtId, paymentData) {
    const debt = this.getDebtById(debtId);
    if (debt.status === 'pagada') {
      throw new BadRequestError('Esta deuda ya está completamente pagada');
    }
    return debtRepository.recordPayment(debtId, paymentData);
  }

  getPayments(debtId) {
    this.getDebtById(debtId);
    return debtRepository.getPayments(debtId);
  }

  /**
   * Genera recomendaciones de liquidación:
   * 1. Método Avalancha (Prioriza mayor tasa de interés: ahorra más dinero).
   * 2. Método Bola de Nieve (Prioriza menor saldo pendiente: victorias rápidas).
   */
  getPayoffStrategies() {
    const activeDebts = debtRepository.findAll('activa');
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
