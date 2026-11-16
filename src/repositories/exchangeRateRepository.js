import { db } from '../config/database.js';

export class ExchangeRateRepository {
  findAll() {
    return db.prepare('SELECT * FROM exchange_rates ORDER BY currency ASC, provider ASC').all();
  }

  findById(id) {
    return db.prepare('SELECT * FROM exchange_rates WHERE id = ?').get(id);
  }

  findByCurrencyAndProvider(currency, provider) {
    return db.prepare('SELECT * FROM exchange_rates WHERE currency = ? AND provider = ?').get(currency, provider);
  }

  upsert(rateData) {
    const current = this.findById(rateData.id);
    const previousRate = current ? current.rate : (rateData.previous_rate || rateData.rate);
    const changePercent = previousRate > 0 
      ? Number((((rateData.rate - previousRate) / previousRate) * 100).toFixed(2))
      : 0;

    const stmt = db.prepare(`
      INSERT INTO exchange_rates (id, currency, provider, name, rate, previous_rate, change_percent, last_updated)
      VALUES (@id, @currency, @provider, @name, @rate, @previous_rate, @change_percent, @last_updated)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        previous_rate = exchange_rates.rate,
        rate = excluded.rate,
        change_percent = CASE 
          WHEN exchange_rates.rate > 0 THEN ROUND(((excluded.rate - exchange_rates.rate) / exchange_rates.rate) * 100, 2)
          ELSE 0 
        END,
        last_updated = excluded.last_updated
    `);

    stmt.run({
      id: rateData.id,
      currency: rateData.currency,
      provider: rateData.provider,
      name: rateData.name,
      rate: rateData.rate,
      previous_rate: previousRate,
      change_percent: changePercent,
      last_updated: rateData.last_updated || new Date().toISOString()
    });

    return this.findById(rateData.id);
  }
}

export const exchangeRateRepository = new ExchangeRateRepository();
