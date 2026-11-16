import { categoryRepository } from '../repositories/categoryRepository.js';
import { NotFoundError, ConflictError } from '../utils/errors.js';

export class CategoryController {
  getAll = (req, res, next) => {
    try {
      const { type } = req.query;
      const data = categoryRepository.findAll(type);
      res.status(200).json({ status: 'success', results: data.length, data });
    } catch (err) {
      next(err);
    }
  };

  getById = (req, res, next) => {
    try {
      const data = categoryRepository.findById(Number(req.params.id));
      if (!data) throw new NotFoundError('Categoría no encontrada');
      res.status(200).json({ status: 'success', data });
    } catch (err) {
      next(err);
    }
  };

  create = (req, res, next) => {
    try {
      const exists = categoryRepository.findByName(req.body.name);
      if (exists) throw new ConflictError('Ya existe una categoría con ese nombre');
      const data = categoryRepository.create(req.body);
      res.status(201).json({ status: 'success', message: 'Categoría creada', data });
    } catch (err) {
      next(err);
    }
  };

  update = (req, res, next) => {
    try {
      const current = categoryRepository.findById(Number(req.params.id));
      if (!current) throw new NotFoundError('Categoría no encontrada');

      if (req.body.name && req.body.name !== current.name) {
        const exists = categoryRepository.findByName(req.body.name);
        if (exists) throw new ConflictError('Ya existe una categoría con ese nombre');
      }

      const data = categoryRepository.update(Number(req.params.id), req.body);
      res.status(200).json({ status: 'success', message: 'Categoría actualizada', data });
    } catch (err) {
      next(err);
    }
  };

  delete = (req, res, next) => {
    try {
      const current = categoryRepository.findById(Number(req.params.id));
      if (!current) throw new NotFoundError('Categoría no encontrada');

      categoryRepository.delete(Number(req.params.id));
      res.status(200).json({ status: 'success', message: 'Categoría eliminada' });
    } catch (err) {
      next(err);
    }
  };
}

export const categoryController = new CategoryController();
