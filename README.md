# 💰 Mi PersonFit - Personal Finance Mobile & API

Ecosistema integral de finanzas personales, gestión de deudas, metas de ahorro, control de gastos, **tasas de cambio en vivo para Venezuela (BCV Oficial y Paralelo en Bs, USD y EUR)** y **calculadora financiera multimoneda**.

---

## 🏛️ Componentes del Proyecto

1. **Backend RESTful (Node.js & Express + SQLite en modo WAL):**
   * Autenticación con perfiles y contraseñas seguras (`bcryptjs` + JWT).
   * Módulo de deudas con cálculo de estrategias (**Avalancha** vs **Bola de Nieve**).
   * **Historial de deudas pagadas al 100%** con archivo de amortización y celebraciones.
   * **Motor de notificaciones y recordatorios de deudas** en tiempo real (urgentes, vencidas, por vencer en 1-5 días).
   * **API de Tasas de Cambio para Venezuela:** Monitoreo en tiempo real de BCV Oficial y Paralelo/Monitor (USD y EUR) con cálculo automático del **porcentaje de incremento/variación (%)** y brecha cambiaria.
   * **Calculadora y Conversor de Divisas:** Conversión bidireccional entre Bolívares (VES), Dólares (USD) y Euros (EUR).
2. **Aplicación Móvil "Mi PersonFit" (Flutter):**
   * Sistema de diseño visual único (Esmeralda `#10B981`, Pizarra `#0F172A`, Índigo y Ámbar).
   * Ticker en vivo de tasas venezolanas en el Dashboard.
   * **Calculadora Financiera integrada en toda la app** (con atajos: `+16% IVA`, `-16% Base`, división de cuentas entre personas y comparativa simultánea BCV vs Paralelo).
   * Medidor interactivo de Salud Financiera (0 a 100) y Regla 50/30/20.

---

## 📚 Endpoints de Tasas de Cambio & Calculadora (`/api/v1/rates`)

### 1. `GET /api/v1/rates`
Obtiene las tasas de cambio de Venezuela actualizadas con el porcentaje de incremento/variación:
```json
{
  "status": "success",
  "data": {
    "summary": {
      "usd_bcv": 914.02,
      "usd_bcv_change": 0.31,
      "usd_paralelo": 1045.50,
      "usd_paralelo_change": 1.31,
      "eur_bcv": 1010.56,
      "eur_bcv_change": 0.54,
      "eur_paralelo": 1120.00,
      "eur_paralelo_change": 0.90,
      "exchange_gap_percentage": 14.38,
      "gap_description": "El dólar paralelo está un 14.38% por encima de la tasa oficial BCV."
    },
    "rates": [ ... ]
  }
}
```

### 2. `POST /api/v1/rates/convert`
Calculadora de conversión de divisas:
```json
{
  "amount": 100,
  "from": "USD",
  "to": "VES",
  "rate_type": "oficial"
}
```
**Respuesta:**
```json
{
  "status": "success",
  "data": {
    "amount": 100,
    "from": "USD",
    "to": "VES",
    "rate_type": "oficial",
    "rate_used": 914.02,
    "result": 91402.00,
    "formula": "100 USD × 914.02 Bs",
    "comparison": {
      "alternate_type": "paralelo",
      "alternate_rate": 1045.50,
      "alternate_result": 104550.00,
      "difference": 13148.00
    }
  }
}
```

---

## 🚀 Cómo Iniciar el Proyecto

### 1. Servidor Backend
```bash
npm run dev
```
Inicia en `http://127.0.0.1:3000`.

### 2. Aplicación Móvil Flutter
```bash
cd mi_personfit_mobile
flutter run
```

---

## ☁️ Despliegue en Render
1. Sube tu repositorio a GitHub.
2. En Render, crea un **Web Service**:
   * Build command: `npm install`
   * Start command: `npm start`
   * Variables de entorno: `PORT=10000`, `NODE_ENV=production`, `DATABASE_URL=./data/finance.db`, `JWT_SECRET=tu_clave_secreta`.
