import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import { env } from './env.js';

const dbPath = path.resolve(env.DATABASE_URL);
const dbDir = path.dirname(dbPath);

if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

export const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

export const initDatabase = () => {
  const schema = `
    -- Usuarios
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      avatar TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Ingresos
    CREATE TABLE IF NOT EXISTS incomes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      source TEXT NOT NULL,
      frequency TEXT NOT NULL DEFAULT 'mensual',
      date TEXT NOT NULL,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Deudas y Pasivos
    CREATE TABLE IF NOT EXISTS debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      title TEXT NOT NULL,
      creditor TEXT NOT NULL,
      total_amount REAL NOT NULL,
      current_balance REAL NOT NULL,
      monthly_payment REAL NOT NULL,
      interest_rate REAL DEFAULT 0,
      due_day INTEGER NOT NULL,
      next_due_date TEXT NOT NULL,
      status TEXT DEFAULT 'activa', -- 'activa', 'pagada', 'refinanciada'
      paid_at DATETIME, -- Fecha en que se liquidó completamente
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Historial de pagos de deudas
    CREATE TABLE IF NOT EXISTS debt_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debt_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE
    );

    -- Categorías de gastos y servicios
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER, -- NULL para categorías globales predeterminadas
      name TEXT NOT NULL,
      type TEXT NOT NULL, -- 'servicio', 'compra', 'obligatorio', 'deseo'
      icon TEXT,
      monthly_budget REAL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Gastos y Servicios (Compras diarias o facturas fijas)
    CREATE TABLE IF NOT EXISTS expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      due_date TEXT,
      is_paid INTEGER DEFAULT 1, -- 1: pagado, 0: pendiente
      payment_method TEXT DEFAULT 'efectivo',
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
    );

    -- Metas de Ahorro
    CREATE TABLE IF NOT EXISTS savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      title TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      target_date TEXT,
      priority TEXT DEFAULT 'media', -- 'alta', 'media', 'baja'
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Aportes / Retiros de Ahorro
    CREATE TABLE IF NOT EXISTS savings_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (goal_id) REFERENCES savings_goals(id) ON DELETE CASCADE
    );

    -- Tasas de Cambio Venezuela (BCV, Paralelo, USD, EUR)
    CREATE TABLE IF NOT EXISTS exchange_rates (
      id TEXT PRIMARY KEY, -- 'usd_oficial', 'usd_paralelo', 'eur_oficial', 'eur_paralelo'
      currency TEXT NOT NULL, -- 'USD', 'EUR'
      provider TEXT NOT NULL, -- 'oficial', 'paralelo'
      name TEXT NOT NULL,
      rate REAL NOT NULL,
      previous_rate REAL NOT NULL,
      change_percent REAL NOT NULL DEFAULT 0,
      last_updated TEXT NOT NULL
    );

    -- Supermercados
    CREATE TABLE IF NOT EXISTS supermarkets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER, -- NULL para supermercados predeterminados del sistema
      name TEXT NOT NULL,
      branch TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Productos de supermercado
    CREATE TABLE IF NOT EXISTS grocery_products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER, -- NULL para productos predeterminados globales
      name TEXT NOT NULL,
      category TEXT DEFAULT 'Alimentos',
      unit TEXT DEFAULT 'unidad', -- 'kg', 'lt', 'unidad', 'paquete', 'cartón'
      barcode TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Historial de precios por producto y supermercado
    CREATE TABLE IF NOT EXISTS grocery_prices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      supermarket_id INTEGER NOT NULL,
      price_bs REAL NOT NULL,
      price_usd REAL NOT NULL,
      date TEXT NOT NULL,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (product_id) REFERENCES grocery_products(id) ON DELETE CASCADE,
      FOREIGN KEY (supermarket_id) REFERENCES supermarkets(id) ON DELETE CASCADE
    );

    -- Listas de compras de supermercado ("Qué llevo, cuánto llevo")
    CREATE TABLE IF NOT EXISTS grocery_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      supermarket_id INTEGER,
      status TEXT DEFAULT 'activa', -- 'activa', 'completada'
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (supermarket_id) REFERENCES supermarkets(id) ON DELETE SET NULL
    );

    -- Ítems de la lista de compras
    CREATE TABLE IF NOT EXISTS grocery_list_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      list_id INTEGER NOT NULL,
      product_id INTEGER,
      product_name TEXT NOT NULL,
      quantity REAL DEFAULT 1,
      unit TEXT DEFAULT 'unidad',
      price_bs REAL DEFAULT 0,
      price_usd REAL DEFAULT 0,
      is_checked INTEGER DEFAULT 0, -- 1: ya en el carrito / comprado
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (list_id) REFERENCES grocery_lists(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES grocery_products(id) ON DELETE SET NULL
    );

    -- Perfiles financieros compartidos temporalmente (con expiración)
    CREATE TABLE IF NOT EXISTS financial_shares (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      share_token TEXT NOT NULL UNIQUE,
      duration_minutes INTEGER NOT NULL,
      expires_at TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      view_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `;

  db.exec(schema);

  // Migraciones seguras para bases de datos existentes: agregar columnas si no existen
  const addColumnIfNotExists = (tableName, columnName, columnDef) => {
    const columns = db.pragma(`table_info(${tableName})`);
    const exists = columns.some(c => c.name === columnName);
    if (!exists) {
      db.exec(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnDef}`);
    }
  };

  addColumnIfNotExists('incomes', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('incomes', 'currency', "TEXT DEFAULT 'USD'");
  addColumnIfNotExists('incomes', 'next_payout_date', 'TEXT');
  addColumnIfNotExists('incomes', 'day_of_month', 'INTEGER');

  addColumnIfNotExists('debts', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('debts', 'paid_at', 'DATETIME');
  addColumnIfNotExists('debts', 'currency', "TEXT DEFAULT 'USD'");
  addColumnIfNotExists('debts', 'deduct_from_salary', 'INTEGER DEFAULT 0');
  addColumnIfNotExists('debts', 'is_borrowed', 'INTEGER DEFAULT 0');

  addColumnIfNotExists('categories', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('expenses', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('expenses', 'currency', "TEXT DEFAULT 'USD'");
  addColumnIfNotExists('savings_goals', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');

  // Semilla de tasas de cambio predeterminadas
  const ratesCount = db.prepare('SELECT COUNT(*) as count FROM exchange_rates').get().count;
  if (ratesCount === 0) {
    const defaultRates = [
      { id: 'usd_oficial', currency: 'USD', provider: 'oficial', name: 'Dólar BCV Oficial', rate: 914.02, previous_rate: 911.20, change_percent: 0.31, last_updated: new Date().toISOString() },
      { id: 'usd_paralelo', currency: 'USD', provider: 'paralelo', name: 'Dólar Paralelo / Monitor', rate: 1045.50, previous_rate: 1032.00, change_percent: 1.31, last_updated: new Date().toISOString() },
      { id: 'eur_oficial', currency: 'EUR', provider: 'oficial', name: 'Euro BCV Oficial', rate: 1010.56, previous_rate: 1005.10, change_percent: 0.54, last_updated: new Date().toISOString() },
      { id: 'eur_paralelo', currency: 'EUR', provider: 'paralelo', name: 'Euro Paralelo', rate: 1120.00, previous_rate: 1110.00, change_percent: 0.90, last_updated: new Date().toISOString() }
    ];

    const insertRate = db.prepare(`
      INSERT INTO exchange_rates (id, currency, provider, name, rate, previous_rate, change_percent, last_updated)
      VALUES (@id, @currency, @provider, @name, @rate, @previous_rate, @change_percent, @last_updated)
    `);

    const insertAllRates = db.transaction((rates) => {
      for (const r of rates) insertRate.run(r);
    });

    insertAllRates(defaultRates);
  }

  // Semilla de categorías predeterminadas
  const count = db.prepare('SELECT COUNT(*) as count FROM categories WHERE user_id IS NULL').get().count;
  if (count === 0) {
    const defaultCategories = [
      { name: 'Vivienda y Alquiler', type: 'obligatorio', icon: 'home', monthly_budget: 0 },
      { name: 'Electricidad y Gas', type: 'servicio', icon: 'zap', monthly_budget: 0 },
      { name: 'Agua Potable', type: 'servicio', icon: 'droplet', monthly_budget: 0 },
      { name: 'Internet y Teléfono', type: 'servicio', icon: 'wifi', monthly_budget: 0 },
      { name: 'Supermercado y Alimentos', type: 'obligatorio', icon: 'shopping-cart', monthly_budget: 0 },
      { name: 'Transporte y Combustible', type: 'obligatorio', icon: 'truck', monthly_budget: 0 },
      { name: 'Salud y Farmacia', type: 'obligatorio', icon: 'activity', monthly_budget: 0 },
      { name: 'Suscripciones (Streaming/Software)', type: 'servicio', icon: 'tv', monthly_budget: 0 },
      { name: 'Restaurantes y Ocio', type: 'deseo', icon: 'coffee', monthly_budget: 0 },
      { name: 'Compras Personales y Ropa', type: 'compra', icon: 'tag', monthly_budget: 0 },
      { name: 'Gastos Imprevistos', type: 'obligatorio', icon: 'alert-circle', monthly_budget: 0 }
    ];

    const insertCat = db.prepare(`
      INSERT INTO categories (name, type, icon, monthly_budget, user_id)
      VALUES (@name, @type, @icon, @monthly_budget, NULL)
    `);

    const insertMany = db.transaction((cats) => {
      for (const cat of cats) insertCat.run(cat);
    });

    insertMany(defaultCategories);
  }

  // Semilla de Supermercados predeterminados
  const superCount = db.prepare('SELECT COUNT(*) as count FROM supermarkets WHERE user_id IS NULL').get().count;
  if (superCount === 0) {
    const defaultSupermarkets = [
      { name: 'Gama Supermercados', branch: 'Sucursal Principal' },
      { name: 'Central Madeirense', branch: 'Hipermercado' },
      { name: "Automercados Plaza's", branch: 'Sucursal Expreso' },
      { name: 'Unicasa', branch: 'Centro' },
      { name: 'Río Supermercado', branch: 'General' }
    ];

    const insertSuper = db.prepare('INSERT INTO supermarkets (name, branch, user_id) VALUES (@name, @branch, NULL)');
    const insertAllSupers = db.transaction((supers) => {
      for (const s of supers) insertSuper.run(s);
    });
    insertAllSupers(defaultSupermarkets);
  }

  // Semilla de Productos básicos de supermercado
  const prodCount = db.prepare('SELECT COUNT(*) as count FROM grocery_products WHERE user_id IS NULL').get().count;
  if (prodCount === 0) {
    const defaultProducts = [
      { name: 'Harina PAN Blanca (1 kg)', category: 'Víveres', unit: 'paquete' },
      { name: 'Arroz Blanco Primor (1 kg)', category: 'Víveres', unit: 'paquete' },
      { name: 'Pasta Larga Spaghetti Capri (1 kg)', category: 'Víveres', unit: 'paquete' },
      { name: 'Aceite Vegetal Mazeite (1 L)', category: 'Víveres', unit: 'botella' },
      { name: 'Leche Entera Líquida (1 L)', category: 'Lácteos', unit: 'litro' },
      { name: 'Huevos Blancos (Cartón 30 und)', category: 'Proteínas', unit: 'cartón' },
      { name: 'Pollo Entero Beneficiado (1 kg)', category: 'Proteínas', unit: 'kg' },
      { name: 'Carne Molida de Primera (1 kg)', category: 'Proteínas', unit: 'kg' },
      { name: 'Queso Blanco Llanero (1 kg)', category: 'Lácteos', unit: 'kg' },
      { name: 'Café Molido Fama de América (250 g)', category: 'Víveres', unit: 'paquete' },
      { name: 'Azúcar Blanca Refinada (1 kg)', category: 'Víveres', unit: 'paquete' },
      { name: 'Atún en Lata Margarita (140 g)', category: 'Enlatados', unit: 'lata' }
    ];

    const insertProd = db.prepare('INSERT INTO grocery_products (name, category, unit, user_id) VALUES (@name, @category, @unit, NULL)');
    const insertAllProds = db.transaction((prods) => {
      for (const p of prods) insertProd.run(p);
    });
    insertAllProds(defaultProducts);

    // Semilla de Precios de Comparación iniciales (Precios anteriores vs Precios actuales en diferentes supermercados)
    const prods = db.prepare('SELECT id, name FROM grocery_products').all();
    const supers = db.prepare('SELECT id, name FROM supermarkets').all();

    if (supers.length >= 2 && prods.length > 0) {
      const gamaId = supers.find(s => s.name.includes('Gama'))?.id || supers[0].id;
      const centralId = supers.find(s => s.name.includes('Central'))?.id || supers[1].id;
      const plazasId = supers.find(s => s.name.includes("Plaza's"))?.id || (supers[2] ? supers[2].id : supers[0].id);

      const bcvRate = 914.02;
      const datePast = new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const dateNow = new Date().toISOString().split('T')[0];

      const insertPrice = db.prepare(`
        INSERT INTO grocery_prices (product_id, supermarket_id, price_bs, price_usd, date, notes)
        VALUES (@product_id, @supermarket_id, @price_bs, @price_usd, @date, @notes)
      `);

      const priceEntries = [];

      for (const p of prods) {
        let baseUsd = 2.50;
        if (p.name.includes('Harina PAN')) baseUsd = 1.10;
        else if (p.name.includes('Arroz')) baseUsd = 1.25;
        else if (p.name.includes('Pasta')) baseUsd = 1.40;
        else if (p.name.includes('Aceite')) baseUsd = 3.60;
        else if (p.name.includes('Leche')) baseUsd = 2.10;
        else if (p.name.includes('Huevos')) baseUsd = 4.80;
        else if (p.name.includes('Pollo')) baseUsd = 3.20;
        else if (p.name.includes('Carne')) baseUsd = 7.50;
        else if (p.name.includes('Queso')) baseUsd = 5.20;
        else if (p.name.includes('Café')) baseUsd = 2.80;
        else if (p.name.includes('Azúcar')) baseUsd = 1.35;
        else if (p.name.includes('Atún')) baseUsd = 1.80;

        // Precio anterior en Gama (hace 15 días)
        const oldGamaUsd = +(baseUsd * 0.92).toFixed(2);
        priceEntries.push({
          product_id: p.id,
          supermarket_id: gamaId,
          price_usd: oldGamaUsd,
          price_bs: +(oldGamaUsd * 880).toFixed(2),
          date: datePast,
          notes: 'Compra anterior'
        });

        // Precio actual en Gama (+8% a +12%)
        const nowGamaUsd = +(baseUsd * 1.02).toFixed(2);
        priceEntries.push({
          product_id: p.id,
          supermarket_id: gamaId,
          price_usd: nowGamaUsd,
          price_bs: +(nowGamaUsd * bcvRate).toFixed(2),
          date: dateNow,
          notes: 'Precio actual'
        });

        // Precio actual en Central Madeirense (más económico en víveres)
        const nowCentralUsd = +(baseUsd * 0.97).toFixed(2);
        priceEntries.push({
          product_id: p.id,
          supermarket_id: centralId,
          price_usd: nowCentralUsd,
          price_bs: +(nowCentralUsd * bcvRate).toFixed(2),
          date: dateNow,
          notes: 'Precio actual'
        });

        // Precio actual en Plaza's
        const nowPlazasUsd = +(baseUsd * 1.08).toFixed(2);
        priceEntries.push({
          product_id: p.id,
          supermarket_id: plazasId,
          price_usd: nowPlazasUsd,
          price_bs: +(nowPlazasUsd * bcvRate).toFixed(2),
          date: dateNow,
          notes: 'Precio actual'
        });
      }

      const insertAllPrices = db.transaction((prices) => {
        for (const pr of prices) insertPrice.run(pr);
      });
      insertAllPrices(priceEntries);
    }
  }
};
