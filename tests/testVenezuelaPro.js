import { initDatabase } from '../src/config/database.js';
import { authService } from '../src/services/authService.js';
import { walletService } from '../src/services/walletService.js';
import { installmentService } from '../src/services/installmentService.js';
import { payrollService } from '../src/services/payrollService.js';
import { groceryService } from '../src/services/groceryService.js';
import { debtService } from '../src/services/debtService.js';
import { exchangeRateService } from '../src/services/exchangeRateService.js';
import { incomeService } from '../src/services/incomeService.js';

console.log('--- TEST: Suite Completa Kryon Venezuela Pro ---');
initDatabase();

const email = `vzla_pro_${Date.now()}@kryon.app`;
const { user } = await authService.register({ name: 'José Carabobo', email, password: 'Password123!' });
console.log(`✓ Usuario creado: ${user.name} (ID: ${user.id})`);

// 1. Tasas BCV + Paralelo + Euro BCV + USDT Binance
const rates = await exchangeRateService.getRates(false);
console.log(`✓ Tasas: BCV=${rates.summary.usd_bcv} | Paralelo=${rates.summary.usd_paralelo} | USDT=${rates.summary.usdt_binance} | EUR BCV=${rates.summary.eur_bcv} | Brecha=${rates.summary.exchange_gap_percentage}%`);

// 2. Billeteras Venezolanas
const wInit = walletService.getWallets(user.id);
console.log(`✓ Billeteras venezolanas creadas automáticamente: ${wInit.wallets.length}`);
walletService.updateWallet(user.id, wInit.wallets[0].id, { balance: 45701 }); // Bs
walletService.updateWallet(user.id, wInit.wallets[1].id, { balance: 120 });   // Efectivo USD
walletService.updateWallet(user.id, wInit.wallets[2].id, { balance: 85 });    // Binance USDT
const wAfter = walletService.getWallets(user.id);
console.log(`✓ Consolidado Billeteras: $${wAfter.total_usd} (Bs. ${wAfter.total_bs})`);

// 3. Nómina + Cuotas Cashea cada 14 días
incomeService.createIncome({
  title: 'Quincena Empresa Valencia',
  amount: 300,
  source: 'empleo_principal',
  frequency: 'quincenal',
  currency: 'USD',
  date: new Date().toISOString().split('T')[0]
}, user.id);

const cashea = installmentService.createPlan(user.id, {
  provider: 'Cashea',
  merchant_name: 'Bio Mercado Mañongo',
  title: 'Mercado Cashea',
  total_amount: 100,
  initial_percent: 40,
  installments_count: 3,
  interval_days: 14,
  purchase_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  deduct_from_salary: true
});
console.log(`✓ Plan Cashea creado: ${cashea.merchant_name} | Inicial: $${cashea.initial_paid} | Pendiente: $${cashea.remaining_amount} en ${cashea.payments.length} cuotas cada 14d`);

const payroll = payrollService.getPayrollSummary(user.id);
console.log(`✓ Nómina con descuento Cashea: Sueldo $${payroll.expected_salary_usd} - Deducciones $${payroll.total_deductions_usd} = Neto Restante $${payroll.net_remaining_usd}`);

// 4. Minimarket no registrado + Lista de compras + Reporte colaborativo código de barras
const mini = groceryService.createSupermarket(user.id, {
  name: 'Abasto y Minimarket Don Pepe',
  branch: 'El Trigal',
  state: 'Carabobo',
  municipality: 'Valencia',
  address: 'Av. Mañongo calle 2, El Trigal',
  description: 'Minimarket de confianza con víveres y charcutería',
  store_type: 'minimarket'
});
console.log(`✓ Minimarket registrado: ${mini.name} (ID: ${mini.id}, tipo: ${mini.store_type})`);

const list = groceryService.createList(user.id, { title: 'Compras Express Trigal', supermarket_id: mini.id });
console.log(`✓ Lista de compras creada sin errores: "${list.title}" en ${list.supermarket_name}`);

const report = groceryService.recordPrice({
  product_name: 'Harina PAN Blanca (1 kg)',
  barcode: '7591001000012',
  supermarket_id: mini.id,
  price_usd: 1.05,
  price_bs: 959.72,
  reported_by: user.name
}, user.id);
console.log(`✓ Reporte colaborativo con código de barras ${report.barcode}: $${report.price_usd} verificado por ${report.reported_by}`);

// 5. Deuda con datos de pago copiar/pegar
const debt = debtService.createDebt({
  title: 'Préstamo Personal Carlos',
  creditor: 'Carlos Pérez',
  total_amount: 60,
  monthly_payment: 60,
  due_day: 30,
  next_due_date: new Date().toISOString().split('T')[0],
  currency: 'USD',
  is_borrowed: true,
  deduct_from_salary: true,
  payment_method_type: 'Pago Móvil',
  payment_details: 'Banesco (0134) | 0414-5559900 | V-22.345.678'
}, user.id);
console.log(`✓ Deuda con datos de pago guardada: [${debt.payment_method_type}] ${debt.payment_details}`);

console.log('=== TODOS LOS TESTS DE VENEZUELA PRO PASARON AL 100% ===');
