import { initDatabase } from '../src/config/database.js';
import { groceryService } from '../src/services/groceryService.js';

console.log('--- TEST: Verificando datos y filtros de Supermercados Carabobo ---');
initDatabase();

// 1. Ubicaciones
const locations = groceryService.getLocations(null);
console.log(`✓ Ubicaciones obtenidas. Estado actual: ${locations.current_state}`);
console.log(`✓ Total supermercados Carabobo: ${locations.total_supermarkets_carabobo}`);
const carabobo = locations.states.find(s => s.state === 'Carabobo');
console.log('✓ Municipios con conteo en Carabobo:');
for (const m of carabobo.municipalities.filter(m => m.supermarkets_count > 0)) {
  console.log(`   - ${m.name}: ${m.supermarkets_count} supermercados`);
}

// 2. Filtros por Municipio
const valenciaSupers = groceryService.getSupermarkets(null, { state: 'Carabobo', municipality: 'Valencia' });
console.log(`\n✓ Supermercados en Valencia: ${valenciaSupers.length}`);
for (const s of valenciaSupers) {
  console.log(`   * ${s.name} (${s.branch || 'Principal'}) - Dir: ${s.address?.substring(0, 45)}...`);
  console.log(`     Perfil: ${s.description?.substring(0, 60)}...`);
}

const naguanaguaSupers = groceryService.getSupermarkets(null, { state: 'Carabobo', municipality: 'Naguanagua' });
console.log(`\n✓ Supermercados en Naguanagua: ${naguanaguaSupers.length}`);
for (const s of naguanaguaSupers) {
  console.log(`   * ${s.name} (${s.branch}) - ${s.phone || 'Sin tel'} - ${s.opening_hours}`);
}

const sanDiegoSupers = groceryService.getSupermarkets(null, { state: 'Carabobo', municipality: 'San Diego' });
console.log(`\n✓ Supermercados en San Diego: ${sanDiegoSupers.length}`);
for (const s of sanDiegoSupers) {
  console.log(`   * ${s.name} (${s.branch})`);
}

// 3. Búsqueda por descripción / características
const gourmetSupers = groceryService.getSupermarkets(null, { search: 'gourmet' });
console.log(`\n✓ Búsqueda por término 'gourmet': ${gourmetSupers.length} encontrados.`);
for (const s of gourmetSupers) {
  console.log(`   * ${s.name} (${s.branch}) en ${s.municipality}`);
}

// 4. Comparador de supermercados filtrado por Carabobo / Valencia
const valenciaCompare = groceryService.getCompareSupermarkets(null, { state: 'Carabobo', municipality: 'Valencia' });
console.log(`\n✓ Comparador en Valencia: Más económico -> ${valenciaCompare.cheapest_supermarket?.supermarket_name} (${valenciaCompare.cheapest_supermarket?.branch}) - Total Cesta: $${valenciaCompare.cheapest_supermarket?.total_basket_usd}`);
for (const r of valenciaCompare.rankings) {
  console.log(`   - ${r.supermarket_name} (${r.branch}): $${r.total_basket_usd} (${r.municipality}) | Ahorro: $${r.savings_vs_most_expensive_usd}`);
}

console.log('\n=== TEST CARABOBO COMPLETADO EXITOSAMENTE ===');
