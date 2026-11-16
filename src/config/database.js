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

// Habilitar Foreign Keys y modo WAL para alta concurrencia y velocidad
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

export const initDatabase = () => {
  const schema = `
    -- Ingresos
    CREATE TABLE IF NOT EXISTS incomes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      source TEXT NOT NULL,
      frequency TEXT NOT NULL DEFAULT 'mensual',
      date TEXT NOT NULL,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Deudas y Pasivos
    CREATE TABLE IF NOT EXISTS debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      creditor TEXT NOT NULL,
      total_amount REAL NOT NULL,
      current_balance REAL NOT NULL,
      monthly_payment REAL NOT NULL,
      interest_rate REAL DEFAULT 0,
      due_day INTEGER NOT NULL,
      next_due_date TEXT NOT NULL,
      status TEXT DEFAULT 'activa',
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
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
      name TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL, -- 'servicio', 'compra', 'obligatorio', 'deseo'
      icon TEXT,
      monthly_budget REAL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Gastos y Servicios (Compras diarias o facturas fijas)
    CREATE TABLE IF NOT EXISTS expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      due_date TEXT,
      is_paid INTEGER DEFAULT 1, -- 1: pagado, 0: pendiente
      payment_method TEXT DEFAULT 'efectivo',
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
    );

    -- Metas de Ahorro
    CREATE TABLE IF NOT EXISTS savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      target_date TEXT,
      priority TEXT DEFAULT 'media', -- 'alta', 'media', 'baja'
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
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
  `;

  db.exec(schema);

  // Semilla de categorías predeterminadas si la tabla está vacía
  const count = db.prepare('SELECT COUNT(*) as count FROM categories').get().count;
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
      INSERT INTO categories (name, type, icon, monthly_budget)
      VALUES (@name, @type, @icon, @monthly_budget)
    `);

    const insertMany = db.transaction((cats) => {
      for (const cat of cats) insertCat.run(cat);
    });

    insertMany(defaultCategories);
  }
};
