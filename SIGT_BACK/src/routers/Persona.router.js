import { Router } from "express";;
import PersonaController from '../controller/Persona.controller.js';
import PersonaScheme from '../schemes/Persona.schema.js';
import personaMiddleware from '../middleware/validate.middleware.js';
import verifyToken  from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post('/register', personaMiddleware(PersonaScheme.createCliente), PersonaController.registerPersona);
router.post('/persona/login', PersonaController.loginPersona);
router.post('/persona/logout', checkBlacklist, PersonaController.logoutPersona);
router.post("/persona", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), personaMiddleware(PersonaScheme.createPersona), PersonaController.createPersona);
router.get('/persona',verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), PersonaController.showPersona); 
router.get('/persona/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado", "Cliente"), PersonaController.showPersonaId);
router.put('/persona/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Empleado", "Cliente"), personaMiddleware(PersonaScheme.updatePersona),PersonaController.updatePersona);
router.delete('/persona/:id', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), PersonaController.deletePersona);
router.put("/persona/:id/password", verifyToken, checkBlacklist, PersonaController.changePassword);
router.post("/persona/forgot-password", PersonaController.forgotPassword);
router.post("/persona/reset-password", PersonaController.resetPassword);

router.get('/clientes-compras', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), PersonaController.obtenerClientesConCompras);
router.get('/top-clientes', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), PersonaController.obtenerTopClientes);
router.get('/estadisticas-clientes', verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), PersonaController.obtenerEstadisticasClientes);

export default router;