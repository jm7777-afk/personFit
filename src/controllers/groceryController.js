import { groceryService } from '../services/groceryService.js';

export const groceryController = {
  // Ubicaciones geográficas (Estados y Municipios de Venezuela)
  getLocations(req, res, next) {
    try {
      const data = groceryService.getLocations(req.user?.id);
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  // Supermercados con filtros por Estado, Municipio y Búsqueda
  getSupermarkets(req, res, next) {
    try {
      const { state, municipality, search } = req.query;
      const data = groceryService.getSupermarkets(req.user?.id, { state, municipality, search });
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  },

  createSupermarket(req, res, next) {
    try {
      const data = groceryService.createSupermarket(req.user?.id, req.body);
      res.status(201).json({ status: 'success', message: 'Supermercado agregado', data });
    } catch (err) {
      next(err);
    }
  },

  // Productos
  getProducts(req, res, next) {
    try {
      const data = groceryService.getProducts(req.user?.id);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  },

  createProduct(req, res, next) {
    try {
      const data = groceryService.createProduct(req.user?.id, req.body);
      res.status(201).json({ status: 'success', message: 'Producto registrado', data });
    } catch (err) {
      next(err);
    }
  },

  // Precios y Variación (Colaborativo)
  recordPrice(req, res, next) {
    try {
      const payload = {
        ...req.body,
        reported_by: req.body.reported_by || req.user?.name || 'Usuario Kryon'
      };
      const data = groceryService.recordPrice(payload, req.user?.id);
      res.status(201).json({ status: 'success', message: 'Precio registrado y verificado exitosamente', data });
    } catch (err) {
      next(err);
    }
  },

  compareProducts(req, res, next) {
    try {
      const { state, municipality } = req.query;
      const data = groceryService.getCompareProducts(req.user?.id, { state, municipality });
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  },

  compareSupermarkets(req, res, next) {
    try {
      const { state, municipality } = req.query;
      const data = groceryService.getCompareSupermarkets(req.user?.id, { state, municipality });
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  // Listas de compras ("Qué llevo, cuánto llevo")
  getLists(req, res, next) {
    try {
      const data = groceryService.getLists(req.user?.id);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  },

  createList(req, res, next) {
    try {
      const data = groceryService.createList(req.user?.id, req.body);
      res.status(201).json({ status: 'success', message: 'Lista de compras creada', data });
    } catch (err) {
      next(err);
    }
  },

  getListDetails(req, res, next) {
    try {
      const data = groceryService.getListDetails(req.user?.id, Number(req.params.id));
      if (!data) return res.status(404).json({ status: 'fail', message: 'Lista no encontrada' });
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  },

  addListItem(req, res, next) {
    try {
      const data = groceryService.addListItem(req.user?.id, Number(req.params.id), req.body);
      res.status(201).json({ status: 'success', message: 'Ítem agregado a la lista', data });
    } catch (err) {
      next(err);
    }
  },

  toggleListItem(req, res, next) {
    try {
      const data = groceryService.toggleListItem(
        req.user?.id, 
        Number(req.params.id), 
        Number(req.params.itemId), 
        req.body.is_checked
      );
      res.status(200).json({ status: 'success', message: 'Estado del ítem actualizado', data });
    } catch (err) {
      next(err);
    }
  },

  updateListItem(req, res, next) {
    try {
      const data = groceryService.updateListItem(
        req.user?.id, 
        Number(req.params.id), 
        Number(req.params.itemId), 
        req.body
      );
      res.status(200).json({ status: 'success', message: 'Ítem actualizado', data });
    } catch (err) {
      next(err);
    }
  },

  deleteListItem(req, res, next) {
    try {
      const data = groceryService.deleteListItem(
        req.user?.id, 
        Number(req.params.id), 
        Number(req.params.itemId)
      );
      res.status(200).json({ status: 'success', message: 'Ítem eliminado', data });
    } catch (err) {
      next(err);
    }
  },

  deleteList(req, res, next) {
    try {
      const data = groceryService.deleteList(req.user?.id, Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Lista eliminada', data });
    } catch (err) {
      next(err);
    }
  }
};
