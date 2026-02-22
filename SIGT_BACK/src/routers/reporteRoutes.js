import { Router } from "express";
import reporteController from "../controller/reporteController.js";
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.get("/ventas/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteVentas);
router.get("/inventario/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteInventario);
router.get("/produccion/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteProduccion);
router.get("/empleados/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteEmpleados);
router.get("/clientes/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteClientes);

router.get("/movimientos/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteMovimientos);
router.get("/carritos-abandonados/pdf", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), reporteController.generarReporteCarritosAbandonados);
router.get("/mis-tareas/pdf", verifyToken, checkBlacklist, authorizeRole("Empleado"), reporteController.generarReporteMisTareas);

export default router;
