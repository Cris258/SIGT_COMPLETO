import { Router } from "express";
import { createEstadoPersona, showEstadoPersona, showEstadoPersonaId, updateEstadoPersona, deleteEstadoPersona } from "../controller/EstadoPersona.controller.js";
import rolScheme from '../schemes/EstadoPersona.schema.js';
import rolMiddleware from '../middleware/validate.middleware.js';
import verifyToken  from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/estado',  createEstadoPersona);
router.get('/estado',  showEstadoPersona);
router.get('/estado/:id',  showEstadoPersonaId);
router.put('/estado/:id',  updateEstadoPersona);
router.delete('/estado/:id',  deleteEstadoPersona);

export default router;