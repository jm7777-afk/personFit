import { db, VENEZUELA_LOCATIONS, CARABOBO_MUNICIPALITIES } from '../config/database.js';

export const groceryService = {
  // Ubicaciones geográficas de Venezuela (Estados y Municipios con conteo de supermercados)
  getLocations(userId) {
    const counts = db.prepare(`
      SELECT state, municipality, COUNT(*) as count 
      FROM supermarkets 
      WHERE user_id IS NULL OR user_id = ?
      GROUP BY state, municipality
    `).all(userId || null);

    const countMap = {};
    let totalCarabobo = 0;
    for (const row of counts) {
      const stateKey = (row.state || 'Carabobo').toLowerCase();
      const munKey = (row.municipality || 'Valencia').toLowerCase();
      countMap[`${stateKey}_${munKey}`] = row.count;
      if (stateKey === 'carabobo') {
        totalCarabobo += row.count;
      }
    }

    const states = VENEZUELA_LOCATIONS.map(loc => {
      let stateCount = 0;
      const municipalitiesData = loc.municipalities.map(m => {
        const c = countMap[`${loc.state.toLowerCase()}_${m.toLowerCase()}`] || 0;
        stateCount += c;
        return {
          name: m,
          supermarkets_count: c
        };
      });

      return {
        state: loc.state,
        supermarkets_count: stateCount,
        municipalities: municipalitiesData
      };
    });

    return {
      current_state: 'Carabobo',
      total_supermarkets_carabobo: totalCarabobo,
      states
    };
  },

  // Supermercados con filtros por Estado, Municipio y Búsqueda
  getSupermarkets(userId, { state, municipality, search } = {}) {
    let query = `
      SELECT * FROM supermarkets 
      WHERE (user_id IS NULL OR user_id = ?)
    `;
    const params = [userId || null];

    if (state && state.trim().length > 0) {
      query += ` AND LOWER(state) = LOWER(?)`;
      params.push(state.trim());
    }

    if (municipality && municipality.trim().length > 0 && municipality.toLowerCase() !== 'todos') {
      query += ` AND LOWER(municipality) = LOWER(?)`;
      params.push(municipality.trim());
    }

    if (search && search.trim().length > 0) {
      query += ` AND (
        LOWER(name) LIKE LOWER(?) OR 
        LOWER(COALESCE(branch, '')) LIKE LOWER(?) OR 
        LOWER(COALESCE(address, '')) LIKE LOWER(?) OR 
        LOWER(COALESCE(description, '')) LIKE LOWER(?) OR 
        LOWER(COALESCE(municipality, '')) LIKE LOWER(?)
      )`;
      const s = `%${search.trim()}%`;
      params.push(s, s, s, s, s);
    }

    query += ` ORDER BY municipality ASC, name ASC`;
    return db.prepare(query).all(...params);
  },

  createSupermarket(userId, { name, branch, state, municipality, address, description, phone, opening_hours }) {
    const stmt = db.prepare(`
      INSERT INTO supermarkets (user_id, name, branch, state, municipality, address, description, phone, opening_hours) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(
      userId || null, 
      name, 
      branch || null, 
      state || 'Carabobo', 
      municipality || 'Valencia', 
      address || null, 
      description || null, 
      phone || null, 
      opening_hours || null
    );
    return { 
      id: info.lastInsertRowid, 
      user_id: userId, 
      name, 
      branch, 
      state: state || 'Carabobo', 
      municipality: municipality || 'Valencia', 
      address, 
      description, 
      phone, 
      opening_hours 
    };
  },

  // Productos
  getProducts(userId) {
    const stmt = db.prepare(`
      SELECT p.*,
        (SELECT price_usd FROM grocery_prices gp WHERE gp.product_id = p.id ORDER BY date DESC, id DESC LIMIT 1) as latest_price_usd,
        (SELECT price_bs FROM grocery_prices gp WHERE gp.product_id = p.id ORDER BY date DESC, id DESC LIMIT 1) as latest_price_bs,
        (SELECT s.name FROM grocery_prices gp JOIN supermarkets s ON s.id = gp.supermarket_id WHERE gp.product_id = p.id ORDER BY gp.date DESC, gp.id DESC LIMIT 1) as latest_supermarket
      FROM grocery_products p
      WHERE p.user_id IS NULL OR p.user_id = ?
      ORDER BY p.name ASC
    `);
    return stmt.all(userId);
  },

  createProduct(userId, { name, category, unit, barcode }) {
    const stmt = db.prepare(`
      INSERT INTO grocery_products (user_id, name, category, unit, barcode)
      VALUES (?, ?, ?, ?, ?)
    `);
    const info = stmt.run(userId, name, category || 'Alimentos', unit || 'unidad', barcode || null);
    return { id: info.lastInsertRowid, user_id: userId, name, category, unit, barcode };
  },

  // Registro de Precios y cálculo de incremento
  recordPrice({ product_id, supermarket_id, price_bs, price_usd, date, notes }) {
    // Buscar precio anterior del mismo producto para ver cuánto subió
    const lastPrice = db.prepare(`
      SELECT price_usd, price_bs, date, supermarket_id
      FROM grocery_prices
      WHERE product_id = ?
      ORDER BY date DESC, id DESC
      LIMIT 1
    `).get(product_id);

    const priceDate = date || new Date().toISOString().split('T')[0];
    const stmt = db.prepare(`
      INSERT INTO grocery_prices (product_id, supermarket_id, price_bs, price_usd, date, notes)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(product_id, supermarket_id, price_bs, price_usd, priceDate, notes || null);

    let variationPercentUsd = 0;
    let differenceUsd = 0;
    let variationPercentBs = 0;
    let differenceBs = 0;

    if (lastPrice) {
      differenceUsd = +(price_usd - lastPrice.price_usd).toFixed(2);
      variationPercentUsd = lastPrice.price_usd > 0 
        ? +(((price_usd - lastPrice.price_usd) / lastPrice.price_usd) * 100).toFixed(2) 
        : 0;

      differenceBs = +(price_bs - lastPrice.price_bs).toFixed(2);
      variationPercentBs = lastPrice.price_bs > 0 
        ? +(((price_bs - lastPrice.price_bs) / lastPrice.price_bs) * 100).toFixed(2) 
        : 0;
    }

    return {
      id: info.lastInsertRowid,
      product_id,
      supermarket_id,
      price_bs,
      price_usd,
      date: priceDate,
      variation: {
        difference_usd: differenceUsd,
        percent_usd: variationPercentUsd,
        difference_bs: differenceBs,
        percent_bs: variationPercentBs,
        has_increased: differenceUsd > 0,
        previous_price_usd: lastPrice ? lastPrice.price_usd : price_usd,
        previous_price_bs: lastPrice ? lastPrice.price_bs : price_bs,
        previous_date: lastPrice ? lastPrice.date : priceDate
      }
    };
  },

  // Comparador de Precios de Productos con historial y cuánto subió (con filtro opcional de Estado y Municipio)
  getCompareProducts(userId, { state, municipality } = {}) {
    const products = this.getProducts(userId);
    const result = [];

    let superFilterClause = '';
    const superFilterParams = [];
    if (state && state.trim().length > 0) {
      superFilterClause += ' AND LOWER(s.state) = LOWER(?)';
      superFilterParams.push(state.trim());
    }
    if (municipality && municipality.trim().length > 0 && municipality.toLowerCase() !== 'todos') {
      superFilterClause += ' AND LOWER(s.municipality) = LOWER(?)';
      superFilterParams.push(municipality.trim());
    }

    for (const prod of products) {
      // Obtener todos los precios registrados de este producto agrupados por supermercado
      const prices = db.prepare(`
        SELECT gp.*, s.name as supermarket_name, s.branch as supermarket_branch, s.municipality, s.state
        FROM grocery_prices gp
        JOIN supermarkets s ON s.id = gp.supermarket_id
        WHERE gp.product_id = ? ${superFilterClause}
        ORDER BY gp.date DESC, gp.id DESC
      `).all(prod.id, ...superFilterParams);

      // Agrupar por supermercado el último precio
      const bySuper = {};
      for (const p of prices) {
        if (!bySuper[p.supermarket_id]) {
          bySuper[p.supermarket_id] = {
            supermarket_id: p.supermarket_id,
            supermarket_name: p.supermarket_name,
            supermarket_branch: p.supermarket_branch,
            municipality: p.municipality,
            state: p.state,
            current_price_usd: p.price_usd,
            current_price_bs: p.price_bs,
            date: p.date,
            history: []
          };
        }
        bySuper[p.supermarket_id].history.push({
          price_usd: p.price_usd,
          price_bs: p.price_bs,
          date: p.date
        });
      }

      // Calcular para cada supermercado cuánto subió vs la compra anterior
      const supermarketComparisons = Object.values(bySuper).map(item => {
        let increasePercentUsd = 0;
        let diffUsd = 0;
        let previousPriceUsd = null;
        let previousPriceBs = null;

        if (item.history.length > 1) {
          previousPriceUsd = item.history[1].price_usd;
          previousPriceBs = item.history[1].price_bs;
          diffUsd = +(item.current_price_usd - previousPriceUsd).toFixed(2);
          increasePercentUsd = previousPriceUsd > 0 
            ? +(((item.current_price_usd - previousPriceUsd) / previousPriceUsd) * 100).toFixed(2) 
            : 0;
        }

        return {
          supermarket_id: item.supermarket_id,
          supermarket_name: item.supermarket_name,
          supermarket_branch: item.supermarket_branch,
          municipality: item.municipality,
          state: item.state,
          current_price_usd: item.current_price_usd,
          current_price_bs: item.current_price_bs,
          previous_price_usd: previousPriceUsd,
          previous_price_bs: previousPriceBs,
          diff_usd: diffUsd,
          increase_percent_usd: increasePercentUsd,
          is_cheapest: false
        };
      });

      // Identificar el supermercado más económico para este producto
      if (supermarketComparisons.length > 0) {
        const minPrice = Math.min(...supermarketComparisons.map(s => s.current_price_usd));
        for (const sc of supermarketComparisons) {
          if (sc.current_price_usd === minPrice) {
            sc.is_cheapest = true;
          }
        }
      }

      result.push({
        product: prod,
        comparisons: supermarketComparisons,
        cheapest_supermarket: supermarketComparisons.find(s => s.is_cheapest) || null
      });
    }

    return result;
  },

  // Comparador de Supermercados: Cesta global para ver cuál es más económico en total (con filtro de Estado y Municipio)
  getCompareSupermarkets(userId, { state, municipality } = {}) {
    const supermarkets = this.getSupermarkets(userId, { state, municipality });
    const products = this.getProducts(userId);

    const rankings = [];

    for (const s of supermarkets) {
      let totalBasketUsd = 0;
      let totalBasketBs = 0;
      let matchedItemsCount = 0;

      for (const p of products) {
        const latestInSuper = db.prepare(`
          SELECT price_usd, price_bs
          FROM grocery_prices
          WHERE product_id = ? AND supermarket_id = ?
          ORDER BY date DESC, id DESC
          LIMIT 1
        `).get(p.id, s.id);

        if (latestInSuper) {
          totalBasketUsd += latestInSuper.price_usd;
          totalBasketBs += latestInSuper.price_bs;
          matchedItemsCount++;
        }
      }

      if (matchedItemsCount > 0) {
        rankings.push({
          supermarket_id: s.id,
          supermarket_name: s.name,
          branch: s.branch,
          municipality: s.municipality,
          state: s.state,
          address: s.address,
          description: s.description,
          phone: s.phone,
          opening_hours: s.opening_hours,
          total_basket_usd: +totalBasketUsd.toFixed(2),
          total_basket_bs: +totalBasketBs.toFixed(2),
          products_tracked: matchedItemsCount,
          average_product_price_usd: +(totalBasketUsd / matchedItemsCount).toFixed(2),
          is_cheapest: false,
          savings_vs_most_expensive_usd: 0
        });
      }
    }

    // Ordenar de más económico a más caro
    rankings.sort((a, b) => a.total_basket_usd - b.total_basket_usd);

    if (rankings.length > 0) {
      rankings[0].is_cheapest = true;
      const maxBasket = rankings[rankings.length - 1].total_basket_usd;
      for (const r of rankings) {
        r.savings_vs_most_expensive_usd = +(maxBasket - r.total_basket_usd).toFixed(2);
      }
    }

    return {
      filter: {
        state: state || 'Carabobo',
        municipality: municipality || 'Todos'
      },
      cheapest_supermarket: rankings[0] || null,
      rankings
    };
  },

  // Listas de Compras ("Qué llevo, cuánto llevo")
  getLists(userId) {
    const lists = db.prepare(`
      SELECT gl.*, s.name as supermarket_name,
        (SELECT COUNT(*) FROM grocery_list_items gli WHERE gli.list_id = gl.id) as total_items,
        (SELECT COUNT(*) FROM grocery_list_items gli WHERE gli.list_id = gl.id AND gli.is_checked = 1) as checked_items,
        (SELECT COALESCE(SUM(quantity * price_usd), 0) FROM grocery_list_items gli WHERE gli.list_id = gl.id) as total_estimated_usd,
        (SELECT COALESCE(SUM(quantity * price_usd), 0) FROM grocery_list_items gli WHERE gli.list_id = gl.id AND gli.is_checked = 1) as total_checked_usd,
        (SELECT COALESCE(SUM(quantity * price_bs), 0) FROM grocery_list_items gli WHERE gli.list_id = gl.id AND gli.is_checked = 1) as total_checked_bs
      FROM grocery_lists gl
      LEFT JOIN supermarkets s ON s.id = gl.supermarket_id
      WHERE gl.user_id = ?
      ORDER BY gl.created_at DESC
    `).all(userId);

    return lists;
  },

  createList(userId, { title, supermarket_id, notes }) {
    const stmt = db.prepare(`
      INSERT INTO grocery_lists (user_id, title, supermarket_id, notes)
      VALUES (?, ?, ?, ?)
    `);
    const info = stmt.run(userId, title, supermarket_id || null, notes || null);
    return this.getListDetails(userId, info.lastInsertRowid);
  },

  getListDetails(userId, listId) {
    const list = db.prepare(`
      SELECT gl.*, s.name as supermarket_name
      FROM grocery_lists gl
      LEFT JOIN supermarkets s ON s.id = gl.supermarket_id
      WHERE gl.id = ? AND gl.user_id = ?
    `).get(listId, userId);

    if (!list) return null;

    const items = db.prepare(`
      SELECT * FROM grocery_list_items
      WHERE list_id = ?
      ORDER BY is_checked ASC, id DESC
    `).all(listId);

    const totalEstimatedUsd = items.reduce((acc, it) => acc + (it.quantity * it.price_usd), 0);
    const totalEstimatedBs = items.reduce((acc, it) => acc + (it.quantity * it.price_bs), 0);
    const totalCheckedUsd = items.filter(it => it.is_checked === 1).reduce((acc, it) => acc + (it.quantity * it.price_usd), 0);
    const totalCheckedBs = items.filter(it => it.is_checked === 1).reduce((acc, it) => acc + (it.quantity * it.price_bs), 0);
    const checkedCount = items.filter(it => it.is_checked === 1).length;

    return {
      ...list,
      total_items: items.length,
      checked_items: checkedCount,
      progress_percent: items.length > 0 ? +((checkedCount / items.length) * 100).toFixed(1) : 0,
      total_estimated_usd: +totalEstimatedUsd.toFixed(2),
      total_estimated_bs: +totalEstimatedBs.toFixed(2),
      total_checked_usd: +totalCheckedUsd.toFixed(2),
      total_checked_bs: +totalCheckedBs.toFixed(2),
      items
    };
  },

  addListItem(userId, listId, { product_id, product_name, quantity, unit, price_bs, price_usd }) {
    // Si viene product_id y no viene precio, autocompletar con el último precio registrado
    let finalPriceUsd = price_usd || 0;
    let finalPriceBs = price_bs || 0;
    let name = product_name;

    if (product_id && (!finalPriceUsd || !name)) {
      const prod = db.prepare('SELECT name, unit FROM grocery_products WHERE id = ?').get(product_id);
      if (prod) {
        if (!name) name = prod.name;
        if (!unit) unit = prod.unit;
      }
      const lastPrice = db.prepare(`
        SELECT price_usd, price_bs FROM grocery_prices 
        WHERE product_id = ? ORDER BY date DESC, id DESC LIMIT 1
      `).get(product_id);
      if (lastPrice) {
        if (!finalPriceUsd) finalPriceUsd = lastPrice.price_usd;
        if (!finalPriceBs) finalPriceBs = lastPrice.price_bs;
      }
    }

    const stmt = db.prepare(`
      INSERT INTO grocery_list_items (list_id, product_id, product_name, quantity, unit, price_bs, price_usd, is_checked)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0)
    `);
    const info = stmt.run(listId, product_id || null, name || 'Producto', quantity || 1, unit || 'unidad', finalPriceBs, finalPriceUsd);

    return this.getListDetails(userId, listId);
  },

  toggleListItem(userId, listId, itemId, isChecked) {
    db.prepare('UPDATE grocery_list_items SET is_checked = ? WHERE id = ? AND list_id = ?')
      .run(isChecked ? 1 : 0, itemId, listId);
    return this.getListDetails(userId, listId);
  },

  updateListItem(userId, listId, itemId, { quantity, price_bs, price_usd, is_checked }) {
    const current = db.prepare('SELECT * FROM grocery_list_items WHERE id = ? AND list_id = ?').get(itemId, listId);
    if (!current) return null;

    db.prepare(`
      UPDATE grocery_list_items 
      SET quantity = ?, price_bs = ?, price_usd = ?, is_checked = ?
      WHERE id = ? AND list_id = ?
    `).run(
      quantity ?? current.quantity,
      price_bs ?? current.price_bs,
      price_usd ?? current.price_usd,
      is_checked !== undefined ? (is_checked ? 1 : 0) : current.is_checked,
      itemId,
      listId
    );

    return this.getListDetails(userId, listId);
  },

  deleteListItem(userId, listId, itemId) {
    db.prepare('DELETE FROM grocery_list_items WHERE id = ? AND list_id = ?').run(itemId, listId);
    return this.getListDetails(userId, listId);
  },

  deleteList(userId, listId) {
    const stmt = db.prepare('DELETE FROM grocery_lists WHERE id = ? AND user_id = ?');
    stmt.run(listId, userId);
    return { success: true };
  }
};
