import { Router } from "express";
import { createMovimiento, showMovimiento, showIdMovimiento, updateMovimiento, deleteMovimiento } from "../controller/Movimiento.controller.js";
import movimientoScheme from '../schemes/Movimiento.schema.js';
import movimientoMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/movimiento', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), movimientoMiddleware(movimientoScheme.createMovimiento), createMovimiento);
router.get('/movimiento', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado", "Cliente"), showMovimiento);
router.get('/movimiento/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado", "Cliente"), showIdMovimiento);
router.put('/movimiento/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), movimientoMiddleware(movimientoScheme.updateMovimiento), updateMovimiento);
router.delete('/movimiento/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), deleteMovimiento);

export default router;