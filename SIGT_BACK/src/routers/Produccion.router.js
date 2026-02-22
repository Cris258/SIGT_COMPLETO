import { Router } from "express";
import { createProduccion, showProduccion, showIdProduccion, updateProduccion, deleteProduccion } from "../controller/Produccion.controller.js";
import produccionScheme from '../schemes/Produccion.schema.js';
import produccionMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/produccion', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado"), produccionMiddleware(produccionScheme.createProduccion), createProduccion);
router.get('/produccion', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado"), showProduccion);
router.get('/produccion/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado"), showIdProduccion);
router.put('/produccion/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), produccionMiddleware(produccionScheme.updateProduccion), updateProduccion);
router.delete('/produccion/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), deleteProduccion);

export default router;