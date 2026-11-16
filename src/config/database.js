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
  addColumnIfNotExists('debts', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('debts', 'paid_at', 'DATETIME');
  addColumnIfNotExists('categories', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('expenses', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('savings_goals', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');

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
};
