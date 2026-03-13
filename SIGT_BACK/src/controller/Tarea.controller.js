import tareaModel from "../models/Tarea.model.js";
import Producto from '../models/Producto.model.js';
import Movimiento from '../models/Movimiento.model.js';
import Produccion from '../models/Produccion.model.js';
import sequelize from "../config/connect.db.js";

export const createTarea = async (req, res) => {
  try {
    const data = req.body;

    const nueva = await tareaModel.create({
      Descripcion: data.Descripcion,
      FechaAsignacion: data.FechaAsignacion,
      FechaLimite: data.FechaLimite,
      EstadoTarea: data.EstadoTarea,
      Prioridad: data.Prioridad,
      Persona_FK: parseInt(data.Persona_FK),
      Producto_FK: parseInt(data.Producto_FK),
    });

    return res.status(201).json({
      ok: true,
      status: 201,
      Message: "Tarea creada correctamente",
      id: nueva.idTarea,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al crear la tarea",
      error: error.message,
    });
  }
};


export const showTarea = async (req, res) => {
  try {
    let tareas;

    if (req.user.rol === "Empleado") {
      tareas = await tareaModel.findAll({
        where: { Persona_FK: req.user.id },
        include: [
          {
            model: Producto,
          }
        ]
      });
    } else {
      tareas = await tareaModel.findAll({
        include: [
          {
            model: Producto,
          }
        ]
      });
    }

    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Listado de tareas",
      body: tareas,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al obtener tareas",
      error: error.message,
    });
  }
};


export const showIdTarea = async (req, res) => {
  try {
    const id = req.params.id;

    const tarea = await tareaModel.findOne({ 
      where: { idTarea: id },
      include: [
        {
          model: Producto,
        }
      ]
    });

    if (!tarea) {
      return res.status(404).json({ Message: "Tarea no encontrada" });
    }

    if (req.user.rol === "Empleado" && tarea.Persona_FK !== req.user.id) {
      return res.status(403).json({
        Message: "No puedes ver tareas que no te pertenecen",
      });
    }

    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Tarea encontrada",
      body: tarea,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al obtener la tarea",
      error: error.message,
    });
  }
};


export const updateTarea = async (req, res) => {
  try {
    const id = req.params.id;
    const data = req.body;

    const tarea = await tareaModel.findByPk(id);
    if (!tarea) {
      return res.status(404).json({ Message: "Tarea no encontrada" });
    }

    await tarea.update({
      Descripcion: data.Descripcion ?? tarea.Descripcion,
      FechaAsignacion: data.FechaAsignacion ?? tarea.FechaAsignacion,
      FechaLimite: data.FechaLimite ?? tarea.FechaLimite,
      EstadoTarea: data.EstadoTarea ?? tarea.EstadoTarea,
      Prioridad: data.Prioridad ?? tarea.Prioridad,
      Persona_FK: data.Persona_FK ? parseInt(data.Persona_FK) : tarea.Persona_FK,
      Producto_FK: data.Producto_FK ? parseInt(data.Producto_FK) : tarea.Producto_FK,
    });

    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Tarea actualizada correctamente",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al actualizar la tarea",
      error: error.message,
    });
  }
};


export const deleteTarea = async (req, res) => {
  try {
    const id = req.params.id;

    const deleted = await tareaModel.destroy({ where: { idTarea: id } });

    if (!deleted) {
      return res.status(404).json({ Message: "Tarea no encontrada" });
    }

    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Tarea eliminada correctamente",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al eliminar la tarea",
      error: error.message,
    });
  }
};

// COMPLETAR TAREA
// Actualiza: Stock, Movimiento, Produccion y Estado de Tarea
export const completarTarea = async (req, res) => {
  const { id } = req.params;
  
  try {
    // 1️⃣ Buscar la tarea con el producto
    const tarea = await tareaModel.findOne({
      where: { idTarea: id },
      include: [
        {
          model: Producto,
        }
      ]
    });

    if (!tarea) {
      return res.status(404).json({
        ok: false,
        message: 'Tarea no encontrada'
      });
    }

    // Validar que no esté ya completada
    if (tarea.EstadoTarea === 'Completada') {
      return res.status(400).json({
        ok: false,
        message: 'Esta tarea ya fue completada anteriormente'
      });
    }

    if (!tarea.Producto_FK) {
      return res.status(400).json({
        ok: false,
        message: 'Esta tarea no tiene un producto asociado'
      });
    }

    // 2️⃣ Extraer la cantidad de la descripción
    // Ejemplo: "Hacer 24 pijamas estilo..." → extraer 24
    const match = tarea.Descripcion.match(/Hacer (\d+) pijamas/i);
    
    if (!match || !match[1]) {
      return res.status(400).json({
        ok: false,
        message: 'No se pudo determinar la cantidad producida desde la descripción. Asegúrate de que siga el formato: "Hacer [cantidad] pijamas..."'
      });
    }

    const cantidadProducida = parseInt(match[1]);
    const fechaCompletado = new Date();

    // 3️⃣ Buscar el producto
    const producto = await Producto.findByPk(tarea.Producto_FK);
    if (!producto) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado'
      });
    }

    // 4️⃣ CREAR REGISTRO DE PRODUCCIÓN
    const nuevaProduccion = await Produccion.create({
      FechaProduccion: fechaCompletado,
      CantidadProducida: cantidadProducida,
      Persona_FK: tarea.Persona_FK, // Empleado que completó la tarea
      Tarea_FK: tarea.idTarea // ✅ CAMBIO: Ahora es Tarea_FK, no Producto_FK
    });
    console.log(`✅ Producción registrada: ID ${nuevaProduccion.idProduccion}`);

    // 5️⃣ ACTUALIZAR STOCK DEL PRODUCTO
    const stockAnterior = producto.Stock;
    const nuevoStock = stockAnterior + cantidadProducida;
    
    await producto.update({
      Stock: nuevoStock
    });
    console.log(`✅ Stock actualizado: ${producto.NombreProducto} | Anterior: ${stockAnterior} → Nuevo: ${nuevoStock}`);

    // 6️⃣ CREAR MOVIMIENTO DE ENTRADA
    await Movimiento.create({
      Tipo: 'Entrada',
      Cantidad: cantidadProducida,
      Fecha: fechaCompletado,
      Motivo: `Producción completada - Tarea #${id} (${producto.NombreProducto})`,
      Persona_FK: tarea.Persona_FK,
      Producto_FK: tarea.Producto_FK,
      Produccion_FK: nuevaProduccion.idProduccion // ✅ Vinculado a la producción creada
    });
    console.log(`✅ Movimiento de entrada creado: +${cantidadProducida} unidades`);

    // ACTUALIZAR ESTADO DE LA TAREA A COMPLETADA
    await tarea.update({
      EstadoTarea: 'Completada'
    });
    console.log(`✅ Tarea #${id} marcada como Completada`);

    // 8️⃣ RESPUESTA EXITOSA
    res.status(200).json({
      ok: true,
      message: 'Tarea completada exitosamente',
      data: {
        tareaId: tarea.idTarea,
        produccionId: nuevaProduccion.idProduccion,
        producto: {
          id: producto.idProducto,
          nombre: producto.NombreProducto,
          color: producto.Color,
          talla: producto.Talla,
          estampado: producto.Estampado
        },
        cantidadProducida: cantidadProducida,
        stock: {
          anterior: stockAnterior,
          nuevo: nuevoStock,
          incremento: cantidadProducida
        },
        fechaCompletado: fechaCompletado,
        empleado: tarea.Persona_FK
      }
    });

  } catch (error) {
    console.error('❌ Error al completar tarea:', error);
    res.status(500).json({
      ok: false,
      message: 'Error al completar la tarea',
      error: error.message
    });
  }
};

// ESTADÍSTICAS
export const getEstadisticas = async (req, res) => {
  try {
    const query = `
      SELECT 
        EstadoTarea,
        COUNT(*) AS Cantidad,
        ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*)FROM "Tareas")), 2) AS Porcentaje
     FROM "Tareas"
      GROUP BY EstadoTarea
    `;

    const [results] = await sequelize.query(query);

    return res.status(200).json({
      success: true,
      data: results,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      Message: "Error al obtener estadísticas",
      error: error.message,
    });
  }
};


// TOP EMPLEADOS
export const getTopEmpleados = async (req, res) => {
  try {
    const query = `
      SELECT 
        p.idPersona,
        CONCAT(p.Primer_Nombre, ' ', p.Primer_Apellido) AS NombreEmpleado,
        r.NombreRol,
        COUNT(CASE WHEN t.EstadoTarea = 'Completada' THEN 1 END) AS TareasCompletadas,
        COUNT(CASE WHEN t.EstadoTarea = 'Pendiente' THEN 1 END) AS TareasPendientes,
        COUNT(CASE WHEN t.EstadoTarea = 'En Progreso' THEN 1 END) AS TareasEnProgreso,
        COUNT(t.idTarea) AS TotalTareas
      FROM "Personas" p
      INNER JOIN "Roles" r ON p.Rol_FK = r.idRol
      LEFT JOIN "Tareas" t ON p.idPersona = t.Persona_FK
      WHERE r.NombreRol IN ('Empleado','Administrador')
      GROUP BY p.idPersona
      HAVING COUNT(t.idTarea) > 0
      ORDER BY TareasCompletadas DESC
      LIMIT 5;
    `;

    const [results] = await sequelize.query(query);

    return res.status(200).json({
      success: true,
      data: results,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      Message: "Error al obtener TOP empleados",
      error: error.message,
    });
  }
};


// LISTADO DE EMPLEADOS CON SUS TAREAS
export const getEmpleadosTareas = async (req, res) => {
  try {
    const query = `
      SELECT 
        p.idPersona AS ID,
        CONCAT(p.Primer_Nombre, ' ', p.Primer_Apellido) AS Empleado,
        r.NombreRol AS Rol,
        COUNT(CASE WHEN t.EstadoTarea = 'Completada' THEN 1 END) AS TareasHechas,
        COUNT(CASE WHEN t.EstadoTarea IN ('Pendiente','En Progreso') THEN 1 END) AS Pendientes,
        COUNT(t.idTarea) AS TotalTareas
      FROM "Personas" p
      INNER JOIN "Roles" r ON p.Rol_FK = r.idRol
      LEFT JOIN "Tareas" t ON p.idPersona = t.Persona_FK
      WHERE r.NombreRol = 'Empleado'
      GROUP BY p.idPersona
    `;

    const [results] = await sequelize.query(query);

    return res.status(200).json({
      success: true,
      data: results,
    });
} catch (error) {
    console.error('ERROR EMPLEADOS TAREAS:', error.message, error.stack);
    return res.status(500).json({
      success: false,
      Message: "Error al obtener lista de empleados",
      error: error.message,
    });
  }
};


// TAREAS POR EMPLEADO
export const getTareasByEmpleado = async (req, res) => {
  try {
    const { id } = req.params;

    const tareas = await tareaModel.findAll({
      where: { Persona_FK: parseInt(id) },
    });

    return res.status(200).json({
      ok: true,
      status: 200,
      body: tareas,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al obtener tareas del empleado",
      error: error.message,
    });
  }
};


//CAMBIAR ESTADO DE UNA TAREA
export const updateEstadoTarea = async (req, res) => {
  try {
    const { id } = req.params;
    const { EstadoTarea } = req.body;

    const estadosValidos = ["Pendiente", "En Progreso", "Completada"];

    if (!estadosValidos.includes(EstadoTarea)) {
      return res.status(400).json({
        Message: "Estado de tarea no válido",
        estadosPermitidos: estadosValidos,
      });
    }

    const [updated] = await tareaModel.update(
      { EstadoTarea },
      { where: { idTarea: id } }
    );

    if (!updated) {
      return res.status(404).json({ Message: "Tarea no encontrada" });
    }

    return res.status(200).json({
      ok: true,
      Message: "Estado actualizado correctamente",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al actualizar estado",
      error: error.message,
    });
  }
};
