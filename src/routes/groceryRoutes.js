import { Router } from 'express';
import { groceryController } from '../controllers/groceryController.js';

const router = Router();

// Ubicaciones (Estados y Municipios de Venezuela)
router.get('/locations', groceryController.getLocations);

// Supermercados y Productos
router.get('/supermarkets', groceryController.getSupermarkets);
router.post('/supermarkets', groceryController.createSupermarket);

router.get('/products', groceryController.getProducts);
router.post('/products', groceryController.createProduct);

// Precios y Comparativas ("Cuánto subió" y "Cuál es más económico")
router.post('/prices', groceryController.recordPrice);
router.get('/compare-products', groceryController.compareProducts);
router.get('/compare-supermarkets', groceryController.compareSupermarkets);

// Listas de compras ("Qué llevo, cuánto llevo")
router.get('/lists', groceryController.getLists);
router.post('/lists', groceryController.createList);
router.get('/lists/:id', groceryController.getListDetails);
router.delete('/lists/:id', groceryController.deleteList);

router.post('/lists/:id/items', groceryController.addListItem);
router.patch('/lists/:id/items/:itemId/toggle', groceryController.toggleListItem);
router.put('/lists/:id/items/:itemId', groceryController.updateListItem);
router.delete('/lists/:id/items/:itemId', groceryController.deleteListItem);

export default router;
