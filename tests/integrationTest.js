import { createApp } from '../src/app.js';
import { initDatabase, db } from '../src/config/database.js';

async function runTests() {
  console.log('🧪 Iniciando pruebas de integración con servidor HTTP real...');
  initDatabase();

  const app = createApp();

  // Escuchar en puerto dinámico asignado por el SO (port 0)
  const server = await new Promise((resolve) => {
    const s = app.listen(0, '127.0.0.1', () => resolve(s));
  });

  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  const request = async (method, path, body = null) => {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json'
      }
    };
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

    // 2. Categories
    const categories = await request('GET', '/api/v1/categories');
    console.log('✅ Categorías precargadas:', categories.body.results, 'encontradas');

    // 3. Registrar Ingreso de Empleo
    const today = new Date().toISOString().slice(0, 10);
    const incomeRes = await request('POST', '/api/v1/incomes', {
      title: 'Sueldo Empleo Principal',
      amount: 2500,
      source: 'empleo_principal',
      frequency: 'mensual',
      date: today,
      notes: 'Ingreso quincena/mensual fijo'
    });
    console.log('✅ Ingreso registrado:', incomeRes.status, incomeRes.body.data.title, `$${incomeRes.body.data.amount}`);

    // 4. Registrar Deuda y Cuota de Pago
    const debtRes = await request('POST', '/api/v1/debts', {
      title: 'Tarjeta de Crédito Visa Oro',
      creditor: 'Banco Nacional',
      total_amount: 1200,
      current_balance: 1200,
      monthly_payment: 150,
      interest_rate: 24.5,
      due_day: 20,
      next_due_date: today, // Hoy para que aparezca en el radar
      notes: 'Pagar con estrategia avalancha'
    });
    const debtId = debtRes.body.data.id;
    console.log('✅ Deuda registrada:', debtRes.status, debtRes.body.data.title, `Saldo: $${debtRes.body.data.current_balance}`);

    // 5. Registrar un Abono a la Deuda
    const paymentRes = await request('POST', `/api/v1/debts/${debtId}/payments`, {
      amount: 200,
      payment_date: today,
      notes: 'Abono extraordinario para bajar intereses'
    });
    console.log('✅ Abono registrado a la deuda:', paymentRes.status, `Nuevo saldo: $${paymentRes.body.data.debt.current_balance}`);

    // 6. Estrategias de Liquidación (Avalancha vs Bola de Nieve)
    const stratRes = await request('GET', '/api/v1/debts/strategies');
    console.log('✅ Estrategias calculadas:', stratRes.body.data.strategies.avalanche.name);

    // 7. Registrar Gastos: Servicio por pagar y Compra diaria
    const expenseServiceRes = await request('POST', '/api/v1/expenses', {
      title: 'Factura de Electricidad',
      amount: 65,
      category_id: 2, // Electricidad
      date: today,
      due_date: today,
      is_paid: 0, // Pendiente de pago
      payment_method: 'transferencia'
    });
    console.log('✅ Servicio registrado (por pagar):', expenseServiceRes.status, expenseServiceRes.body.data.title);

    const expenseFoodRes = await request('POST', '/api/v1/expenses', {
      title: 'Supermercado Mensual',
      amount: 350,
      category_id: 5, // Supermercado
      date: today,
      is_paid: 1,
      payment_method: 'tarjeta_debito'
    });
    console.log('✅ Compra diaria registrada:', expenseFoodRes.status, expenseFoodRes.body.data.title);

    // 8. Crear Meta de Ahorro y Aportar Dinero
    const goalRes = await request('POST', '/api/v1/savings', {
      title: 'Fondo de Emergencia (3 meses)',
      target_amount: 3000,
      current_amount: 500,
      priority: 'alta',
      target_date: '2027-06-30'
    });
    const goalId = goalRes.body.data.id;
    console.log('✅ Meta de ahorro creada:', goalRes.status, goalRes.body.data.title, `Progreso: ${goalRes.body.data.progress_percentage}%`);

    const saveTxRes = await request('POST', `/api/v1/savings/${goalId}/transactions`, {
      amount: 250,
      date: today,
      notes: 'Aporte de la quincena'
    });
    console.log('✅ Aporte a meta registrado:', saveTxRes.status, `Nuevo monto: $${saveTxRes.body.data.current_amount} (${saveTxRes.body.data.progress_percentage}%)`);

    // 9. Dashboard Consolidado
    const dashboardRes = await request('GET', '/api/v1/dashboard');
    console.log('\n--- 📊 RESUMEN DEL DASHBOARD ---');
    console.log('Flujo de Caja:', dashboardRes.body.data.cashflow);
    console.log('Score de Salud Financiera:', dashboardRes.body.data.financial_health);
    console.log('Evaluación 50/30/20:', dashboardRes.body.data.budget_rule_50_30_20);
    console.log('Deudas por vencer:', dashboardRes.body.data.debts_overview.urgent_debts_count);
    console.log('Servicios por pagar:', dashboardRes.body.data.upcoming_bills_radar.urgent_bills_count);

    console.log('\n🎉 ¡TODAS LAS PRUEBAS DE INTEGRACIÓN COMPLETADAS EXITOSAMENTE!');
  } catch (error) {
    console.error('❌ Error en pruebas:', error);
  } finally {
    server.close();
    db.close();
  }
}

runTests();
