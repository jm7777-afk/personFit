import { exchangeRateService } from '../services/exchangeRateService.js';

export class ExchangeRateController {
  getRates = async (req, res, next) => {
    try {
      const autoSync = req.query.sync !== 'false';
      const data = await exchangeRateService.getRates(autoSync);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  syncRates = async (req, res, next) => {
    try {
      const data = await exchangeRateService.syncLiveRates();
      res.status(200).json({ status: 'success', message: 'Tasas sincronizadas en vivo', data });
    } catch (err) {
      next(err);
    }
  };

  convert = (req, res, next) => {
    try {
      const data = exchangeRateService.convert(req.body);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };
}

export const exchangeRateController = new ExchangeRateController();
