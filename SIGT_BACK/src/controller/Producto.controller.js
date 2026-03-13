import productoModel from "../models/Producto.model.js";
import db from "../config/connect.db.js";
import cloudinary from "../config/cloudinary.config.js";

// CREAR PRODUCTO (IMÁGENES OPCIONALES)
export const createProducto = async (req, res) => {
  try {
    const data = req.body;

    const imagenesUrl = [];
    const cloudinaryIds = [];

    // 👇 Solo subir imágenes si existen
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const result = await new Promise((resolve, reject) => {
          const uploadStream = cloudinary.uploader.upload_stream(
            {
              folder: "productos",
              resource_type: "auto",
            },
            (error, result) => {
              if (error) reject(error);
              else resolve(result);
            }
          );
          uploadStream.end(file.buffer);
        });

        imagenesUrl.push(result.secure_url);
        cloudinaryIds.push(result.public_id);
      }
    }

    const nuevoProducto = await productoModel.create({
      NombreProducto: data.NombreProducto,
      Color: data.Color,
      Talla: data.Talla,
      Estampado: data.Estampado,
      Stock: data.Stock,
      Precio: data.Precio,
      ImagenUrl: imagenesUrl.length > 0 ? imagenesUrl : null,
      CloudinaryId: cloudinaryIds.length > 0 ? cloudinaryIds : null,
    });

    res.status(201).json({
      ok: true,
      message: "Producto creado correctamente",
      id: nuevoProducto.idProducto,
      producto: nuevoProducto,
      totalImagenes: imagenesUrl.length,
    });
  } catch (error) {
    console.error("Error al crear producto:", error);
    res.status(500).json({
      ok: false,
      message: "Error al crear el producto",
      error: error.message,
    });
  }
};

// OBTENER TODOS LOS PRODUCTOS
export const showProducto = async (req, res) => {
  try {
    const productos = await productoModel.findAll({
      order: [["idProducto", "DESC"]],
    });

    res.status(200).json({
      ok: true,
      message: "Lista de productos",
      body: productos,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Error al obtener productos",
      error: error.message,
    });
  }
};

// OBTENER PRODUCTOS AGRUPADOS
export const obtenerProductosAgrupados = async (req, res) => {
  try {
    const productos = await productoModel.findAll({
      order: [['NombreProducto', 'ASC']]
    });

    const productosAgrupados = productos.reduce((acc, producto) => {
      const nombre = producto.NombreProducto;
      // Gracias al getter del modelo, ImagenUrl ya llega como array
      const imagenes = producto.ImagenUrl || [];

      if (!acc[nombre]) {
        acc[nombre] = {
          nombre: nombre,
          estampado: producto.Estampado,
          imagen_principal: imagenes.length > 0 ? imagenes[0] : null,
          precio_base: parseFloat(producto.Precio),
          colores: [],
          variantes: []
        };
      }

      // Agregar variante con todas sus imágenes
      acc[nombre].variantes.push({
        idProducto: producto.idProducto,
        color: producto.Color,
        talla: producto.Talla,
        precio: parseFloat(producto.Precio),
        stock: producto.Stock,
        imagenes: imagenes
      });

      // Agregar color si no existe, con todas sus imágenes
      const colorExiste = acc[nombre].colores.find(c => c.color === producto.Color);
      if (!colorExiste) {
        acc[nombre].colores.push({
          color: producto.Color,
          imagenUrl: imagenes.length > 0 ? imagenes[0] : null,
          imagenes: imagenes
        });
      }

      return acc;
    }, {});

    const resultado = Object.values(productosAgrupados);

    res.status(200).json({
      ok: true,
      message: "Productos agrupados",
      body: resultado
    });

  } catch (error) {
    console.error('Error al obtener productos agrupados:', error);
    res.status(500).json({
      ok: false,
      message: "Error al obtener productos agrupados",
      error: error.message
    });
  }
};

// OBTENER PRODUCTO POR ID
export const showIdProducto = async (req, res) => {
  try {
    const id = req.params.id;

    const producto = await productoModel.findOne({
      where: { idProducto: id },
    });

    if (!producto) {
      return res.status(404).json({
        ok: false,
        message: "Producto no encontrado",
      });
    }

    res.status(200).json({
      ok: true,
      message: "Producto encontrado",
      body: producto,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Error al buscar producto",
      error: error.message,
    });
  }
};

// ACTUALIZAR PRODUCTO
export const updateProducto = async (req, res) => {
  try {
    const id = req.params.id;
    const data = req.body;

    console.log("=== UPDATE PRODUCTO ===");
    console.log("ID recibido:", id);
    console.log("Body recibido:", JSON.stringify(data, null, 2));
    console.log("Archivos recibidos?:", req.files?.length || 0);

    const productoActual = await productoModel.findByPk(id);

    if (!productoActual) {
      console.log("❌ Producto no encontrado");
      return res.status(404).json({
        ok: false,
        message: "Producto no encontrado",
      });
    }

    console.log("✅ Producto encontrado:", productoActual.NombreProducto);

    const camposActualizar = {};

    if (data.NombreProducto !== undefined)
      camposActualizar.NombreProducto = data.NombreProducto;
    if (data.Color !== undefined) camposActualizar.Color = data.Color;
    if (data.Talla !== undefined) camposActualizar.Talla = data.Talla;
    if (data.Estampado !== undefined)
      camposActualizar.Estampado = data.Estampado;
    if (data.Stock !== undefined) camposActualizar.Stock = data.Stock;
    if (data.Precio !== undefined) camposActualizar.Precio = data.Precio;

    console.log(
      "Campos a actualizar:",
      JSON.stringify(camposActualizar, null, 2),
    );

    // Manejar imágenes si se enviaron archivos
    if (req.files && req.files.length > 0) {
      // Eliminar imágenes anteriores de Cloudinary
      if (
        productoActual.CloudinaryId &&
        Array.isArray(productoActual.CloudinaryId)
      ) {
        for (const cloudinaryId of productoActual.CloudinaryId) {
          await cloudinary.uploader.destroy(cloudinaryId);
        }
      }

      const imagenesUrl = [];
      const cloudinaryIds = [];

      // Subir nuevas imágenes
      for (const file of req.files) {
        const result = await new Promise((resolve, reject) => {
          const uploadStream = cloudinary.uploader.upload_stream(
            {
              folder: "productos",
              resource_type: "auto",
            },
            (error, result) => {
              if (error) reject(error);
              else resolve(result);
            },
          );
          uploadStream.end(file.buffer);
        });

        imagenesUrl.push(result.secure_url);
        cloudinaryIds.push(result.public_id);
      }

      camposActualizar.ImagenUrl = imagenesUrl;
      camposActualizar.CloudinaryId = cloudinaryIds;
    }

    console.log("Ejecutando UPDATE en base de datos...");
    const [rowsUpdated] = await productoModel.update(camposActualizar, {
      where: { idProducto: id },
    });

    console.log("✅ Filas actualizadas:", rowsUpdated);

    if (rowsUpdated === 0) {
      return res.status(404).json({
        ok: false,
        message: "Producto no encontrado o sin cambios",
      });
    }

    res.status(200).json({
      ok: true,
      message: "Producto actualizado correctamente",
    });
  } catch (error) {
    console.error("❌ ERROR COMPLETO:", error);
    res.status(500).json({
      ok: false,
      message: "Error al actualizar producto",
      error: error.message,
    });
  }
};

// ELIMINAR PRODUCTO
export const deleteProducto = async (req, res) => {
  try {
    const id = req.params.id;

    const producto = await productoModel.findByPk(id);

    if (!producto) {
      return res.status(404).json({
        ok: false,
        message: "Producto no encontrado",
      });
    }

    // Eliminar todas las imágenes de Cloudinary
    if (producto.CloudinaryId && Array.isArray(producto.CloudinaryId)) {
      for (const cloudinaryId of producto.CloudinaryId) {
        await cloudinary.uploader.destroy(cloudinaryId);
      }
    }

    await producto.destroy();

    res.status(200).json({
      ok: true,
      message: "Producto eliminado",
    });
  } catch (error) {
    console.error("Error al eliminar producto:", error);
    res.status(500).json({
      ok: false,
      message: "Error al eliminar producto",
      error: error.message,
    });
  }
};

// Obtener todos los productos
export const obtenerProductos = async (req, res) => {
  try {
    const query = `
      SELECT 
        p."idProducto" AS "ID",
        p."NombreProducto" AS "Nombre",
        p."Color",
        p."Talla",
        p."Stock",
        p."Precio"
      FROM "Productos" p
      ORDER BY p."Stock" ASC
    `;

    const [productos] = await db.query(query);
    res.json({ success: true, data: productos });
  } catch (error) {
    res.status(500).json({ success: false, message: "Error al obtener productos", error: error.message });
  }
};

export const obtenerTopProductos = async (req, res) => {
  try {
    const query = `
      SELECT 
        p."idProducto" AS "ID",
        p."NombreProducto" AS "Nombre",
        p."Color",
        p."Talla",
        p."Stock",
        p."Precio",
        COALESCE(SUM(dv."Cantidad"), 0) AS "UnidadesVendidas"
      FROM "Productos" p
      LEFT JOIN "DetalleVenta" dv ON p."idProducto" = dv."Producto_FK"
      GROUP BY p."idProducto", p."NombreProducto", p."Color", p."Talla", p."Stock", p."Precio"
      ORDER BY "UnidadesVendidas" DESC
      LIMIT 5
    `;

    const [topProductos] = await db.query(query);
    res.json({ success: true, data: topProductos });
  } catch (error) {
    res.status(500).json({ success: false, message: "Error al obtener top productos", error: error.message });
  }
};

export const obtenerEstadisticasInventario = async (req, res) => {
  try {
    const query = `
      SELECT 
        "Talla",
        COUNT(*) AS "Cantidad"
      FROM "Productos"
      GROUP BY "Talla"
      ORDER BY "Talla"
    `;

    const [porTalla] = await db.query(query);
    res.json({ success: true, data: { porTalla } });
  } catch (error) {
    res.status(500).json({ success: false, message: "Error al obtener estadísticas", error: error.message });
  }
};