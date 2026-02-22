import { Router } from "express";
import { createRol, showRol, showIdRol, updateRol, deleteRol } from "../controller/Rol.controller.js";
import rolScheme from '../schemes/Rol.schema.js';
import rolMiddleware from '../middleware/validate.middleware.js';
import verifyToken  from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/rol', createRol);
router.get('/rol',  showRol);
router.get('/rol/:id', showIdRol);
router.put('/rol/:id',updateRol);
router.delete('/rol/:id',  deleteRol);

export default router;