import { Router } from "express";
import { createProducto, showProducto, obtenerProductosAgrupados,showIdProducto, updateProducto, deleteProducto, obtenerProductos, obtenerTopProductos, obtenerEstadisticasInventario } from "../controller/Producto.controller.js";
import productoScheme from '../schemes/Producto.schema.js';
import validateMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";
import upload from '../config/multer.config.js';

const router = Router();

router.post('/producto', upload.array('imagenes', 10), verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), validateMiddleware(productoScheme.createProducto), createProducto);
router.get('/producto-home',  showProducto);
router.get('/productos/agrupados', obtenerProductosAgrupados);
router.get('/producto', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado','Cliente'), showProducto);
router.get('/producto/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado','Cliente'), showIdProducto);
router.put('/producto/:id', upload.array('imagenes', 10), verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Cliente'), validateMiddleware(productoScheme.updateProducto), updateProducto);
router.delete('/producto/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), deleteProducto);

router.get('/productos', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), obtenerProductos);
router.get('/top-productos', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), obtenerTopProductos);
router.get('/estadisticas-inventario', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), obtenerEstadisticasInventario);


export default router;