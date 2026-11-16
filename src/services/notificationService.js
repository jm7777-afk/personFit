import { debtRepository } from '../repositories/debtRepository.js';
import { expenseRepository } from '../repositories/expenseRepository.js';

export class NotificationService {
  getNotifications(userId = null) {
    const notifications = [];

    // 1. Recordatorios de Deudas (Próximos 7 días y vencidas)
    const activeDebts = debtRepository.findAll('activa', userId);
    const today = new Date().toISOString().slice(0, 10);

    for (const debt of activeDebts) {
      const dueDate = debt.next_due_date;
      const diffTime = new Date(dueDate).getTime() - new Date(today).getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays < 0) {
        // Deuda Vencida
        notifications.push({
          id: `debt_overdue_${debt.id}`,
          type: 'debt_overdue',
          priority: 'urgent',
          title: '🚨 Cuota de Deuda Vencida',
          message: `La cuota de $${debt.monthly_payment} para "${debt.title}" (${debt.creditor}) venció hace ${Math.abs(diffDays)} día(s). Abona lo antes posible para evitar intereses moratorios.`,
          debt_id: debt.id,
          due_date: debt.next_due_date,
          amount_due: debt.monthly_payment,
          action: 'record_payment'
        });
      } else if (diffDays === 0) {
        // Vence Hoy
        notifications.push({
          id: `debt_due_today_${debt.id}`,
          type: 'debt_due_today',
          priority: 'high',
          title: '⏰ ¡Pago de Deuda Vence HOY!',
          message: `Hoy es el día límite para pagar tu cuota de $${debt.monthly_payment} de "${debt.title}".`,
          debt_id: debt.id,
          due_date: debt.next_due_date,
          amount_due: debt.monthly_payment,
          action: 'record_payment'
        });
      } else if (diffDays <= 5) {
        // Vence en los próximos 5 días
        notifications.push({
          id: `debt_due_soon_${debt.id}`,
          type: 'debt_due_soon',
          priority: 'high',
          title: '📅 Recordatorio de Pago Próximo',
          message: `Tu cuota de $${debt.monthly_payment} para "${debt.title}" vence en ${diffDays} días (${debt.next_due_date}).`,
          debt_id: debt.id,
          due_date: debt.next_due_date,
          amount_due: debt.monthly_payment,
          action: 'record_payment'
        });
      }
    }

    // 2. Facturas de Servicios por vencer
    const upcomingBills = expenseRepository.findUpcomingBills(7);
    for (const bill of upcomingBills) {
      notifications.push({
        id: `bill_due_${bill.id}`,
        type: 'bill_due',
        priority: 'medium',
        title: '💡 Servicio por Pagar',
        message: `El servicio "${bill.title}" vence el ${bill.due_date} por $${bill.amount}.`,
        expense_id: bill.id,
        due_date: bill.due_date,
        amount_due: bill.amount,
        action: 'pay_bill'
      });
    }

    // 3. Celebraciones de Deudas Liquidadas recientemente
    const paidDebts = debtRepository.findPaidHistory(userId);
    for (const paid of paidDebts.slice(0, 3)) {
      notifications.push({
        id: `celebration_${paid.id}`,
        type: 'celebration',
        priority: 'positive',
        title: '🎉 ¡Deuda Liquidada!',
        message: `¡Gran logro! Has pagado completamente tu deuda "${paid.title}". Liberaste $${paid.monthly_payment}/mes de flujo de dinero.`,
        debt_id: paid.id
      });
    }

    return {
      unread_count: notifications.filter(n => n.priority === 'urgent' || n.priority === 'high').length,
      total_count: notifications.length,
      notifications
    };
  }
}

export const notificationService = new NotificationService();
