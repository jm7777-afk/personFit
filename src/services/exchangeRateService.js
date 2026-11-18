import { exchangeRateRepository } from '../repositories/exchangeRateRepository.js';
import { BadRequestError } from '../utils/errors.js';

export class ExchangeRateService {
  async getRates(autoSync = true) {
    if (autoSync) {
      try {
        await this.syncLiveRates();
      } catch (err) {
        console.warn('⚠️ No se pudo sincronizar tasas en vivo, usando datos cacheados:', err.message);
      }
    }

    const rates = exchangeRateRepository.findAll();
    const usdBcv = rates.find(r => r.id === 'usd_oficial');
    const usdParalelo = rates.find(r => r.id === 'usd_paralelo');
    const usdtBinance = rates.find(r => r.id === 'usdt_binance');
    const eurBcv = rates.find(r => r.id === 'eur_oficial');
    const eurParalelo = rates.find(r => r.id === 'eur_paralelo');

    // Calcular brecha cambiaria entre paralelo y BCV
    let gapPercent = 0;
    if (usdBcv && usdParalelo && usdBcv.rate > 0) {
      gapPercent = Number((((usdParalelo.rate - usdBcv.rate) / usdBcv.rate) * 100).toFixed(2));
    }

    const usdtRateVal = usdtBinance
      ? usdtBinance.rate
      : (usdParalelo ? Number((usdParalelo.rate * 1.006).toFixed(2)) : 0);

    return {
      summary: {
        usd_bcv: usdBcv ? usdBcv.rate : 0,
        usd_bcv_change: usdBcv ? usdBcv.change_percent : 0,
        usd_paralelo: usdParalelo ? usdParalelo.rate : 0,
        usd_paralelo_change: usdParalelo ? usdParalelo.change_percent : 0,
        usdt_binance: usdtRateVal,
        usdt_binance_change: usdtBinance ? usdtBinance.change_percent : (usdParalelo ? usdParalelo.change_percent : 0),
        eur_bcv: eurBcv ? eurBcv.rate : 0,
        eur_bcv_change: eurBcv ? eurBcv.change_percent : 0,
        eur_paralelo: eurParalelo ? eurParalelo.rate : 0,
        eur_paralelo_change: eurParalelo ? eurParalelo.change_percent : 0,
        exchange_gap_percentage: gapPercent,
        gap_description: `El dólar paralelo está un ${gapPercent}% por encima de la tasa oficial BCV.`
      },
      rates,
      last_synced_at: new Date().toISOString()
    };
  }

  async syncLiveRates() {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);

    try {
      // 1. Dólares
      const resDolares = await fetch('https://ve.dolarapi.com/v1/dolares', { signal: controller.signal });
      if (resDolares.ok) {
        const dolares = await resDolares.json();
        for (const item of dolares) {
          if (item.fuente === 'oficial') {
            exchangeRateRepository.upsert({
              id: 'usd_oficial',
              currency: 'USD',
              provider: 'oficial',
              name: 'Dólar BCV Oficial',
              rate: item.promedio,
              last_updated: item.fechaActualizacion || new Date().toISOString()
            });
          } else if (item.fuente === 'paralelo') {
            exchangeRateRepository.upsert({
              id: 'usd_paralelo',
              currency: 'USD',
              provider: 'paralelo',
              name: 'Dólar Paralelo / Monitor',
              rate: item.promedio,
              last_updated: item.fechaActualizacion || new Date().toISOString()
            });
          }
        }
      }

      // 2. Euros
      const resEuros = await fetch('https://ve.dolarapi.com/v1/euros', { signal: controller.signal });
      if (resEuros.ok) {
        const euros = await resEuros.json();
        for (const item of euros) {
          if (item.fuente === 'oficial') {
            exchangeRateRepository.upsert({
              id: 'eur_oficial',
              currency: 'EUR',
              provider: 'oficial',
              name: 'Euro BCV Oficial',
              rate: item.promedio,
              last_updated: item.fechaActualizacion || new Date().toISOString()
            });
          } else if (item.fuente === 'paralelo') {
            exchangeRateRepository.upsert({
              id: 'eur_paralelo',
              currency: 'EUR',
              provider: 'paralelo',
              name: 'Euro Paralelo',
              rate: item.promedio,
              last_updated: item.fechaActualizacion || new Date().toISOString()
            });
          }
        }
      }

      return exchangeRateRepository.findAll();
    } finally {
      clearTimeout(timeout);
    }
  }

  /**
   * Calculadora Multimoneda para Venezuela (VES, USD, EUR)
   */
  convert({ amount, from = 'USD', to = 'VES', rateType = 'oficial' }) {
    if (!amount || amount <= 0) {
      throw new BadRequestError('El monto debe ser un número positivo');
    }

    const fromUpper = from.toUpperCase();
    const toUpper = to.toUpperCase();
    const type = rateType.toLowerCase() === 'paralelo' ? 'paralelo' : 'oficial';

    const usdRate = exchangeRateRepository.findByCurrencyAndProvider('USD', type)?.rate || 914.02;
    const eurRate = exchangeRateRepository.findByCurrencyAndProvider('EUR', type)?.rate || 1010.56;

    let result = 0;
    let rateUsed = 1;
    let formula = '';

    if (fromUpper === toUpper) {
      result = amount;
      rateUsed = 1;
      formula = 'Misma moneda';
    } else if (fromUpper === 'USD' && toUpper === 'VES') {
      result = amount * usdRate;
      rateUsed = usdRate;
      formula = `${amount} USD × ${usdRate} Bs`;
    } else if (fromUpper === 'VES' && toUpper === 'USD') {
      result = amount / usdRate;
      rateUsed = usdRate;
      formula = `${amount} Bs ÷ ${usdRate} Bs/USD`;
    } else if (fromUpper === 'EUR' && toUpper === 'VES') {
      result = amount * eurRate;
      rateUsed = eurRate;
      formula = `${amount} EUR × ${eurRate} Bs`;
    } else if (fromUpper === 'VES' && toUpper === 'EUR') {
      result = amount / eurRate;
      rateUsed = eurRate;
      formula = `${amount} Bs ÷ ${eurRate} Bs/EUR`;
    } else if (fromUpper === 'USD' && toUpper === 'EUR') {
      const inBs = amount * usdRate;
      result = inBs / eurRate;
      rateUsed = usdRate / eurRate;
      formula = `(${amount} USD × ${usdRate}) ÷ ${eurRate}`;
    } else if (fromUpper === 'EUR' && toUpper === 'USD') {
      const inBs = amount * eurRate;
      result = inBs / usdRate;
      rateUsed = eurRate / usdRate;
      formula = `(${amount} EUR × ${eurRate}) ÷ ${usdRate}`;
    } else {
      throw new BadRequestError(`Conversión de ${fromUpper} a ${toUpper} no soportada`);
    }

    // Calcular comparación simultánea (cuánto sería en la otra tasa)
    const alternateType = type === 'oficial' ? 'paralelo' : 'oficial';
    const altUsdRate = exchangeRateRepository.findByCurrencyAndProvider('USD', alternateType)?.rate || usdRate;
    let alternateResult = 0;
    if (fromUpper === 'USD' && toUpper === 'VES') {
      alternateResult = amount * altUsdRate;
    } else if (fromUpper === 'VES' && toUpper === 'USD') {
      alternateResult = amount / altUsdRate;
    }

    return {
      amount,
      from: fromUpper,
      to: toUpper,
      rate_type: type,
      rate_used: Number(rateUsed.toFixed(4)),
      result: Number(result.toFixed(2)),
      formula,
      comparison: {
        alternate_type: alternateType,
        alternate_rate: altUsdRate,
        alternate_result: Number(alternateResult.toFixed(2)),
        difference: Number(Math.abs(result - alternateResult).toFixed(2))
      }
    };
  }
}

export const exchangeRateService = new ExchangeRateService();
