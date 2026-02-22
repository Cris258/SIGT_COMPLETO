import reporteService from '../services/reporteService.js';
import pdfService from '../services/pdfService.js';

class ReporteController {
  // ========== REPORTE DE VENTAS ==========
  async generarReporteVentas(req, res) {
    try {
      const { fechaInicio, fechaFin, clienteId, periodo } = req.query;

      let ventas;
      if (periodo) {
        ventas = await reporteService.obtenerVentasPorPeriodo(periodo);
      } else {
        ventas = await reporteService.obtenerVentas({ fechaInicio, fechaFin, clienteId });
      }

      if (ventas.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron ventas para los filtros especificados'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteVentas(ventas, {
        fechaInicio,
        fechaFin,
        periodo
      });

      res.download(filepath, filename, (err) => {
        if (err) {
          console.error('Error al descargar:', err);
          res.status(500).json({
            success: false,
            message: 'Error al descargar el archivo'
          });
        }
      });
    } catch (error) {
      console.error('Error en generarReporteVentas:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de ventas',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE INVENTARIO ==========
  async generarReporteInventario(req, res) {
    try {
      const { stockCritico, talla, color } = req.query;

      const productos = await reporteService.obtenerInventario({
        stockCritico: stockCritico === 'true',
        talla,
        color
      });

      if (productos.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron productos'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteInventario(productos);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteInventario:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de inventario',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE PRODUCCIÓN ==========
  async generarReporteProduccion(req, res) {
    try {
      const { fechaInicio, fechaFin, empleadoId } = req.query;

      const producciones = await reporteService.obtenerProduccion({
        fechaInicio,
        fechaFin,
        empleadoId
      });

      if (producciones.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron registros de producción'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteProduccion(producciones);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteProduccion:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de producción',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE EMPLEADOS ==========
  async generarReporteEmpleados(req, res) {
    try {
      const empleados = await reporteService.obtenerEmpleados();

      if (empleados.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron empleados'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteEmpleados(empleados);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteEmpleados:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de empleados',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE CLIENTES ==========
  async generarReporteClientes(req, res) {
    try {
      const clientes = await reporteService.obtenerClientes();

      if (clientes.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron clientes'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteClientes(clientes);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteClientes:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de clientes',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE MOVIMIENTOS ==========
  async generarReporteMovimientos(req, res) {
    try {
      const { productoId, fechaInicio, fechaFin, tipo } = req.query;

      const movimientos = await reporteService.obtenerMovimientos({
        productoId,
        fechaInicio,
        fechaFin,
        tipo
      });

      if (movimientos.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron movimientos'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteMovimientos(movimientos);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteMovimientos:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de movimientos',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE CARRITOS ABANDONADOS ==========
  async generarReporteCarritosAbandonados(req, res) {
    try {
      const carritos = await reporteService.obtenerCarritosAbandonados();

      if (carritos.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron carritos abandonados'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteCarritosAbandonados(carritos);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteCarritosAbandonados:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de carritos abandonados',
        error: error.message
      });
    }
  }

  // ========== REPORTE DE MIS TAREAS (EMPLEADO) ==========
  async generarReporteMisTareas(req, res) {
    try {
      const empleadoId = req.persona.idPersona;

      const datos = await reporteService.obtenerMisTareas(empleadoId);

      if (!datos || datos.tareas.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontraron tareas asignadas'
        });
      }

      const { filepath, filename } = await pdfService.generarReporteMisTareas(datos);

      res.download(filepath, filename);
    } catch (error) {
      console.error('Error en generarReporteMisTareas:', error);
      res.status(500).json({
        success: false,
        message: 'Error al generar el reporte de mis tareas',
        error: error.message
      });
    }
  }
}

export default new ReporteController();