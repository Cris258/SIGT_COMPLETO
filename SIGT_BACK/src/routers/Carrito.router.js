import { Router } from "express";
import { createCarrito, showCarrito, showIdCarrito, updateCarrito, deleteCarrito } from "../controller/Carrito.controller.js";
import carritoScheme from '../schemes/Carrito.schema.js';
import carritoMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/carrito', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), carritoMiddleware(carritoScheme.createCarrito), createCarrito);
router.get('/carrito', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showCarrito);
router.get('/carrito/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showIdCarrito);
router.put('/carrito/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), carritoMiddleware(carritoScheme.updateCarrito), updateCarrito);
router.delete('/carrito/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), deleteCarrito);

export default router;