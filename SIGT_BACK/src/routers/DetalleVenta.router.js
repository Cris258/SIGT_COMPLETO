import { Router } from "express";
import { createDetalleVenta, showDetalleVenta, showIdDetalleVenta, showDetallesByVenta, updateDetalleVenta, deleteDetalleVenta } from "../controller/DetalleVenta.controller.js";
import detalleVentaScheme from "../schemes/DetalleVenta.schema.js";
import validateMiddleware from "../middleware/validate.middleware.js";
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post("/detalleVenta", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), validateMiddleware(detalleVentaScheme.createDetalleVenta), createDetalleVenta);
router.get("/detalleVenta", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), showDetalleVenta);
router.get("/detalleventa/venta/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showDetallesByVenta);
router.get("/detalleVenta/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showIdDetalleVenta);
router.put("/detalleVenta/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), validateMiddleware(detalleVentaScheme.updateDetalleVenta), updateDetalleVenta);
router.delete("/detalleVenta/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador"), deleteDetalleVenta);

export default router;