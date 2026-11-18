import { db } from '../config/database.js';

const DEFAULT_VE_WALLETS = [
  { name: 'Bolívares (Pago Móvil)', wallet_type: 'bolivares', currency: 'VES', balance: 0, color: '#0EA5E9' },
  { name: 'Efectivo USD', wallet_type: 'efectivo_usd', currency: 'USD', balance: 0, color: '#10B981' },
  { name: 'Binance (USDT)', wallet_type: 'binance_usdt', currency: 'USDT', balance: 0, color: '#F59E0B' },
  { name: 'Zelle', wallet_type: 'zelle', currency: 'USD', balance: 0, color: '#7C3AED' },
  { name: 'Zinli / Wally', wallet_type: 'zinli_wally', currency: 'USD', balance: 0, color: '#EC4899' },
  { name: 'Euros (EUR)', wallet_type: 'euro', currency: 'EUR', balance: 0, color: '#2563EB' }
];

function resolveSafeUserId(userId) {
  if (userId) return userId;
  const firstUser = db.prepare('SELECT id FROM users ORDER BY id ASC LIMIT 1').get();
  return firstUser ? firstUser.id : null;
}

export const walletService = {
  getWallets(userId) {
    const uid = resolveSafeUserId(userId);
    if (!uid) {
      return { wallets: [], total_usd: 0, total_bs: 0 };
    }

    let wallets = db.prepare('SELECT * FROM wallets WHERE user_id = ? ORDER BY id ASC').all(uid);

    // Sembrar las 6 billeteras venezolanas predeterminadas si el usuario aún no tiene
    if (wallets.length === 0) {
      const insert = db.prepare(`
        INSERT INTO wallets (user_id, name, wallet_type, currency, balance, color)
        VALUES (@user_id, @name, @wallet_type, @currency, @balance, @color)
      `);
      const tx = db.transaction((items) => {
        for (const w of items) {
          insert.run({ ...w, user_id: uid });
        }
      });
      tx(DEFAULT_VE_WALLETS);
      wallets = db.prepare('SELECT * FROM wallets WHERE user_id = ? ORDER BY id ASC').all(uid);
    }

    // Obtener tasas para consolidado total en USD y Bs
    const bcvRow = db.prepare("SELECT rate FROM exchange_rates WHERE id = 'usd_oficial'").get();
    const eurRow = db.prepare("SELECT rate FROM exchange_rates WHERE id = 'eur_oficial'").get();
    const bcvRate = bcvRow ? bcvRow.rate : 914.02;
    const eurRate = eurRow ? eurRow.rate : 1010.56;
    const eurToUsd = bcvRate > 0 ? eurRate / bcvRate : 1.1;

    let totalUsd = 0;
    const enriched = wallets.map((w) => {
      let equivUsd = w.balance;
      let equivBs = w.balance * bcvRate;
      const cur = (w.currency || 'USD').toUpperCase();

      if (cur === 'VES') {
        equivUsd = bcvRate > 0 ? +(w.balance / bcvRate).toFixed(2) : 0;
        equivBs = +w.balance.toFixed(2);
      } else if (cur === 'EUR') {
        equivUsd = +(w.balance * eurToUsd).toFixed(2);
        equivBs = +(w.balance * eurRate).toFixed(2);
      } else {
        equivUsd = +w.balance.toFixed(2);
        equivBs = +(w.balance * bcvRate).toFixed(2);
      }

      totalUsd += equivUsd;
      return {
        ...w,
        equivalent_usd: equivUsd,
        equivalent_bs: equivBs
      };
    });

    totalUsd = +totalUsd.toFixed(2);
    const totalBs = +(totalUsd * bcvRate).toFixed(2);

    return {
      wallets: enriched,
      total_usd: totalUsd,
      total_bs: totalBs,
      bcv_rate: bcvRate
    };
  },

  createWallet(userId, { name, wallet_type, currency, balance, account_details, color }) {
    const uid = resolveSafeUserId(userId);
    if (!uid) throw new Error('Usuario no autenticado para crear billetera');

    const stmt = db.prepare(`
      INSERT INTO wallets (user_id, name, wallet_type, currency, balance, account_details, color)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(
      uid,
      name,
      wallet_type || 'otro',
      (currency || 'USD').toUpperCase(),
      Number(balance) || 0,
      account_details || null,
      color || '#6366F1'
    );
    return db.prepare('SELECT * FROM wallets WHERE id = ?').get(info.lastInsertRowid);
  },

  updateWallet(userId, walletId, { name, balance, account_details, currency, color }) {
    const uid = resolveSafeUserId(userId);
    const current = db.prepare('SELECT * FROM wallets WHERE id = ? AND user_id = ?').get(walletId, uid);
    if (!current) return null;

    db.prepare(`
      UPDATE wallets
      SET name = ?, balance = ?, account_details = ?, currency = ?, color = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ? AND user_id = ?
    `).run(
      name ?? current.name,
      balance !== undefined ? Number(balance) : current.balance,
      account_details !== undefined ? account_details : current.account_details,
      currency ? currency.toUpperCase() : current.currency,
      color ?? current.color,
      walletId,
      uid
    );

    return db.prepare('SELECT * FROM wallets WHERE id = ?').get(walletId);
  },

  deleteWallet(userId, walletId) {
    const uid = resolveSafeUserId(userId);
    const info = db.prepare('DELETE FROM wallets WHERE id = ? AND user_id = ?').run(walletId, uid);
    return info.changes > 0;
  }
};
