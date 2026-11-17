import crypto from 'crypto';
import { db } from '../config/database.js';
import { dashboardService } from './dashboardService.js';
import { payrollService } from './payrollService.js';

export const shareService = {
  // Crear enlace / token de perfil temporal compartido
  createShareToken(userId, durationMinutes = 60) {
    // Validar duración mínima 5 min y máxima 7 días (10080 min)
    const minutes = Math.max(5, Math.min(10080, parseInt(durationMinutes, 10) || 60));
    const token = crypto.randomBytes(16).toString('hex');
    const expiresAt = new Date(Date.now() + minutes * 60 * 1000).toISOString();

    const stmt = db.prepare(`
      INSERT INTO financial_shares (user_id, share_token, duration_minutes, expires_at, is_active)
      VALUES (?, ?, ?, ?, 1)
    `);
    const info = stmt.run(userId, token, minutes, expiresAt);

    return {
      id: info.lastInsertRowid,
      share_token: token,
      duration_minutes: minutes,
      expires_at: expiresAt,
      share_url: `/api/v1/profile/shared/${token}`
    };
  },

  // Obtener perfil financiero temporal de solo lectura mediante el token
  getSharedProfile(token) {
    const share = db.prepare(`
      SELECT fs.*, u.name as user_name, u.email as user_email
      FROM financial_shares fs
      JOIN users u ON u.id = fs.user_id
      WHERE fs.share_token = ?
    `).get(token);

    if (!share) {
      return { is_valid: false, message: 'Enlace no válido o inexistente.' };
    }

    const now = new Date();
    const expiresAt = new Date(share.expires_at);

    if (share.is_active !== 1 || now >= expiresAt) {
      // Marcar como inactivo si expiró
      if (share.is_active === 1) {
        db.prepare('UPDATE financial_shares SET is_active = 0 WHERE id = ?').run(share.id);
      }
      return {
        is_valid: false,
        is_expired: true,
        message: 'Este enlace temporal de visualización ha expirado y se ha desconectado automáticamente.',
        expired_at: share.expires_at
      };
    }

    // Incrementar contador de visualizaciones
    db.prepare('UPDATE financial_shares SET view_count = view_count + 1 WHERE id = ?').run(share.id);

    const msRemaining = expiresAt.getTime() - now.getTime();
    const minutesRemaining = Math.max(0, Math.floor(msRemaining / (1000 * 60)));
    const secondsRemaining = Math.max(0, Math.floor((msRemaining % (1000 * 60)) / 1000));

    // Obtener datos financieros consolidados del usuario
    const dashboardData = dashboardService.getDashboardData(null, share.user_id);
    const payrollData = payrollService.getPayrollSummary(share.user_id);

    return {
      is_valid: true,
      is_expired: false,
      access_meta: {
        shared_by: share.user_name,
        expires_at: share.expires_at,
        minutes_remaining: minutesRemaining,
        seconds_remaining: secondsRemaining,
        total_duration_minutes: share.duration_minutes,
        view_count: share.view_count + 1
      },
      financial_overview: {
        financial_health_score: dashboardData.financial_health?.score || 100,
        financial_health_status: dashboardData.financial_health?.status || 'Excelente',
        monthly_income: dashboardData.cashflow?.total_income || 0,
        monthly_expenses: dashboardData.cashflow?.total_expenses || 0,
        net_balance: dashboardData.cashflow?.net_balance || 0,
        active_debts_count: dashboardData.debts_overview?.urgent_debts_count || 0,
        total_debt_balance: dashboardData.debts_overview?.total_outstanding_debt || 0,
        total_savings: dashboardData.savings_overview?.total_accumulated_savings || 0,
        rule_50_30_20: dashboardData.budget_rule_50_30_20
      },
      payroll: {
        frequency: payrollData.frequency,
        frequency_label: payrollData.frequency_label,
        days_remaining_to_payout: payrollData.days_remaining,
        next_payout_date: payrollData.next_payout_date,
        expected_salary_usd: payrollData.expected_salary_usd,
        net_remaining_salary_usd: payrollData.net_remaining_usd,
        deductions_count: payrollData.deductions_breakdown.length
      },
      debts_overview: dashboardData.debts_overview?.upcoming_debts || []
    };
  },

  // Obtener enlaces activos del usuario para administrarlos
  getUserShares(userId) {
    const shares = db.prepare(`
      SELECT * FROM financial_shares
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 10
    `).all(userId);

    const now = new Date();
    return shares.map(s => {
      const expiresAt = new Date(s.expires_at);
      const isExpired = s.is_active !== 1 || now >= expiresAt;
      const msRemaining = Math.max(0, expiresAt.getTime() - now.getTime());
      return {
        ...s,
        is_active: isExpired ? 0 : 1,
        minutes_remaining: Math.floor(msRemaining / (1000 * 60)),
        is_expired: isExpired
      };
    });
  },

  // Revocar acceso anticipadamente
  revokeShare(userId, token) {
    const stmt = db.prepare(`
      UPDATE financial_shares 
      SET is_active = 0 
      WHERE user_id = ? AND (share_token = ? OR id = ?)
    `);
    const info = stmt.run(userId, token, parseInt(token, 10) || -1);
    return { success: info.changes > 0 };
  }
};
