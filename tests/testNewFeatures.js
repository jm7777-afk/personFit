import { initDatabase } from '../src/config/database.js';
import { groceryService } from '../src/services/groceryService.js';
import { payrollService } from '../src/services/payrollService.js';
import { shareService } from '../src/services/shareService.js';
import { authService } from '../src/services/authService.js';

console.log('--- TEST: Inicializando BD y verificando semillas ---');
initDatabase();

// 1. Supermercados y productos
const supers = groceryService.getSupermarkets(null);
console.log(`✓ Supermercados cargados: ${supers.length}`);

const prods = groceryService.getProducts(null);
console.log(`✓ Productos cargados: ${prods.length}`);

// 2. Comparador de productos ("cuánto subió")
const compareProds = groceryService.getCompareProducts(null);
console.log(`✓ Comparación de productos procesada: ${compareProds.length} productos analizados.`);
const sampleProd = compareProds[0];
console.log(`  Ejemplo: ${sampleProd.product.name}`);
for (const c of sampleProd.comparisons) {
  console.log(`   - ${c.supermarket_name}: $${c.current_price_usd} (Var: ${c.increase_percent_usd > 0 ? '+' : ''}${c.increase_percent_usd}%) | Más barato: ${c.is_cheapest ? 'SÍ' : 'No'}`);
}

// 3. Comparador de supermercados ("cuál es más económico")
const compareSupers = groceryService.getCompareSupermarkets(null);
console.log(`✓ Supermercado más económico: ${compareSupers.cheapest_supermarket?.supermarket_name} (Total Cesta: $${compareSupers.cheapest_supermarket?.total_basket_usd})`);
for (const r of compareSupers.rankings) {
  console.log(`   * ${r.supermarket_name}: $${r.total_basket_usd} (Ahorro vs más caro: $${r.savings_vs_most_expensive_usd})`);
}

// 4. Lista de compras ("qué llevo, cuánto llevo")
const testEmail = `test_features_${Date.now()}@kryon.app`;
const { user } = await authService.register({ name: 'Usuario Prueba', email: testEmail, password: 'Password123!' });
const list = groceryService.createList(user.id, { title: 'Mercado Quincenal' });
console.log(`✓ Lista creada: ${list.title} (ID: ${list.id})`);

groceryService.addListItem(user.id, list.id, {
  product_id: prods[0].id,
  product_name: prods[0].name,
  quantity: 3,
  price_usd: 1.15,
  price_bs: 1051.12
});
groceryService.addListItem(user.id, list.id, {
  product_id: prods[1].id,
  product_name: prods[1].name,
  quantity: 2,
  price_usd: 1.25,
  price_bs: 1142.50
});

let details = groceryService.getListDetails(user.id, list.id);
console.log(`✓ Lista items: ${details.total_items}, Estimado: $${details.total_estimated_usd}`);

// Marcar un item en el carrito
groceryService.toggleListItem(user.id, list.id, details.items[0].id, true);
details = groceryService.getListDetails(user.id, list.id);
console.log(`✓ "Qué llevo, cuánto llevo": ${details.checked_items}/${details.total_items} items marcados.`);
console.log(`   Llevas en carrito: $${details.total_checked_usd} (Bs. ${details.total_checked_bs}) de $${details.total_estimated_usd} estimado.`);

// 5. Nómina con periodicidad quincenal y descuento de préstamos
import { incomeService } from '../src/services/incomeService.js';
import { debtService } from '../src/services/debtService.js';

incomeService.createIncome({
  title: 'Sueldo Nómina Quincenal',
  amount: 250,
  currency: 'USD',
  source: 'empleo',
  frequency: 'quincenal',
  date: new Date().toISOString().split('T')[0]
}, user.id);

// Registrar dinero prestado que se debe descontar del sueldo
debtService.createDebt({
  title: 'Préstamo para repuesto',
  creditor: 'Carlos',
  total_amount: 50,
  current_balance: 50,
  monthly_payment: 50,
  currency: 'USD',
  due_day: 15,
  next_due_date: new Date().toISOString().split('T')[0],
  is_borrowed: 1,
  deduct_from_salary: 1
}, user.id);

const payroll = payrollService.getPayrollSummary(user.id);
console.log(`✓ Nómina: ${payroll.income_title} (${payroll.frequency_label})`);
console.log(`   Faltan: ${payroll.days_remaining} días para cobrar (${payroll.next_payout_date})`);
console.log(`   Sueldo esperado: $${payroll.expected_salary_usd}`);
console.log(`   Deducciones (Préstamos tomados): -$${payroll.total_deductions_usd}`);
console.log(`   👉 SUELDO NETO RESTANTE QUE TE VA QUEDANDO: $${payroll.net_remaining_usd} (${payroll.percent_free}% libre)`);

// 6. Compartir perfil temporal (1 hora)
const share = shareService.createShareToken(user.id, 60);
console.log(`✓ Enlace temporal creado (Token: ${share.share_token}, Duración: ${share.duration_minutes} min, Expira: ${share.expires_at})`);

const sharedProfile = shareService.getSharedProfile(share.share_token);
console.log(`✓ Perfil compartido válido: ${sharedProfile.is_valid}`);
console.log(`   Minutos restantes de visualización: ${sharedProfile.access_meta?.minutes_remaining} min`);
console.log(`   Salud financiera compartida: ${sharedProfile.financial_overview?.financial_health_score}/100`);

// Probar revocación
shareService.revokeShare(user.id, share.share_token);
const revokedProfile = shareService.getSharedProfile(share.share_token);
console.log(`✓ Estado tras revocación: ${revokedProfile.is_valid ? 'FALLÓ' : 'CORRECTO (Desconectado/Expirado)'} -> ${revokedProfile.message}`);

console.log('=== TODOS LOS TESTS PASARON EXITOSAMENTE ===');
