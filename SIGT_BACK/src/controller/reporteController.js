import reporteService from "../services/reporteService.js";
import pdfService from "../services/pdfService.js";

class ReporteController {
  // ========== REPORTE DE VENTAS ==========

  async generarReporteVentas(req, res) {
    try {
      console.log("📊 Generando reporte de ventas...");
      const { fechaInicio, fechaFin, clienteId, periodo } = req.query;

      let ventas;
      if (periodo) {
        ventas = await reporteService.obtenerVentasPorPeriodo(periodo);
      } else {
        ventas = await reporteService.obtenerVentas({
          fechaInicio,
          fechaFin,
          clienteId,
        });
      }

      if (ventas.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron ventas para los filtros especificados",
        });
      }

      console.log(`✅ ${ventas.length} ventas encontradas`);

      const { filepath, filename } = await pdfService.generarReporteVentas(
        ventas,
        {
          fechaInicio,
          fechaFin,
          periodo,
        }
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename, (err) => {
        if (err) {
          console.error("Error al descargar:", err);
          res.status(500).json({
            success: false,
            message: "Error al descargar el archivo",
          });
        }
      });
    } catch (error) {
      console.error("❌ Error en generarReporteVentas:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de ventas",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE INVENTARIO ==========

  async generarReporteInventario(req, res) {
    try {
      console.log("📊 Generando reporte de inventario...");
      const { stockCritico, talla, color } = req.query;

      const productos = await reporteService.obtenerInventario({
        stockCritico: stockCritico === "true",
        talla,
        color,
      });

      if (productos.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron productos",
        });
      }

      console.log(`✅ ${productos.length} productos encontrados`);

      const { filepath, filename } = await pdfService.generarReporteInventario(
        productos
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteInventario:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de inventario",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE PRODUCCIÓN ==========

  async generarReporteProduccion(req, res) {
    try {
      console.log("📊 Generando reporte de producción...");
      const { fechaInicio, fechaFin, empleadoId } = req.query;

      const producciones = await reporteService.obtenerProduccion({
        fechaInicio,
        fechaFin,
        empleadoId,
      });

      if (producciones.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron registros de producción",
        });
      }

      console.log(`✅ ${producciones.length} producciones encontradas`);

      const { filepath, filename } = await pdfService.generarReporteProduccion(
        producciones
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteProduccion:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de producción",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE EMPLEADOS ==========

  async generarReporteEmpleados(req, res) {
    try {
      console.log("📊 Generando reporte de empleados...");

      const empleados = await reporteService.obtenerEmpleados();

      if (empleados.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron empleados",
        });
      }

      console.log(`✅ ${empleados.length} empleados encontrados`);

      const { filepath, filename } = await pdfService.generarReporteEmpleados(
        empleados
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteEmpleados:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de empleados",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE CLIENTES ==========

  async generarReporteClientes(req, res) {
    try {
      console.log("📊 Generando reporte de clientes...");

      const clientes = await reporteService.obtenerClientes();

      if (clientes.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron clientes",
        });
      }

      console.log(`✅ ${clientes.length} clientes encontrados`);

      const { filepath, filename } = await pdfService.generarReporteClientes(
        clientes
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteClientes:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de clientes",
        error: error.message,
      });
    }
  }

  // ========== OBTENER DATOS JSON (sin PDF) ==========

  async obtenerDatosVentas(req, res) {
    try {
      const { fechaInicio, fechaFin, clienteId } = req.query;
      const ventas = await reporteService.obtenerVentas({
        fechaInicio,
        fechaFin,
        clienteId,
      });

      res.json({
        success: true,
        data: ventas,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Error al obtener datos de ventas",
        error: error.message,
      });
    }
  }

  async obtenerDatosInventario(req, res) {
    try {
      const { stockCritico, talla, color } = req.query;
      const productos = await reporteService.obtenerInventario({
        stockCritico: stockCritico === "true",
        talla,
        color,
      });

      res.json({
        success: true,
        data: productos,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Error al obtener datos de inventario",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE MOVIMIENTOS ==========
  async generarReporteMovimientos(req, res) {
    try {
      console.log("📊 Generando reporte de movimientos...");
      const { fechaInicio, fechaFin, productoId, tipo } = req.query;

      const movimientos = await reporteService.obtenerMovimientos({
        fechaInicio,
        fechaFin,
        productoId,
        tipo,
      });

      if (movimientos.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No se encontraron movimientos",
        });
      }

      console.log(`✅ ${movimientos.length} movimientos encontrados`);

      const { filepath, filename } = await pdfService.generarReporteMovimientos(
        movimientos
      );

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteMovimientos:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de movimientos",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE CARRITOS ABANDONADOS ==========
  async generarReporteCarritosAbandonados(req, res) {
    try {
      console.log("🛒 Generando reporte de carritos abandonados...");

      const carritos = await reporteService.obtenerCarritosAbandonados();

    if (carritos.length === 0) {
  return res.status(404).json({
    success: false,
    message: "No hay carritos abandonados o pendientes",
  });
}

      console.log(`✅ ${carritos.length} carritos encontrados`);

      const { filepath, filename } =
        await pdfService.generarReporteCarritosAbandonados(carritos);

      console.log(`✅ PDF generado: ${filename}`);

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteCarritosAbandonados:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de carritos abandonados",
        error: error.message,
      });
    }
  }

  // ========== REPORTE DE MIS TAREAS ==========
  async generarReporteMisTareas(req, res) {
    try {
      console.log("📋 Generando reporte de mis tareas...");
      console.log("REQ.USER =>", req.user);

      let empleadoId;

      // ✅ Usar ID directamente desde el token
      if (req.user && req.user.id) {
        empleadoId = req.user.id;
        console.log(`👤 Empleado desde token: ${empleadoId}`);
      }
      // 🔧 fallback para testing
      else if (req.query.empleadoId) {
        empleadoId = parseInt(req.query.empleadoId);
        console.log(`👤 Empleado desde query: ${empleadoId}`);
      }

      if (!empleadoId) {
        return res.status(400).json({
          success: false,
          message:
            "ID de empleado no proporcionado. Autentícate o usa ?empleadoId=X",
        });
      }

      const datos = await reporteService.obtenerMisTareas(empleadoId);

      if (datos.tareas.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No tienes tareas asignadas",
        });
      }

      const { filepath, filename } = await pdfService.generarReporteMisTareas(
        datos
      );

      res.download(filepath, filename);
    } catch (error) {
      console.error("❌ Error en generarReporteMisTareas:", error);
      res.status(500).json({
        success: false,
        message: "Error al generar el reporte de tareas",
        error: error.message,
      });
    }
  }
}

export default new ReporteController();
