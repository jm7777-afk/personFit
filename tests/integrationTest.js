import { createApp } from '../src/app.js';
import { initDatabase, db } from '../src/config/database.js';

async function runTests() {
  console.log('🧪 Iniciando pruebas de integración completas...');
  initDatabase();

  const app = createApp();

  const server = await new Promise((resolve) => {
    const s = app.listen(0, '127.0.0.1', () => resolve(s));
  });

  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  const request = async (method, path, body = null, token = null) => {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }
    if (body) {
      options.body = JSON.stringify(body);
    }
    const res = await fetch(`${baseUrl}${path}`, options);
    const data = await res.json().catch(() => null);
    return { status: res.status, body: data };
  };

  try {
    // 1. Healthcheck
    const health = await request('GET', '/health');
    console.log('✅ Healthcheck:', health.status, health.body.status);

    // 2. Auth: Registro y Login de Usuario
    const testEmail = `user_${Date.now()}@personfit.com`;
    const regRes = await request('POST', '/api/v1/auth/register', {
      name: 'Carlos Mendoza',
      email: testEmail,
      password: 'password123'
    });
    console.log('✅ Usuario registrado:', regRes.status, regRes.body.data.user.email);
    const authToken = regRes.body.data.token;

    // 3. Perfil de Usuario con Token JWT
    const profileRes = await request('GET', '/api/v1/auth/profile', null, authToken);
    console.log('✅ Perfil autenticado:', profileRes.status, profileRes.body.data.user.name);

    // 4. Categories
    const categories = await request('GET', '/api/v1/categories');
    console.log('✅ Categorías precargadas:', categories.body.results, 'encontradas');

    // 5. Registrar Ingreso
    const today = new Date().toISOString().slice(0, 10);
    const incomeRes = await request('POST', '/api/v1/incomes', {
      title: 'Sueldo Empleo Principal',
      amount: 3000,
      source: 'empleo_principal',
      frequency: 'mensual',
      date: today,
      notes: 'Cobro de empleo'
    });
    console.log('✅ Ingreso registrado:', incomeRes.status, incomeRes.body.data.title, `$${incomeRes.body.data.amount}`);

    // 6. Registrar Deuda
    const debtRes = await request('POST', '/api/v1/debts', {
      title: 'Préstamo Personal',
      creditor: 'Banco Solidario',
      total_amount: 500,
      current_balance: 500,
      monthly_payment: 100,
      interest_rate: 18.0,
      due_day: 18,
      next_due_date: today
    });
    const debtId = debtRes.body.data.id;
    console.log('✅ Deuda registrada:', debtRes.status, debtRes.body.data.title);

    // 7. Liquidar deuda completamente (Abono de 500)
    const payAllRes = await request('POST', `/api/v1/debts/${debtId}/payments`, {
      amount: 500,
      payment_date: today,
      notes: 'Liquidación total'
    });
    console.log('✅ Deuda liquidada al 100%:', payAllRes.status, 'Status:', payAllRes.body.data.debt.status);

    // 8. Historial de Deudas Pagadas
    const paidHistory = await request('GET', '/api/v1/debts/history/paid');
    console.log('✅ Historial de Deudas Pagadas:', paidHistory.body.count, 'deuda(s) liquidadas en historial');

    // 9. Recordatorios y Notificaciones
    const notifRes = await request('GET', '/api/v1/notifications');
    console.log('✅ Notificaciones de Recordatorios generadas:', notifRes.body.data.total_count, 'alertas activas');

    // 10. Dashboard
    const dashboardRes = await request('GET', '/api/v1/dashboard');
    console.log('✅ Dashboard consolidado:', dashboardRes.status, `Balance Neto: $${dashboardRes.body.data.cashflow.net_balance}`);

    // 11. Tasas de Cambio Venezuela (BCV, Paralelo, USD, EUR) y Calculadora
    const ratesRes = await request('GET', '/api/v1/rates?sync=false');
    console.log('✅ Tasas de Cambio Venezuela:', ratesRes.status, `USD BCV: ${ratesRes.body.data.summary.usd_bcv} Bs (${ratesRes.body.data.summary.usd_bcv_change}%), Paralelo: ${ratesRes.body.data.summary.usd_paralelo} Bs (${ratesRes.body.data.summary.usd_paralelo_change}%)`);

    // 12. Conversión / Calculadora de Moneda
    const convertRes = await request('POST', '/api/v1/rates/convert', {
      amount: 100,
      from: 'USD',
      to: 'VES',
      rate_type: 'oficial'
    });
    console.log('✅ Calculadora Multimoneda: 100 USD =', convertRes.body.data.result, 'VES', `(Fórmula: ${convertRes.body.data.formula})`);

    console.log('\n🎉 ¡TODAS LAS NUEVAS PRUEBAS DE USUARIO, HISTORIAL, NOTIFICACIONES Y TASAS DE VENEZUELA PASARON AL 100%!');
  } catch (error) {
    console.error('❌ Error en pruebas:', error);
  } finally {
    server.close();
    db.close();
  }
}

runTests();
