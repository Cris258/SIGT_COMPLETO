import { Router } from "express";
import { createVenta, showVenta, showIdVenta, updateVenta, deleteVenta, obtenerHistorialPorCliente, finalizarCompra } from "../controller/Venta.controller.js";
import ventaScheme from '../schemes/Venta.schema.js';
import validateMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/venta', verifyToken, checkBlacklist, authorizeRole('SuperAdmin', 'Administrador', 'Empleado',  'Cliente'), validateMiddleware(ventaScheme.createVenta), createVenta);
router.get('/venta', verifyToken, checkBlacklist, authorizeRole('SuperAdmin', 'Administrador', 'Empleado', 'Cliente'), showVenta);
router.get('/venta/historial/:idPersona', verifyToken, checkBlacklist, authorizeRole('Cliente', 'SuperAdmin', 'Administrador'), obtenerHistorialPorCliente);
router.get('/venta/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin', 'Administrador', 'Empleado', 'Cliente'), showIdVenta);
router.put('/venta/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin', 'Administrador'), validateMiddleware(ventaScheme.updateVenta), updateVenta);
router.delete('/venta/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin', 'Administrador'), deleteVenta);
router.post('/venta/finalizar', verifyToken, checkBlacklist, authorizeRole('Cliente'), finalizarCompra);

export default router;