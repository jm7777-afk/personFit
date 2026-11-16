import { Router } from 'express';
import { categoryController } from '../controllers/categoryController.js';
import { validate } from '../middlewares/validate.js';
import { createCategorySchema, updateCategorySchema } from '../schemas/categorySchema.js';

const router = Router();

router.route('/')
  .get(categoryController.getAll)
  .post(validate(createCategorySchema), categoryController.create);

router.route('/:id')
  .get(categoryController.getById)
  .put(validate(updateCategorySchema), categoryController.update)
  .delete(categoryController.delete);

export default router;
