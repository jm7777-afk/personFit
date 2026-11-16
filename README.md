# 💰 Personal Finance API (Mobile Backend)

API RESTful profesional construida con **Node.js, Express y SQLite** para respaldar una aplicación móvil de finanzas personales, gestión de deudas, fechas de pago, ingresos, presupuestos por secciones y dashboard ejecutivo.

---

## 🏛️ Arquitectura del Proyecto

El backend sigue una **Clean Layered Architecture** (Arquitectura en Capas) para desacoplar responsabilidades y facilitar migraciones (por ejemplo, pasar de SQLite a PostgreSQL en Render sin tocar la lógica de negocio):

```text
├── src/
│   ├── config/          # Variables de entorno validadas con Zod y conexión SQLite (WAL Mode)
│   ├── schemas/         # Contratos y esquemas de validación con Zod
│   ├── repositories/    # Capa de persistencia y consultas SQL
│   ├── services/        # Reglas de negocio (estrategias anti-deuda, regla 50/30/20, alertas)
│   ├── controllers/     # Controladores HTTP (res/req, códigos semánticos)
│   ├── middlewares/     # Validador Zod, captura centralizada de errores
│   ├── utils/           # Clases AppError, NotFoundError, BadRequestError
│   ├── routes/          # Definición de routers REST (/api/v1)
│   ├── app.js           # Ensamblaje Express con CORS, Helmet y Morgan
│   └── server.js        # Punto de entrada y Graceful Shutdown (SIGTERM/SIGINT)
├── tests/               # Pruebas de integración HTTP
├── .env.example         # Plantilla de variables de entorno
├── .gitignore           # Ignora node_modules, .env y *.db
└── package.json
```

---

## 🚀 Inicio Rápido (Local)

1. **Instalar dependencias:**
   ```bash
   npm install
   ```
2. **Configurar variables de entorno:**
   ```bash
   cp .env.example .env
   ```
3. **Ejecutar en modo desarrollo (con hot-reload nativo):**
   ```bash
   npm run dev
   ```
4. **Ejecutar pruebas de integración:**
   ```bash
   npm test
   ```

El servidor iniciará en `http://localhost:3000`.

---

## 📚 Endpoints de la API (`/api/v1`)

### 1. 🏥 DevOps & Salud
* `GET /health` : Estado del servidor, uptime y ambiente (usado por el monitor de Render).
* `GET /` : Metadatos e índice de la API.

---

### 2. 📊 Dashboard Ejecutivo (Corazón de la App Móvil)
* `GET /api/v1/dashboard` (opcional `?month=YYYY-MM`):
  * **Flujo de caja:** Total ingresos, total gastos, balance neto y tasa de ahorro (%).
  * **Salud Financiera:** Score (0 a 100), estado (*Excelente, Saludable, Alerta, Crítico*) y recomendaciones automáticas contra fugas de dinero.
  * **Regla 50/30/20:** Evaluación de gastos en Necesidades (50%), Deseos/Compras (30%) y Ahorro/Deudas (20%).
  * **Radar de Vencimientos:** Deudas y servicios por pagar en los próximos 15 días.
  * **Desglose de Gastos:** Total gastado y porcentaje por categoría.

---

### 3. 💼 Ingresos y Empleo (`/api/v1/incomes`)
* `GET /api/v1/incomes` : Lista todos los ingresos (filtros: `?month=YYYY-MM&source=empleo_principal`).
* `POST /api/v1/incomes` : Registra un nuevo ingreso.
  ```json
  {
    "title": "Sueldo Empleo Principal",
    "amount": 2500,
    "source": "empleo_principal",
    "frequency": "mensual",
    "date": "2026-11-15",
    "notes": "Cobro de quincena"
  }
  ```
* `GET /api/v1/incomes/:id` : Obtener un ingreso.
* `PUT /api/v1/incomes/:id` : Actualizar.
* `DELETE /api/v1/incomes/:id` : Eliminar.

---

### 4. 💳 Deudas y Radar de Pagos (`/api/v1/debts`)
* `GET /api/v1/debts` : Lista todas las deudas (filtro: `?status=activa`).
* `GET /api/v1/debts/upcoming` : Deudas con fecha de pago en los próximos días (`?days=15`).
* `GET /api/v1/debts/strategies` : Cálculo de estrategias de liquidación:
  * **Método Avalancha:** Ordenado por mayor tasa de interés (ahorra el máximo dinero en intereses).
  * **Método Bola de Nieve:** Ordenado por menor saldo pendiente (victorias rápidas y motivación).
* `POST /api/v1/debts` : Registrar una deuda.
  ```json
  {
    "title": "Tarjeta Visa Oro",
    "creditor": "Banco Nacional",
    "total_amount": 1200,
    "current_balance": 1200,
    "monthly_payment": 150,
    "interest_rate": 24.5,
    "due_day": 20,
    "next_due_date": "2026-11-20"
  }
  ```
* `POST /api/v1/debts/:id/payments` : Registrar un abono a deuda (reduce automáticamente el saldo y marca como pagada si llega a 0).
  ```json
  {
    "amount": 200,
    "payment_date": "2026-11-16",
    "notes": "Abono a capital"
  }
  ```
* `GET /api/v1/debts/:id/payments` : Historial de abonos de la deuda.

---

### 5. 🛒 Gastos y Servicios (`/api/v1/expenses`)
* `GET /api/v1/expenses` : Filtros `?month=YYYY-MM&is_paid=0&category_id=2&type=servicio`.
* `GET /api/v1/expenses/upcoming-bills` : Facturas/servicios pendientes de pago próximos a vencer (`?days=15`).
* `POST /api/v1/expenses` : Registrar gasto o factura de servicio.
  *(Incluye auditoría automática de presupuesto: avisa si se supera el 80% o 100% del límite de la categoría).*
  ```json
  {
    "title": "Factura de Luz",
    "amount": 65.00,
    "category_id": 2,
    "date": "2026-11-16",
    "due_date": "2026-11-25",
    "is_paid": 0,
    "payment_method": "transferencia"
  }
  ```
* `PATCH /api/v1/expenses/:id/pay` : Marcar una factura pendiente como pagada.

---

### 6. 🏷️ Categorías y Presupuestos (`/api/v1/categories`)
* `GET /api/v1/categories` : Lista de categorías predeterminadas (Servicios, Supermercado, Alquiler, etc.).
* `PUT /api/v1/categories/:id` : Configurar `monthly_budget` para activar alertas automáticas contra sobregiros.

---

### 7. 🎯 Metas de Ahorro (`/api/v1/savings`)
* `GET /api/v1/savings` : Metas con cálculo de `% de progreso` y monto restante.
* `POST /api/v1/savings` : Crear meta (ej. Fondo de emergencia).
  ```json
  {
    "title": "Fondo de Emergencia (3 meses)",
    "target_amount": 3000,
    "current_amount": 500,
    "priority": "alta",
    "target_date": "2027-06-30"
  }
  ```
* `POST /api/v1/savings/:id/transactions` : Registrar un aporte (monto positivo) o retiro (monto negativo).

---

## ☁️ Guía de Despliegue en Render

1. Sube este repositorio a tu **GitHub / GitLab**.
2. En tu cuenta de [Render Dashboard](https://dashboard.render.com):
   * Haz clic en **New +** $\rightarrow$ **Web Service**.
   * Conecta tu repositorio.
3. Configuración del servicio:
   * **Runtime:** `Node`
   * **Build Command:** `npm install`
   * **Start Command:** `npm start`
4. Variables de Entorno en Render:
   * `NODE_ENV` = `production`
   * `PORT` = `10000` (o el asignado por Render automáticamente)
   * `DATABASE_URL` = `./data/finance.db`
5. Render detectará automáticamente el endpoint `/health` y pondrá tu API en línea en pocos minutos.
