import { Router } from "express";
import { createTarea, showTarea, showIdTarea, updateTarea, deleteTarea, completarTarea, getEstadisticas, getTopEmpleados, getEmpleadosTareas, getTareasByEmpleado, updateEstadoTarea } from "../controller/Tarea.controller.js";
import tareaScheme from '../schemes/Tarea.schema.js';
import validateMiddleware from '../middleware/validate.middleware.js';
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/tarea', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), validateMiddleware(tareaScheme.createTarea), createTarea);
router.get('/tarea', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado'), showTarea);
router.get('/tarea/empleado/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado'), getTareasByEmpleado);
router.get('/tarea/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado'), showIdTarea);
router.put('/tarea/:id/estado', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado'), updateEstadoTarea);
router.put('/tarea/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador', 'Empleado'), validateMiddleware(tareaScheme.updateTarea), updateTarea);
router.delete('/tarea/:id', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), deleteTarea);
router.put('/tarea/:id/completar', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador','Empleado'), completarTarea);

router.get('/estadisticas', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), getEstadisticas);
router.get('/top-empleados', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), getTopEmpleados);
router.get('/empleados-tareas', verifyToken, checkBlacklist, authorizeRole('SuperAdmin','Administrador'), getEmpleadosTareas);

export default router;