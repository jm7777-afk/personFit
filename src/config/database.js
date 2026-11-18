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

export const CARABOBO_MUNICIPALITIES = [
  'Valencia',
  'Naguanagua',
  'San Diego',
  'Guacara',
  'Los Guayos',
  'Puerto Cabello',
  'Libertador',
  'San Joaquín',
  'Diego Ibarra',
  'Bejuma',
  'Montalbán',
  'Miranda',
  'Carlos Arvelo',
  'Juan José Mora'
];

export const VENEZUELA_LOCATIONS = [
  {
    state: 'Carabobo',
    municipalities: CARABOBO_MUNICIPALITIES
  },
  {
    state: 'Distrito Capital',
    municipalities: ['Libertador', 'Chacao', 'Baruta', 'Sucre', 'El Hatillo']
  },
  {
    state: 'Miranda',
    municipalities: ['Los Salias', 'Guaicaipuro', 'Carrizal', 'Plaza', 'Zamora', 'Baruta', 'Chacao']
  },
  {
    state: 'Aragua',
    municipalities: ['Girardot', 'Mario Briceño Iragorry', 'Santiago Mariño', 'José Félix Ribas', 'Sucre']
  },
  {
    state: 'Zulia',
    municipalities: ['Maracaibo', 'San Francisco', 'Cabimas', 'Lagunillas', 'Santa Rita']
  },
  {
    state: 'Lara',
    municipalities: ['Iribarren', 'Palavecino', 'Torres', 'Morán', 'Jiménez']
  }
];

export const CARABOBO_SUPERMARKETS = [
  {
    name: 'Bio Mercado',
    branch: 'Mañongo',
    state: 'Carabobo',
    municipality: 'Naguanagua',
    address: 'Av. Salvador Feo La Cruz c/c Av. 4, Urb. Mañongo, Naguanagua',
    description: 'Supermercado gourmet y de alta gama con charcutería importada, cortes de carne premium, bodegón exclusivo, cava de vinos y panadería artesanal.',
    phone: '+58 241-8422461',
    opening_hours: 'Lun-Dom: 7:30 AM - 9:00 PM',
    latitude: 10.2335,
    longitude: -68.0067,
    store_type: 'supermercado',
    price_factor: 1.14
  },
  {
    name: 'Bio Mercado',
    branch: 'El Parral',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Río Caroní c/ Av. 137, Urb. El Parral, Valencia Norte',
    description: 'Supermercado premium en la zona norte de Valencia con área de delicateses, sushi bar, bodegón de productos importados y frutas/verduras de primera calidad.',
    phone: '+58 241-8254412',
    opening_hours: 'Lun-Dom: 7:30 AM - 9:00 PM',
    latitude: 10.2148,
    longitude: -68.0205,
    store_type: 'supermercado',
    price_factor: 1.15
  },
  {
    name: 'Hiperlíder',
    branch: 'San Diego',
    state: 'Carabobo',
    municipality: 'San Diego',
    address: 'Av. Don Julio Centeno, Sector Castillito, San Diego (frente a Metrópolis)',
    description: 'Hipermercado de gran formato al mayor y detal con los precios más competitivos en canasta básica, charcutería por volumen, carnes y artículos para el hogar.',
    phone: '+58 241-8716100',
    opening_hours: 'Lun-Sáb: 7:30 AM - 8:30 PM, Dom: 8:00 AM - 7:00 PM',
    latitude: 10.2289,
    longitude: -67.9592,
    store_type: 'hipermercado',
    price_factor: 0.90
  },
  {
    name: 'Hiperlíder',
    branch: 'Los Guayos',
    state: 'Carabobo',
    municipality: 'Los Guayos',
    address: 'Carretera Nacional Valencia-Guacara, Sector Los Guayos',
    description: 'Hipermercado de alto volumen de ventas al mayor y detal para el eje oriental de Carabobo. Máximo ahorro en canasta básica y víveres al mayor.',
    phone: '+58 241-8641122',
    opening_hours: 'Lun-Dom: 8:00 AM - 8:00 PM',
    latitude: 10.1846,
    longitude: -67.9348,
    store_type: 'hipermercado',
    price_factor: 0.89
  },
  {
    name: 'Hiperlíder',
    branch: 'Flor Amarillo',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Principal de Flor Amarillo, Parroquia Rafael Urdaneta, Valencia Sur',
    description: 'Hipermercado con ofertas masivas en víveres al por mayor y detal, carnicería y congelados para el sur de Valencia.',
    phone: '+58 241-8389010',
    opening_hours: 'Lun-Dom: 8:00 AM - 8:00 PM',
    latitude: 10.1452,
    longitude: -67.9535,
    store_type: 'hipermercado',
    price_factor: 0.91
  },
  {
    name: 'Kromi Market',
    branch: 'Prebo',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Andrés Eloy Blanco con Calle 137, Urb. Prebo I, Valencia',
    description: 'Supermercado tradicional de Valencia Norte, reconocido por sus cortes de carnes maduradas, charcutería selecta, panadería fresca y bodegón.',
    phone: '+58 241-8245566',
    opening_hours: 'Lun-Dom: 8:00 AM - 8:30 PM',
    latitude: 10.2112,
    longitude: -68.0168,
    store_type: 'supermercado',
    price_factor: 1.08
  },
  {
    name: 'Kromi Market',
    branch: 'Mañongo (C.C. Vía Veneto)',
    state: 'Carabobo',
    municipality: 'Naguanagua',
    address: 'C.C. Vía Veneto, Nivel Mezzanina, Urb. Mañongo, Naguanagua',
    description: 'Supermercado formato boutique con víveres importados, quesos madurados, cava de licores y atención personalizada.',
    phone: '+58 241-8431050',
    opening_hours: 'Lun-Sáb: 8:00 AM - 8:00 PM, Dom: 9:00 AM - 6:00 PM',
    latitude: 10.2352,
    longitude: -68.0054,
    store_type: 'supermercado',
    price_factor: 1.09
  },
  {
    name: 'Automercados San Diego',
    branch: 'C.C. Fin de Siglo',
    state: 'Carabobo',
    municipality: 'San Diego',
    address: 'Centro Comercial Fin de Siglo, Av. Don Julio Centeno, San Diego',
    description: 'Supermercado referente y de tradición familiar en San Diego con amplia variedad en víveres, frutas, hortalizas frescas y farmacia.',
    phone: '+58 241-8714420',
    opening_hours: 'Lun-Sáb: 7:30 AM - 8:00 PM, Dom: 8:00 AM - 4:00 PM',
    latitude: 10.2384,
    longitude: -67.9571,
    store_type: 'supermercado',
    price_factor: 0.97
  },
  {
    name: 'Automercados San Diego',
    branch: 'El Morro',
    state: 'Carabobo',
    municipality: 'San Diego',
    address: 'Urb. El Morro I, Calle Los Jabillos, San Diego',
    description: 'Supermercado de cercanía y compras ágiles de vecindario, con charcutería fresca, panadería y víveres esenciales.',
    phone: '+58 241-8718890',
    opening_hours: 'Lun-Dom: 8:00 AM - 7:30 PM',
    latitude: 10.2442,
    longitude: -67.9614,
    store_type: 'supermercado',
    price_factor: 0.98
  },
  {
    name: 'Río Supermercado',
    branch: 'Av. Bolívar Norte',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Bolívar Norte, Sector Las Acacias, Valencia',
    description: 'Moderna cadena nacional en formato hipermercado. Gran surtido de marcas nacionales e importadas, cafetería, farmacia y descuentos constantes.',
    phone: '+58 241-8219900',
    opening_hours: 'Lun-Dom: 8:00 AM - 9:00 PM',
    latitude: 10.2036,
    longitude: -68.0049,
    store_type: 'hipermercado',
    price_factor: 1.01
  },
  {
    name: 'Central Madeirense',
    branch: 'La Isabelica',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Este-Oeste 3, Sector La Isabelica, Valencia',
    description: 'Tradicional cadena de supermercados enfocada en la economía familiar y productos de cesta básica a precios accesibles.',
    phone: '+58 241-8342201',
    opening_hours: 'Lun-Sáb: 8:00 AM - 7:30 PM, Dom: 8:30 AM - 3:00 PM',
    latitude: 10.1591,
    longitude: -67.9693,
    store_type: 'supermercado',
    price_factor: 0.95
  },
  {
    name: 'Central Madeirense',
    branch: 'C.C. Cristal',
    state: 'Carabobo',
    municipality: 'Naguanagua',
    address: 'C.C. Cristal, Av. Universidad con Calle 170, Naguanagua',
    description: 'Supermercado céntrico en Naguanagua con víveres, charcutería y artículos del hogar para compras del día a día.',
    phone: '+58 241-8671150',
    opening_hours: 'Lun-Sáb: 8:00 AM - 7:30 PM, Dom: 8:30 AM - 4:00 PM',
    latitude: 10.2415,
    longitude: -68.0079,
    store_type: 'supermercado',
    price_factor: 0.96
  },
  {
    name: 'Super Garzón',
    branch: 'Av. Lara Centro',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Av. Lara cruce con Av. Branger, Centro de Valencia',
    description: 'Hipermercado de alto volumen de ventas en el casco central de Valencia, especializado en combos de comida económicos y compras por bulto.',
    phone: '+58 241-8573310',
    opening_hours: 'Lun-Sáb: 7:30 AM - 7:00 PM, Dom: 8:00 AM - 3:00 PM',
    latitude: 10.1782,
    longitude: -68.0021,
    store_type: 'hipermercado',
    price_factor: 0.92
  },
  {
    name: 'Supermercado Euromax',
    branch: 'El Trigal Norte',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'C.C. Trigal Centro, Av. Atlántico, Urb. El Trigal Norte, Valencia',
    description: 'Supermercado de alta tradición en El Trigal con excelente carnicería, charcutería seleccionada, víveres nacionales e importados y panadería.',
    phone: '+58 241-8428800',
    opening_hours: 'Lun-Dom: 8:00 AM - 8:00 PM',
    latitude: 10.2185,
    longitude: -67.9972,
    store_type: 'supermercado',
    price_factor: 1.04
  },
  {
    name: "Automercados Plaza's",
    branch: 'Puerto Cabello',
    state: 'Carabobo',
    municipality: 'Puerto Cabello',
    address: 'Av. La Paz c/c Calle Puerto Cabello, Sector Rancho Grande, Puerto Cabello',
    description: 'Supermercado de referencia en Puerto Cabello con productos frescos, bodegón importado, cortes de carne premium y pescadería del día.',
    phone: '+58 242-3642100',
    opening_hours: 'Lun-Sáb: 8:00 AM - 8:00 PM, Dom: 8:30 AM - 6:00 PM',
    latitude: 10.4648,
    longitude: -68.0125,
    store_type: 'supermercado',
    price_factor: 1.07
  },
  {
    name: 'Supermercado Luxor',
    branch: 'Guacara Plaza',
    state: 'Carabobo',
    municipality: 'Guacara',
    address: 'Carretera Nacional Valencia-Guacara, C.C. Guacara Plaza, Guacara',
    description: 'Supermercado de gran formato para el municipio Guacara, con gran surtido de víveres populares, carnicería y charcutería económica.',
    phone: '+58 245-5649980',
    opening_hours: 'Lun-Dom: 8:00 AM - 7:30 PM',
    latitude: 10.2256,
    longitude: -67.8781,
    store_type: 'supermercado',
    price_factor: 0.93
  },
  {
    name: 'Makro / Redvital',
    branch: 'Valencia Intercomunal',
    state: 'Carabobo',
    municipality: 'Valencia',
    address: 'Autopista Regional del Centro, Distribuidor San Blas / San Diego, Valencia',
    description: 'Hipermercado mayorista y detal integrado con megatienda de salud Redvital. Ideal para compras familiares en bultos y ahorro a escala.',
    phone: '+58 241-8710000',
    opening_hours: 'Lun-Dom: 8:00 AM - 8:00 PM',
    latitude: 10.1947,
    longitude: -67.9698,
    store_type: 'hipermercado',
    price_factor: 0.91
  }
];

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

    -- Billeteras y Medios de Pago Venezolanos (Bs, Efectivo USD, Binance USDT, Zelle, Zinli/Wally, Euro)
    CREATE TABLE IF NOT EXISTS wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      wallet_type TEXT NOT NULL, -- 'bolivares', 'efectivo_usd', 'binance_usdt', 'zelle', 'zinli_wally', 'euro', 'otro'
      currency TEXT NOT NULL DEFAULT 'USD', -- 'VES', 'USD', 'USDT', 'EUR'
      balance REAL NOT NULL DEFAULT 0,
      account_details TEXT, -- Datos propios para recibir pagos (opcional)
      color TEXT DEFAULT '#6366F1',
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Planes de Compras en Cuotas (Cashea, Krece, Chollo, Crédito Comercial cada 14 días)
    CREATE TABLE IF NOT EXISTS installment_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      provider TEXT NOT NULL DEFAULT 'Cashea',
      merchant_name TEXT NOT NULL,
      title TEXT NOT NULL,
      total_amount REAL NOT NULL,
      initial_paid REAL NOT NULL DEFAULT 0,
      remaining_amount REAL NOT NULL,
      installments_count INTEGER NOT NULL DEFAULT 3,
      interval_days INTEGER NOT NULL DEFAULT 14,
      purchase_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'activa', -- 'activa', 'pagada'
      deduct_from_salary INTEGER DEFAULT 1,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Cuotas Individuales cada 14 días
    CREATE TABLE IF NOT EXISTS installment_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plan_id INTEGER NOT NULL,
      installment_number INTEGER NOT NULL,
      amount REAL NOT NULL,
      due_date TEXT NOT NULL,
      is_paid INTEGER DEFAULT 0,
      paid_at DATETIME,
      FOREIGN KEY (plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE
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
  addColumnIfNotExists('debts', 'payment_method_type', "TEXT DEFAULT 'Pago Móvil'");
  addColumnIfNotExists('debts', 'payment_details', 'TEXT');

  addColumnIfNotExists('categories', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('expenses', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');
  addColumnIfNotExists('expenses', 'currency', "TEXT DEFAULT 'USD'");
  addColumnIfNotExists('savings_goals', 'user_id', 'INTEGER REFERENCES users(id) ON DELETE CASCADE');

  addColumnIfNotExists('supermarkets', 'state', "TEXT DEFAULT 'Carabobo'");
  addColumnIfNotExists('supermarkets', 'municipality', "TEXT DEFAULT 'Valencia'");
  addColumnIfNotExists('supermarkets', 'address', 'TEXT');
  addColumnIfNotExists('supermarkets', 'description', 'TEXT');
  addColumnIfNotExists('supermarkets', 'phone', 'TEXT');
  addColumnIfNotExists('supermarkets', 'opening_hours', 'TEXT');
  addColumnIfNotExists('supermarkets', 'latitude', 'REAL');
  addColumnIfNotExists('supermarkets', 'longitude', 'REAL');
  addColumnIfNotExists('supermarkets', 'store_type', "TEXT DEFAULT 'supermercado'");

  addColumnIfNotExists('grocery_prices', 'barcode', 'TEXT');
  addColumnIfNotExists('grocery_prices', 'reported_by', "TEXT DEFAULT 'Kryon'");
  addColumnIfNotExists('grocery_prices', 'verified_at', 'TEXT');

  // Semilla de tasas de cambio predeterminadas (incluye USDT Binance P2P y Euro BCV)
  const defaultRates = [
    { id: 'usd_oficial', currency: 'USD', provider: 'oficial', name: 'Dólar BCV Oficial', rate: 914.02, previous_rate: 911.20, change_percent: 0.31, last_updated: new Date().toISOString() },
    { id: 'usd_paralelo', currency: 'USD', provider: 'paralelo', name: 'Dólar Paralelo / Monitor', rate: 1045.50, previous_rate: 1032.00, change_percent: 1.31, last_updated: new Date().toISOString() },
    { id: 'usdt_binance', currency: 'USDT', provider: 'binance', name: 'USDT Binance P2P', rate: 1052.00, previous_rate: 1038.50, change_percent: 1.30, last_updated: new Date().toISOString() },
    { id: 'eur_oficial', currency: 'EUR', provider: 'oficial', name: 'Euro BCV Oficial', rate: 1010.56, previous_rate: 1005.10, change_percent: 0.54, last_updated: new Date().toISOString() },
    { id: 'eur_paralelo', currency: 'EUR', provider: 'paralelo', name: 'Euro Paralelo', rate: 1120.00, previous_rate: 1110.00, change_percent: 0.90, last_updated: new Date().toISOString() }
  ];

  const insertRateOrIgnore = db.prepare(`
    INSERT OR IGNORE INTO exchange_rates (id, currency, provider, name, rate, previous_rate, change_percent, last_updated)
    VALUES (@id, @currency, @provider, @name, @rate, @previous_rate, @change_percent, @last_updated)
  `);
  for (const r of defaultRates) insertRateOrIgnore.run(r);

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

  // Limpiar supermercados de prueba antiguos sin dirección ni descripción
  db.prepare('DELETE FROM supermarkets WHERE address IS NULL AND user_id IS NULL').run();

  // Semilla y actualización de Supermercados de Carabobo y Venezuela (con GPS y tipo de tienda)
  const upsertSuper = db.prepare(`
    INSERT INTO supermarkets (name, branch, state, municipality, address, description, phone, opening_hours, latitude, longitude, store_type, user_id)
    VALUES (@name, @branch, @state, @municipality, @address, @description, @phone, @opening_hours, @latitude, @longitude, @store_type, NULL)
  `);

  const updateSuper = db.prepare(`
    UPDATE supermarkets
    SET state = @state, municipality = @municipality, address = @address, description = @description,
        phone = @phone, opening_hours = @opening_hours, latitude = @latitude, longitude = @longitude, store_type = @store_type
    WHERE name = @name AND (branch = @branch OR (@branch IS NULL AND branch IS NULL))
  `);

  const findSuper = db.prepare(`
    SELECT id FROM supermarkets WHERE name = ? AND (branch = ? OR (branch IS NULL AND ? IS NULL))
  `);

  for (const s of CARABOBO_SUPERMARKETS) {
    const existing = findSuper.get(s.name, s.branch, s.branch);
    if (existing) {
      updateSuper.run(s);
    } else {
      upsertSuper.run(s);
    }
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
  }

  // Semilla de Precios de Comparación iniciales (Precios anteriores vs Precios actuales en diferentes supermercados de Carabobo)
  const prods = db.prepare('SELECT id, name FROM grocery_products').all();
  const allSupers = db.prepare("SELECT id, name, branch FROM supermarkets WHERE state = 'Carabobo'").all();

  const pricesCount = db.prepare('SELECT COUNT(*) as count FROM grocery_prices').get().count;
  if (pricesCount < 100 && allSupers.length > 0 && prods.length > 0) {
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

      for (const s of allSupers) {
        const def = CARABOBO_SUPERMARKETS.find(cs => cs.name === s.name && cs.branch === s.branch);
        const factor = def ? def.price_factor : 1.0;

        const currentUsd = +(baseUsd * factor).toFixed(2);
        const pastUsd = +(currentUsd * 0.93).toFixed(2); // ~7% de subida

        const existingNow = db.prepare('SELECT id FROM grocery_prices WHERE product_id = ? AND supermarket_id = ? AND date = ?').get(p.id, s.id, dateNow);
        if (!existingNow) {
          // Precio pasado
          priceEntries.push({
            product_id: p.id,
            supermarket_id: s.id,
            price_usd: pastUsd,
            price_bs: +(pastUsd * 880).toFixed(2),
            date: datePast,
            notes: 'Compra anterior'
          });

          // Precio actual
          priceEntries.push({
            product_id: p.id,
            supermarket_id: s.id,
            price_usd: currentUsd,
            price_bs: +(currentUsd * bcvRate).toFixed(2),
            date: dateNow,
            notes: 'Precio actual verificado'
          });
        }
      }
    }

    if (priceEntries.length > 0) {
      const insertAllPrices = db.transaction((prices) => {
        for (const pr of prices) insertPrice.run(pr);
      });
      insertAllPrices(priceEntries);
    }
  }
};
