import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class PDFService {
  constructor() {
    // Crear carpeta de reportes si no existe
    this.reportesDir = path.join(__dirname, "../../reportes");
    if (!fs.existsSync(this.reportesDir)) {
      fs.mkdirSync(this.reportesDir, { recursive: true });
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  agregarHeader(doc, titulo) {
    // Fondo del header
    doc.rect(50, 50, 500, 70).fillAndStroke("#4A148C", "#4A148C");

    doc
      .fontSize(24)
      .fillColor("#FFFFFF")
      .text(titulo, 50, 70, { align: "center", width: 500 })
      .moveDown(0.3);

    doc
      .fontSize(9)
      .fillColor("#E0E0E0")
      .text(
        `Generado el: ${new Date().toLocaleString("es-CO", {
          dateStyle: "long",
          timeStyle: "short",
        })}`,
        50,
        95,
        { align: "center", width: 500 }
      );

    doc.moveDown(2);
  }

  agregarFooter(doc) {
    // FIX: Obtener el rango ANTES de intentar acceder a las páginas
    const range = doc.bufferedPageRange();

    // Validar que el rango sea válido
    if (!range || range.count === 0) {
      console.warn("No hay páginas para agregar footer");
      return;
    }

    const pageCount = range.count;
    const startPage = range.start;

    // FIX: Iterar desde el inicio del rango correctamente
    for (let i = 0; i < pageCount; i++) {
      const pageIndex = startPage + i;

      // Validar que la página existe antes de cambiar
      try {
        doc.switchToPage(pageIndex);
      } catch (error) {
        console.warn(
          `No se pudo cambiar a la página ${pageIndex}:`,
          error.message
        );
        continue;
      }

      const bottom = doc.page.height - 70;

      // Línea superior del footer
      doc
        .moveTo(50, bottom)
        .lineTo(550, bottom)
        .strokeColor("#BDC3C7")
        .lineWidth(1)
        .stroke();

      doc
        .fontSize(8)
        .fillColor("#95A5A6")
        .text(
          "Sistema de Gestion de Inventario y Tareas - SIGT",
          50,
          bottom + 10,
          { align: "center", width: 500 }
        )
        .text(`Pagina ${i + 1} de ${pageCount}`, 50, bottom + 25, {
          align: "center",
          width: 500,
        });
    }
  }

  crearTabla(doc, headers, rows, columnWidths) {
    const startX = 50;
    let startY = doc.y;
    const minRowHeight = 25;
    const headerHeight = 30;

    doc.fillColor("#7B2CBF").rect(startX, startY, 500, headerHeight).fill();

    doc.fillColor("#FFFFFF").fontSize(10);
    let xPos = startX + 10;

    headers.forEach((header, i) => {
      doc.text(header, xPos, startY + 10, {
        width: columnWidths[i] - 20,
        align: "left",
      });
      xPos += columnWidths[i];
    });

    startY += headerHeight;

    // Filas de datos
    rows.forEach((row, rowIndex) => {
      // Calcular altura necesaria para el texto más largo
      let maxHeight = minRowHeight;
      row.forEach((cell, i) => {
        const cellText = String(cell);
        const textHeight = doc.heightOfString(cellText, {
          width: columnWidths[i] - 20,
          lineGap: 2,
        });
        maxHeight = Math.max(maxHeight, textHeight + 16); // +16 para padding
      });

      // Nueva página si es necesario
      if (startY + maxHeight > doc.page.height - 100) {
        doc.addPage();
        startY = 50;
      }

      const fillColor = rowIndex % 2 === 0 ? "#F5F5F5" : "#FFFFFF";
      doc.fillColor(fillColor).rect(startX, startY, 500, maxHeight).fill();

      doc.fillColor("#2C3E50").fontSize(9);
      xPos = startX + 10;

      row.forEach((cell, i) => {
        doc.text(String(cell), xPos, startY + 8, {
          width: columnWidths[i] - 20,
          align: "left",
          lineGap: 2,
        });
        xPos += columnWidths[i];
      });

      startY += maxHeight;
    });

    doc.y = startY + 10;
  }

  // ========== REPORTE 1: VENTAS ==========

  async generarReporteVentas(ventas, filtros = {}) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-ventas-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE VENTAS");

        // Resumen
        const totalVentas = ventas.reduce(
          (sum, v) => sum + parseFloat(v.Total),
          0
        );
        const cantidadVentas = ventas.length;

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen General", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de ventas: ${cantidadVentas}`)
          .text(`Monto total: $${totalVentas.toLocaleString("es-CO")}`)
          .text(
            `Ticket promedio: $${(totalVentas / cantidadVentas).toLocaleString(
              "es-CO"
            )}`
          )
          .moveDown(1);

        // Tabla de ventas
        doc
          .fontSize(12)
          .text("Detalle de Ventas", { underline: true })
          .moveDown(0.5);

        const headers = ["#", "Fecha", "Cliente", "Ciudad", "Total"];
        const columnWidths = [40, 100, 150, 110, 100];
        const rows = ventas.map((venta, index) => [
          index + 1,
          new Date(venta.Fecha).toLocaleDateString("es-CO"),
          `${venta.Persona.Primer_Nombre} ${venta.Persona.Primer_Apellido}`,
          venta.Ciudad,
          `$${parseFloat(venta.Total).toLocaleString("es-CO")}`,
        ]);

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE 2: INVENTARIO ==========

  async generarReporteInventario(productos) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-inventario-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE INVENTARIO");

        // Resumen
        const stockTotal = productos.reduce((sum, p) => sum + p.Stock, 0);
        const valorTotal = productos.reduce(
          (sum, p) => sum + p.Stock * parseFloat(p.Precio),
          0
        );
        const stockCritico = productos.filter((p) => p.Stock < 5).length;

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen de Inventario", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de productos: ${productos.length}`)
          .text(`Stock total: ${stockTotal} unidades`)
          .text(`Valor del inventario: $${valorTotal.toLocaleString("es-CO")}`)
          .fillColor("#E74C3C")
          .text(`Productos en stock crítico: ${stockCritico}`)
          .fillColor("#2C3E50")
          .moveDown(1);

        // Tabla de productos
        doc
          .fontSize(12)
          .text("Detalle de Productos", { underline: true })
          .moveDown(0.5);

        const headers = ["Producto", "Talla", "Color", "Stock", "Precio"];
        const columnWidths = [150, 60, 80, 80, 130];
        const rows = productos.map((producto) => {
          const row = [
            producto.NombreProducto,
            producto.Talla,
            producto.Color,
            producto.Stock,
            `$${parseFloat(producto.Precio).toLocaleString("es-CO")}`,
          ];
          return row;
        });

        this.crearTabla(doc, headers, rows, columnWidths);

        // Alerta de stock crítico
        if (stockCritico > 0) {
          doc.addPage();
          doc
            .fontSize(14)
            .fillColor("#E74C3C")
            .text("ALERTA: Productos con Stock Critico (< 5 unidades)", {
              underline: true,
            })
            .moveDown(0.5);

          const productosCriticos = productos.filter((p) => p.Stock < 5);
          const headersCriticos = ["Producto", "Talla", "Color", "Stock"];
          const widthsCriticos = [180, 80, 100, 140];
          const rowsCriticos = productosCriticos.map((p) => [
            p.NombreProducto,
            p.Talla,
            p.Color,
            `${p.Stock}`,
          ]);

          this.crearTabla(doc, headersCriticos, rowsCriticos, widthsCriticos);
        }

        // FIX: Agregar footer después de terminar todo el contenido
        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE 3: PRODUCCIÓN ==========

  async generarReporteProduccion(producciones) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-produccion-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE PRODUCCIÓN");

        // Resumen
        const totalProducido = producciones.reduce(
          (sum, p) => sum + p.CantidadProducida,
          0
        );

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen de Produccion", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de registros: ${producciones.length}`)
          .text(`Unidades producidas: ${totalProducido}`)
          .moveDown(1);

        // Tabla de producción
        doc
          .fontSize(12)
          .text("Detalle de Producción", { underline: true })
          .moveDown(0.5);

        const headers = ["Fecha", "Empleado", "Cantidad", "Tarea"];
        const columnWidths = [80, 130, 70, 220];

        // FIX: Manejo seguro de las relaciones que pueden no existir
        const rows = producciones.map((prod) => {
          const fecha = new Date(prod.FechaProduccion).toLocaleDateString(
            "es-CO"
          );

          // Verificar si existe la relación con Persona/Empleado
          let empleado = "Sin asignar";
          if (prod.Persona) {
            empleado = `${prod.Persona.Primer_Nombre} ${prod.Persona.Primer_Apellido}`;
          } else if (prod.Empleado) {
            empleado = `${prod.Empleado.Primer_Nombre} ${prod.Empleado.Primer_Apellido}`;
          }

          // Verificar si existe la relación con Tarea - SIN LIMITAR
          let tarea = "Sin tarea";
          if (prod.Tarea && prod.Tarea.Descripcion) {
            tarea = prod.Tarea.Descripcion; // Descripción completa
          }

          return [fecha, empleado, `${prod.CantidadProducida} uds`, tarea];
        });

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE 4: EMPLEADOS ==========

  async generarReporteEmpleados(empleados) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-empleados-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE EMPLEADOS Y TAREAS");

        // Resumen
        const totalTareas = empleados.reduce(
          (sum, e) => sum + e.TotalTareas,
          0
        );
        const tareasCompletadas = empleados.reduce(
          (sum, e) => sum + e.TareasHechas,
          0
        );

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen General", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de empleados: ${empleados.length}`)
          .text(`Total de tareas: ${totalTareas}`)
          .text(`Tareas completadas: ${tareasCompletadas}`)
          .text(
            `Progreso general: ${(
              (tareasCompletadas / totalTareas) *
              100
            ).toFixed(2)}%`
          )
          .moveDown(1);

        // Tabla de empleados
        doc
          .fontSize(12)
          .text("Detalle de Empleados", { underline: true })
          .moveDown(0.5);

        const headers = ["Empleado", "Rol", "Hechas", "Pendientes", "Total"];
        const columnWidths = [150, 100, 70, 90, 90];
        const rows = empleados.map((emp) => [
          emp.Empleado,
          emp.Rol,
          emp.TareasHechas.toString(),
          emp.Pendientes.toString(),
          emp.TotalTareas.toString(),
        ]);

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE 5: CLIENTES ==========

  async generarReporteClientes(clientes) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-clientes-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE CLIENTES");

        // Resumen
        const totalClientes = clientes.length;
        const totalGastado = clientes.reduce(
          (sum, c) => sum + parseFloat(c.TotalGastado || 0),
          0
        );

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen de Clientes", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de clientes: ${totalClientes}`)
          .text(`Total facturado: $${totalGastado.toLocaleString("es-CO")}`)
          .moveDown(1);

        // Tabla de clientes
        doc
          .fontSize(12)
          .text("Detalle de Clientes", { underline: true })
          .moveDown(0.5);

        const headers = ["Cliente", "Correo", "Compras", "Total Gastado"];
        const columnWidths = [150, 150, 70, 130];
        const rows = clientes.map((cliente) => [
          `${cliente.Nombre} ${cliente.Apellido}`,
          cliente.Email,
          cliente.TotalCompras?.toString() || "0",
          `$${parseFloat(cliente.TotalGastado || 0).toLocaleString("es-CO")}`,
        ]);

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE DE MOVIMIENTOS (MEJORADO) ==========
  async generarReporteMovimientos(movimientos) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-movimientos-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE MOVIMIENTOS");

        // Resumen por tipo
        const entradas = movimientos.filter((m) => m.Tipo === "Entrada");
        const salidas = movimientos.filter((m) => m.Tipo === "Salida");
        const ajustes = movimientos.filter((m) => m.Tipo === "Ajuste");
        const devoluciones = movimientos.filter((m) => m.Tipo === "Devolucion");

        const totalEntradas = entradas.reduce((sum, m) => sum + m.Cantidad, 0);
        const totalSalidas = salidas.reduce((sum, m) => sum + m.Cantidad, 0);

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen de Movimientos", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de movimientos: ${movimientos.length}`)
          .fillColor("#27AE60")
          .text(`Entradas: ${entradas.length} (${totalEntradas} unidades)`)
          .fillColor("#E74C3C")
          .text(`Salidas: ${salidas.length} (${totalSalidas} unidades)`)
          .fillColor("#F39C12")
          .text(`Ajustes: ${ajustes.length}`)
          .fillColor("#3498DB")
          .text(`Devoluciones: ${devoluciones.length}`)
          .fillColor("#2C3E50")
          .moveDown(1);

        // Tabla de movimientos CON PRODUCTO COMPLETO
        doc
          .fontSize(12)
          .text("Detalle de Movimientos", { underline: true })
          .moveDown(0.5);

        const headers = ["Fecha", "Tipo", "Producto", "Cant.", "Responsable"];
        const columnWidths = [70, 60, 200, 50, 120];
        const rows = movimientos.map((mov) => {
          // Construir nombre completo del producto
          let productoCompleto = "N/A";
          if (mov.Producto) {
            const { NombreProducto, Talla, Color } = mov.Producto;
            productoCompleto = `${NombreProducto} - ${Color} - Talla ${Talla}`;
          }

          return [
            new Date(mov.Fecha).toLocaleDateString("es-CO"),
            mov.Tipo,
            productoCompleto,
            mov.Cantidad,
            mov.Persona
              ? `${mov.Persona.Primer_Nombre} ${mov.Persona.Primer_Apellido}`
              : "N/A",
          ];
        });

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE DE CARRITOS ABANDONADOS (MEJORADO) ==========
  async generarReporteCarritosAbandonados(carritos) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `reporte-carritos-abandonados-${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);
        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        this.agregarHeader(doc, "REPORTE DE CARRITOS ABANDONADOS");

        // Resumen
        const totalCarritos = carritos.length;
        const valorTotal = carritos.reduce(
          (sum, c) => sum + parseFloat(c.ValorEstimado),
          0
        );

        doc
          .fontSize(12)
          .fillColor("#2C3E50")
          .text("Resumen de Oportunidades Perdidas", { underline: true })
          .moveDown(0.5);

        doc
          .fontSize(10)
          .text(`Total de carritos abandonados: ${totalCarritos}`)
          .fillColor("#E74C3C")
          .text(
            `Valor estimado perdido: $${valorTotal.toLocaleString("es-CO")}`
          )
          .fillColor("#2C3E50")
          .moveDown(1);

        // Tabla de carritos
        doc
          .fontSize(12)
          .text("Detalle de Carritos Abandonados", { underline: true })
          .moveDown(0.5);

        const headers = ["Fecha", "Cliente", "Productos", "Valor"];
        const columnWidths = [70, 160, 150, 120];

        const rows = carritos.map((carrito) => {
          // Construir lista de productos
          let productosTexto = "Sin productos";
          if (carrito.Detalles && carrito.Detalles.length > 0) {
            productosTexto = carrito.Detalles.map(
              (d) => `${d.Producto} (${d.Cantidad})`
            ).join(", ");
          }

          return [
            new Date(carrito.FechaCreacion).toLocaleDateString("es-CO"),
            carrito.Cliente,
            productosTexto,
            `$${parseFloat(carrito.ValorEstimado).toLocaleString("es-CO")}`,
          ];
        });

        this.crearTabla(doc, headers, rows, columnWidths);

        // Sección detallada de cada carrito
        if (carritos.length > 0) {
          doc.addPage();
          doc
            .fontSize(14)
            .fillColor("#4A148C")
            .text("DETALLE COMPLETO DE PRODUCTOS", { underline: true })
            .moveDown(0.5);

          carritos.forEach((carrito, index) => {
            // Verificar espacio disponible
            if (doc.y > doc.page.height - 150) {
              doc.addPage();
            }

            doc
              .fontSize(11)
              .fillColor("#2C3E50")
              .text(`Carrito #${carrito.idCarrito} - ${carrito.Cliente}`, {
                underline: true,
              })
              .fontSize(9)
              .text(
                `Fecha: ${new Date(carrito.FechaCreacion).toLocaleDateString(
                  "es-CO"
                )}`
              )
              .text(`Estado: ${carrito.Estado}`)
              .text(`Contacto: ${carrito.Correo} - ${carrito.Telefono}`)
              .moveDown(0.3);

            if (carrito.Detalles && carrito.Detalles.length > 0) {
              const headersDetalle = ["Producto", "Cantidad", "Precio Unit."];
              const widthsDetalle = [280, 100, 120];
              const rowsDetalle = carrito.Detalles.map((d) => [
                d.Producto,
                d.Cantidad.toString(),
                `$${parseFloat(d.Precio).toLocaleString("es-CO")}`,
              ]);

              this.crearTabla(doc, headersDetalle, rowsDetalle, widthsDetalle);
            }

            doc
              .fontSize(10)
              .fillColor("#E74C3C")
              .text(
                `Total: $${parseFloat(carrito.ValorEstimado).toLocaleString(
                  "es-CO"
                )}`,
                {
                  align: "right",
                }
              )
              .fillColor("#2C3E50")
              .moveDown(1);
          });
        }

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  // ========== REPORTE DE MIS TAREAS ==========
  async generarReporteMisTareas(datos) {
    return new Promise((resolve, reject) => {
      try {
        const filename = `Reporte_Mis_Tareas_${Date.now()}.pdf`;
        const filepath = path.join(this.reportesDir, filename);

        const doc = new PDFDocument({ margin: 50, size: "LETTER" });
        const stream = fs.createWriteStream(filepath);

        doc.pipe(stream);

        // ========== HEADER CON FONDO MORADO ==========
        doc.rect(50, 50, doc.page.width - 100, 60).fill("#6A1B9A");

        doc
          .fontSize(18)
          .fillColor("#FFFFFF")
          .text("REPORTE DE MIS TAREAS", 50, 70, {
            width: doc.page.width - 100,
            align: "center",
          });

        doc
          .fontSize(10)
          .fillColor("#FFFFFF")
          .text(
            `Generado el ${new Date().toLocaleDateString(
              "es-CO"
            )} a las ${new Date().toLocaleTimeString("es-CO")}`,
            50,
            92,
            {
              width: doc.page.width - 100,
              align: "center",
            }
          );

        doc.moveDown(3);

        // ========== INFORMACIÓN DEL EMPLEADO (TEXTO NEGRO) ==========
        doc
          .fillColor("#000000")
          .fontSize(12)
          .text(`Empleado: ${datos.empleado.nombre}`, { underline: true })
          .fontSize(10)
          .text(`Correo: ${datos.empleado.correo}`)
          .moveDown(1);

        // ========== ESTADÍSTICAS ==========
        doc
          .fontSize(12)
          .fillColor("#6A1B9A")
          .text("Estadísticas Generales", { underline: true })
          .moveDown(0.5);

        const stats = datos.estadisticas;

        doc
          .fontSize(10)
          .fillColor("#000000")
          .text(`Total de tareas: ${stats.totalTareas}`)
          .text(`Completadas: ${stats.tareasCompletadas}`)
          .text(`En progreso: ${stats.tareasEnProgreso}`)
          .text(`Pendientes: ${stats.tareasPendientes}`)
          .text(`Total producido: ${stats.totalProducido} unidades`)
          .moveDown(1);

        // ========== TABLA DE TAREAS ==========
        doc
          .fontSize(12)
          .fillColor("#6A1B9A")
          .text("Mis Tareas", { underline: true })
          .moveDown(0.5);

        const headers = ["Estado", "Prioridad", "Límite", "Producto"];
        const columnWidths = [80, 70, 80, 270];

        const rows = datos.tareas.map((tarea) => [
          tarea.EstadoTarea,
          tarea.Prioridad,
          new Date(tarea.FechaLimite).toLocaleDateString("es-CO"),
          tarea.Producto?.NombreProducto || "N/A",
        ]);

        this.crearTabla(doc, headers, rows, columnWidths);

        this.agregarFooter(doc);
        doc.end();

        stream.on("finish", () => resolve({ filepath, filename }));
        stream.on("error", reject);
      } catch (error) {
        reject(error);
      }
    });
  }
}

export default new PDFService();
