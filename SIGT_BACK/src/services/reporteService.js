import { Op } from "sequelize";
import Venta from "../models/Venta.model.js";
import DetalleVenta from "../models/DetalleVenta.model.js";
import Persona from "../models/Persona.model.js";
import Producto from "../models/Producto.model.js";
import Movimiento from "../models/Movimiento.model.js";
import Produccion from "../models/Produccion.model.js";
import Tarea from "../models/Tarea.model.js";
import Carrito from "../models/Carrito.model.js";
import DetalleCarrito from "../models/DetalleCarrito.model.js";

class ReporteService {
  // ========== REPORTES DE VENTAS ==========

  async obtenerVentas(filtros = {}) {
    const where = {};

    // Filtro por rango de fechas
    if (filtros.fechaInicio && filtros.fechaFin) {
      where.Fecha = {
        [Op.between]: [
          new Date(filtros.fechaInicio),
          new Date(filtros.fechaFin),
        ],
      };
    }

    // Filtro por cliente
    if (filtros.clienteId) {
      where.Persona_FK = filtros.clienteId;
    }

    const ventas = await Venta.findAll({
      where,
      include: [
        {
          model: Persona,
          attributes: [
            "idPersona",
            "Primer_Nombre",
            "Primer_Apellido",
            "Correo",
          ],
        },
        {
          model: DetalleVenta,
          include: [
            {
              model: Producto,
              attributes: ["NombreProducto", "Talla", "Color"],
            },
          ],
        },
      ],
      order: [["Fecha", "DESC"]],
    });

    return ventas;
  }

  async obtenerVentasPorPeriodo(periodo = "mes") {
    const hoy = new Date();
    let fechaInicio;

    switch (periodo) {
      case "dia":
        fechaInicio = new Date(hoy.setHours(0, 0, 0, 0));
        break;
      case "semana":
        fechaInicio = new Date(hoy.setDate(hoy.getDate() - 7));
        break;
      case "mes":
        fechaInicio = new Date(hoy.setMonth(hoy.getMonth() - 1));
        break;
      case "año":
        fechaInicio = new Date(hoy.setFullYear(hoy.getFullYear() - 1));
        break;
      default:
        fechaInicio = new Date(hoy.setMonth(hoy.getMonth() - 1));
    }

    return this.obtenerVentas({
      fechaInicio,
      fechaFin: new Date(),
    });
  }

  // ========== REPORTES DE INVENTARIO ==========

  async obtenerInventario(filtros = {}) {
    const where = {};

    // Filtro por stock crítico
    if (filtros.stockCritico) {
      where.Stock = { [Op.lt]: 5 };
    }

    // Filtro por talla
    if (filtros.talla) {
      where.Talla = filtros.talla;
    }

    // Filtro por color
    if (filtros.color) {
      where.Color = filtros.color;
    }

    const productos = await Producto.findAll({
      where,
      order: [["Stock", "ASC"]],
    });

    return productos;
  }

  // ========== REPORTES DE PRODUCCIÓN ==========

  async obtenerProduccion(filtros = {}) {
    try {
      const where = {};

      if (filtros.fechaInicio && filtros.fechaFin) {
        where.FechaProduccion = {
          [Op.between]: [
            new Date(filtros.fechaInicio),
            new Date(filtros.fechaFin),
          ],
        };
      }

      if (filtros.empleadoId) {
        where.Persona_FK = filtros.empleadoId;
      }

      console.log("📊 Consultando producciones con filtros:", where);

      // Ahora SÍ podemos usar includes porque agregamos las asociaciones
      const producciones = await Produccion.findAll({
        where,
        include: [
          {
            model: Persona,
            attributes: ["idPersona", "Primer_Nombre", "Primer_Apellido"],
            required: false, // LEFT JOIN por si acaso
          },
          {
            model: Tarea,
            attributes: ["idTarea", "Descripcion", "Prioridad"],
            required: false, // LEFT JOIN por si acaso
          },
        ],
        order: [["FechaProduccion", "DESC"]],
      });

      console.log(`✅ ${producciones.length} producciones encontradas`);
      return producciones;
    } catch (error) {
      console.error("❌ Error en obtenerProduccion:", error);
      throw error;
    }
  }

  // ========== REPORTES DE EMPLEADOS ==========

  async obtenerEmpleados() {
    try {
      const empleados = await Persona.findAll({
        where: {
          Rol_FK: 3, // Rol de Empleado
        },
        attributes: [
          "idPersona",
          "Primer_Nombre",
          "Segundo_Nombre",
          "Primer_Apellido",
          "Segundo_Apellido",
        ],
        include: [
          {
            model: Tarea,
            attributes: ["idTarea", "EstadoTarea"],
            required: false,
          },
        ],
      });

      // Procesar datos
      const empleadosConTareas = empleados.map((emp) => {
        const tareas = emp.Tareas || [];
        const tareasCompletadas = tareas.filter(
          (t) => t.EstadoTarea === "Completada"
        ).length;
        const tareasPendientes = tareas.filter(
          (t) => t.EstadoTarea === "Pendiente"
        ).length;

        return {
          Empleado: `${emp.Primer_Nombre} ${emp.Primer_Apellido}`,
          Rol: "Empleado",
          TareasHechas: tareasCompletadas,
          Pendientes: tareasPendientes,
          TotalTareas: tareas.length,
        };
      });

      return empleadosConTareas;
    } catch (error) {
      console.error("Error en obtenerEmpleados:", error);
      throw error;
    }
  }

  // ========== REPORTES DE CLIENTES ==========

  async obtenerClientes() {
    try {
      console.log("🔍 Obteniendo clientes...");

      const clientes = await Persona.findAll({
        where: {
          Rol_FK: 4, // Rol de Cliente
        },
        attributes: ["idPersona", "Primer_Nombre", "Primer_Apellido", "Correo"],
        include: [
          {
            model: Venta,
            attributes: ["idVenta", "Total"],
            required: false,
          },
        ],
      });

      console.log(`📊 ${clientes.length} clientes encontrados`);

      // Procesar datos
      const clientesConCompras = clientes.map((cliente) => {
        // ⚠️ CLAVE: Es "Venta" (SINGULAR), NO "Ventas" (plural)
        const ventas = cliente.Venta || [];
        const totalCompras = ventas.length;

        // Sumar el total gastado de todas las ventas
        const totalGastado = ventas.reduce(
          (sum, venta) => sum + parseFloat(venta.Total || 0),
          0
        );

        console.log(
          `👤 Cliente: ${cliente.Primer_Nombre} ${cliente.Primer_Apellido}`
        );
        console.log(`   📦 Compras: ${totalCompras}`);
        console.log(`   💰 Total: $${totalGastado}`);

        return {
          Nombre: cliente.Primer_Nombre,
          Apellido: cliente.Primer_Apellido,
          Email: cliente.Correo,
          TotalCompras: totalCompras,
          TotalGastado: totalGastado.toFixed(2),
        };
      });

      return clientesConCompras;
    } catch (error) {
      console.error("❌ Error en obtenerClientes:", error);
      throw error;
    }
  }

  // ========== REPORTE DE MOVIMIENTOS ==========
  async obtenerMovimientos(filtros = {}) {
    try {
      const where = {};

      if (filtros.fechaInicio && filtros.fechaFin) {
        where.Fecha = {
          [Op.between]: [
            new Date(filtros.fechaInicio),
            new Date(filtros.fechaFin),
          ],
        };
      }

      if (filtros.productoId) {
        where.Producto_FK = filtros.productoId;
      }

      if (filtros.tipo) {
        where.Tipo = filtros.tipo;
      }

      console.log("📊 Consultando movimientos...");

      const movimientos = await Movimiento.findAll({
        where,
        include: [
          {
            model: Persona,
            attributes: ["Primer_Nombre", "Primer_Apellido"],
            required: false,
          },
          // ❌ REMOVIDO: Producto no está asociado directamente
          // Usaremos Producto_FK para buscar el producto manualmente
        ],
        order: [["Fecha", "DESC"]],
      });

      // ✅ Cargar productos manualmente
      const movimientosConProductos = await Promise.all(
        movimientos.map(async (mov) => {
          const movJSON = mov.toJSON();

          if (mov.Producto_FK) {
            const producto = await Producto.findByPk(mov.Producto_FK, {
              attributes: ["NombreProducto", "Talla", "Color"],
            });
            movJSON.Producto = producto;
          }

          return movJSON;
        })
      );

      console.log(
        `✅ ${movimientosConProductos.length} movimientos encontrados`
      );
      return movimientosConProductos;
    } catch (error) {
      console.error("❌ Error en obtenerMovimientos:", error);
      throw error;
    }
  }

  // ========== REPORTE DE CARRITOS ABANDONADOS ==========
  async obtenerCarritosAbandonados() {
    try {
      console.log("🛒 Consultando carritos abandonados...");

      const carritosAbandonados = await Carrito.findAll({
        where: {
          Estado: {
            [Op.ne]: "completado",
          },
        },
        include: [
          {
            model: Persona,
            attributes: [
              "Primer_Nombre",
              "Primer_Apellido",
              "Correo",
              "Telefono",
            ],
            required: false,
          },
          {
            model: DetalleCarrito,
            include: [
              {
                model: Producto,
                // ✅ AGREGADO: Color y Talla
                attributes: ["NombreProducto", "Precio", "Talla", "Color"],
                required: false,
              },
            ],
            required: false,
          },
        ],
        order: [["FechaCreacion", "DESC"]],
      });

      const carritosConTotales = carritosAbandonados.map((carrito) => {
        const detalles = carrito.DetalleCarritos || [];
        const totalProductos = detalles.reduce((sum, d) => sum + d.Cantidad, 0);
        const valorEstimado = detalles.reduce(
          (sum, d) => sum + d.Cantidad * parseFloat(d.Producto?.Precio || 0),
          0
        );

        return {
          idCarrito: carrito.idCarrito,
          FechaCreacion: carrito.FechaCreacion,
          Estado: carrito.Estado,
          Cliente: carrito.Persona
            ? `${carrito.Persona.Primer_Nombre} ${carrito.Persona.Primer_Apellido}`
            : "Desconocido",
          Correo: carrito.Persona?.Correo || "N/A",
          Telefono: carrito.Persona?.Telefono || "N/A",
          TotalProductos: totalProductos,
          ValorEstimado: valorEstimado.toFixed(2),
          Detalles: detalles.map((d) => {
            // ✅ PRODUCTO COMPLETO: Nombre + Color + Talla
            const prod = d.Producto;
            const nombreCompleto = prod
              ? `${prod.NombreProducto} - ${prod.Color} - Talla ${prod.Talla}`
              : "Desconocido";

            return {
              Producto: nombreCompleto,
              Cantidad: d.Cantidad,
              Precio: prod?.Precio || 0,
            };
          }),
        };
      });

      console.log(
        `✅ ${carritosConTotales.length} carritos abandonados/pendientes`
      );
      return carritosConTotales;
    } catch (error) {
      console.error("❌ Error en obtenerCarritosAbandonados:", error);
      throw error;
    }
  }

  // ========== REPORTE DE MIS TAREAS (Para empleado logueado) ==========
  async obtenerMisTareas(empleadoId) {
    try {
      console.log(`📋 Consultando tareas del empleado ${empleadoId}...`);

      const empleado = await Persona.findByPk(empleadoId, {
        attributes: ["Primer_Nombre", "Primer_Apellido", "Correo"],
      });

      if (!empleado) {
        throw new Error("Empleado no encontrado");
      }

      const tareas = await Tarea.findAll({
        where: {
          Persona_FK: empleadoId,
        },
        include: [
          {
            model: Producto,
            attributes: ["NombreProducto", "Talla", "Color"],
            required: false,
          },
        ],
        order: [["FechaLimite", "DESC"]],
      });

      const producciones = await Produccion.findAll({
        where: {
          Persona_FK: empleadoId,
        },
        include: [
          {
            model: Tarea,
            attributes: ["Descripcion"],
            required: false,
          },
        ],
        order: [["FechaProduccion", "DESC"]],
      });

      const totalTareas = tareas.length;
      const tareasCompletadas = tareas.filter(
        (t) => t.EstadoTarea === "Completada"
      ).length;
      const tareasPendientes = tareas.filter(
        (t) => t.EstadoTarea === "Pendiente"
      ).length;
      const tareasEnProgreso = tareas.filter(
        (t) => t.EstadoTarea === "En Progreso"
      ).length;

      const totalProducido = producciones.reduce(
        (sum, p) => sum + p.CantidadProducida,
        0
      );

      return {
        empleado: {
          nombre: `${empleado.Primer_Nombre} ${empleado.Primer_Apellido}`,
          correo: empleado.Correo,
        },
        estadisticas: {
          totalTareas,
          tareasCompletadas,
          tareasPendientes,
          tareasEnProgreso,
          totalProducido,
        },
        tareas,
        producciones,
      };
    } catch (error) {
      console.error("❌ Error en obtenerMisTareas:", error);
      throw error;
    }
  }
}

export default new ReporteService();
