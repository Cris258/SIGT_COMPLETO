import { Router } from "express";
import { createDetalleCarrito, showDetalleCarrito, showIdDetalleCarrito, showDetallesByCarrito, updateDetalleCarrito, deleteDetalleCarrito } from "../controller/DetalleCarrito.controller.js";
import detalleCarritoScheme from "../schemes/DetalleCarrito.schema.js";
import detalleCarritoMiddleware from "../middleware/validate.middleware.js";
import verifyToken from "../middleware/jwt.middleware.js";
import authorizeRole from "../middleware/rol.middleware.js";
import { checkBlacklist } from "../middleware/tokenBlacklist.js";

const router = Router();

router.post("/detalleCarrito", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), detalleCarritoMiddleware(detalleCarritoScheme.createDetalleCarrito), createDetalleCarrito);
router.get("/detalleCarrito", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showDetalleCarrito);
router.get("/detalleCarrito/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showIdDetalleCarrito);
router.get("/detalleCarrito/carrito/:idCarrito", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), showDetallesByCarrito);
router.put("/detalleCarrito/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), detalleCarritoMiddleware(detalleCarritoScheme.updateDetalleCarrito), updateDetalleCarrito);
router.delete("/detalleCarrito/:id", verifyToken, checkBlacklist, authorizeRole("SuperAdmin", "Administrador", "Cliente"), deleteDetalleCarrito);

export default router;