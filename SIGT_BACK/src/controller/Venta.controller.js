import ventaModel from "../models/Venta.model.js";
import detalleVentaModel from "../models/DetalleVenta.model.js";
import productoModel from "../models/Producto.model.js";
import movimientoModel from "../models/Movimiento.model.js";
import personaModel from "../models/Persona.model.js";

export const createVenta = async (req, res) => {
  try {
    await ventaModel.sync();
    const dataVenta = req.body;
    const createVenta = await ventaModel.create({
      Fecha: dataVenta.Fecha,
      Total: dataVenta.Total,
      DireccionEntrega: dataVenta.DireccionEntrega,
      Ciudad: dataVenta.Ciudad,
      Departamento: dataVenta.Departamento,
      Persona_FK: parseInt(dataVenta.Persona_FK),
    });
    res.status(201).json({
      ok: true,
      status: 201,
      Message: "Venta Creada",
      id: createVenta.idVenta,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showVenta = async (req, res) => {
  try {
    await ventaModel.sync();
    let ventas;

    if (req.user.rol === "Cliente" || req.user.rol === "Empleado") {
      ventas = await ventaModel.findAll({
        where: { Persona_FK: req.user.id },
      });
    } else {
      ventas = await ventaModel.findAll();
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Ventas",
      body: ventas,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showIdVenta = async (req, res) => {
  try {
    await ventaModel.sync();
    const idVenta = req.params.id;

    const venta = await ventaModel.findOne({
      where: { idVenta },
    });

    if (!venta) {
      return res.status(404).json({ Message: "Venta no encontrada" });
    }

    if (
      (req.user.rol === "Cliente" || req.user.rol === "Empleado") &&
      venta.Persona_FK !== req.user.id
    ) {
      return res
        .status(403)
        .json({ Message: "No puedes ver una venta que no es tuya" });
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Venta por ID",
      body: venta,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const updateVenta = async (req, res) => {
  try {
    await ventaModel.sync();
    const dataVenta = req.body;
    const idVenta = req.params.id;
    const updateVenta = await ventaModel.update(
      {
        Fecha: dataVenta.Fecha,
        Total: dataVenta.Total,
        DireccionEntrega: dataVenta.DireccionEntrega,
        Ciudad: dataVenta.Ciudad,
        Departamento: dataVenta.Departamento,
        Persona_FK: parseInt(dataVenta.Persona_FK),
      },
      {
        where: {
          idVenta: idVenta,
        },
      }
    );
    res.status(200).json({
      ok: true,
      status: 201,
      Message: "Venta Actualizada",
      body: updateVenta,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const deleteVenta = async (req, res) => {
  try {
    await ventaModel.sync();
    const idVenta = req.params.id;
    const deleteVenta = await ventaModel.destroy({
      where: {
        idVenta: idVenta,
      },
    });
    res.status(200).json({
      ok: true,
      status: 201,
      Message: "Venta Eliminada",
      body: deleteVenta,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

// Obtener historial de compras de un cliente específico
export const obtenerHistorialPorCliente = async (req, res) => {
  try {
    const { idPersona } = req.params;

    console.log("Buscando historial para idPersona:", idPersona);

    // Verificar que la persona existe
    const persona = await personaModel.findByPk(idPersona);
    if (!persona) {
      return res.status(404).json({
        ok: false,
        msg: "Persona no encontrada",
      });
    }

    console.log("Persona encontrada:", persona.Primer_Nombre);

    // Obtener todas las ventas de la persona
    const ventas = await ventaModel.findAll({
      where: { Persona_FK: idPersona },
      order: [["Fecha", "DESC"]],
    });

    console.log("Ventas encontradas:", ventas.length);

    // Importa el modelo de carrito
    const carritoModel = (await import("../models/Carrito.model.js")).default;

    // Para cada venta, obtener sus detalles y el carrito relacionado
    const ventasConDetalles = await Promise.all(
      ventas.map(async (venta) => {
        // Buscar el carrito que generó esta venta (por fecha y persona)
        const carrito = await carritoModel.findOne({
          where: { 
            Persona_FK: idPersona,
            Estado: 'completado'
          },
          order: [["FechaCreacion", "DESC"]]
        });

        const detalles = await detalleVentaModel.findAll({
          where: { Venta_FK: venta.idVenta },
        });

        const detallesConProducto = await Promise.all(
          detalles.map(async (detalle) => {
            const producto = await productoModel.findByPk(detalle.Producto_FK);
            
            // 🔥 AQUÍ ESTÁ EL CAMBIO IMPORTANTE
            return {
              NombreProducto: producto.NombreProducto,
              Color: producto.Color,
              Talla: producto.Talla,
              Cantidad: detalle.Cantidad,
              PrecioUnitario: parseFloat(detalle.PrecioUnitario),
              Imagen: producto.ImagenUrl, // 👈 AGREGAR ESTA LÍNEA
            };
          })
        );

        return {
          idVenta: venta.idVenta,
          idCarrito: carrito ? carrito.idCarrito : null,
          FechaVenta: venta.Fecha,
          Total: parseFloat(venta.Total),
          EstadoCarrito: carrito ? carrito.Estado : "N/A",
          detalles: detallesConProducto,
        };
      })
    );

    console.log("Ventas formateadas:", ventasConDetalles);

    res.status(200).json({
      ok: true,
      body: ventasConDetalles,
    });
  } catch (error) {
    console.error("Error completo al obtener historial:", error);
    res.status(500).json({
      ok: false,
      msg: "Error al obtener el historial de compras",
      error: error.message,
    });
  }
};

// FINALIZAR COMPRA
export const finalizarCompra = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { DireccionEntrega, Ciudad, Departamento, productos } = req.body;
    const personaId = req.user.id;

    // ── Validaciones básicas ──────────────────────────────────────────────────
    if (!DireccionEntrega || !Ciudad || !Departamento) {
      await t.rollback();
      return res.status(400).json({ ok: false, message: "Dirección, ciudad y departamento son obligatorios" });
    }
    if (!productos || !Array.isArray(productos) || productos.length === 0) {
      await t.rollback();
      return res.status(400).json({ ok: false, message: "No hay productos en la compra" });
    }

    // ── Verificar stock de cada producto ─────────────────────────────────────
    for (const item of productos) {
      const producto = await productoModel.findByPk(item.idProducto, { transaction: t });
      if (!producto) {
        await t.rollback();
        return res.status(404).json({ ok: false, message: `Producto ${item.idProducto} no encontrado` });
      }
      if (producto.Stock < item.cantidad) {
        await t.rollback();
        return res.status(400).json({
          ok: false,
          message: `Stock insuficiente para ${producto.NombreProducto} (${producto.Color} - ${producto.Talla}). Disponible: ${producto.Stock}`
        });
      }
    }

    // ── Calcular total ────────────────────────────────────────────────────────
    const total = productos.reduce((acc, item) => acc + item.precioUnitario * item.cantidad, 0);

    // ── Crear Venta ───────────────────────────────────────────────────────────
    const venta = await ventaModel.create({
      Fecha: new Date(),
      Total: total,
      DireccionEntrega,
      Ciudad,
      Departamento,
      Persona_FK: personaId,
    }, { transaction: t });

    // ── Crear DetalleVenta + bajar stock + crear Movimiento ──────────────────
    const detallesParaFactura = [];

    for (const item of productos) {
      const producto = await productoModel.findByPk(item.idProducto, { transaction: t });

      // DetalleVenta
      await detalleVentaModel.create({
        Cantidad: item.cantidad,
        PrecioUnitario: item.precioUnitario,
        Producto_FK: item.idProducto,
        Venta_FK: venta.idVenta,
      }, { transaction: t });

      // Bajar stock
      await productoModel.update(
        { Stock: producto.Stock - item.cantidad },
        { where: { idProducto: item.idProducto }, transaction: t }
      );

      // Movimiento de salida
      await movimientoModel.create({
        Tipo: "Salida",
        Cantidad: item.cantidad,
        Fecha: new Date(),
        Motivo: `Venta #${venta.idVenta}`,
        Persona_FK: personaId,
        Producto_FK: item.idProducto,
      }, { transaction: t });

      // Armar detalle para la factura
      detallesParaFactura.push({
        idProducto: item.idProducto,
        nombre: producto.NombreProducto,
        color: producto.Color,
        talla: producto.Talla,
        estampado: producto.Estampado,
        imagen: Array.isArray(producto.ImagenUrl) ? producto.ImagenUrl[0] : null,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        subtotal: item.precioUnitario * item.cantidad,
      });
    }

    // ── Obtener datos del cliente para la factura ─────────────────────────────
    const persona = await personaModel.findByPk(personaId, { transaction: t });

    await t.commit();

    // ── Respuesta con toda la info para el modal de factura ───────────────────
    return res.status(201).json({
      ok: true,
      message: "Compra finalizada exitosamente",
      factura: {
        idVenta: venta.idVenta,
        fecha: venta.Fecha,
        cliente: {
          nombre: `${persona.Primer_Nombre} ${persona.Primer_Apellido}`,
          documento: persona.Numero_Documento || "",
          email: persona.Correo || "",
          telefono: persona.Telefono || "",
        },
        envio: {
          direccion: DireccionEntrega,
          ciudad: Ciudad,
          departamento: Departamento,
        },
        productos: detallesParaFactura,
        total,
      }
    });

  } catch (error) {
    await t.rollback();
    console.error("Error al finalizar compra:", error);
    return res.status(500).json({
      ok: false,
      message: "Error al procesar la compra",
      error: error.message,
    });
  }
};