import produccionModel from "../models/Produccion.model.js";

const rolesPermitidos = ["SuperAdmin", "Administrador", "Empleado"];
const rolesAdmin = ["SuperAdmin", "Administrador"];

export const createProduccion = async (req, res) => {
  try {
    await produccionModel.sync();

    if (!rolesPermitidos.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para registrar producciones",
      });
    }

    const dataProduccion = req.body;

    // Si es empleado, se asigna a él mismo
    const personaId =
      req.user.rol === "Empleado"
        ? req.user.id
        : parseInt(dataProduccion.Persona_FK);

    const createProduccion = await produccionModel.create({
      FechaProduccion: dataProduccion.FechaProduccion,
      CantidadProducida: dataProduccion.CantidadProducida,
      Persona_FK: personaId,
      DetalleTarea_FK: dataProduccion.DetalleTarea_FK,
      Descripcion: dataProduccion.Descripcion ?? null,
    });

    res.status(201).json({
      ok: true,
      status: 201,
      Message: "Produccion Creada",
      id: createProduccion.idProduccion,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showProduccion = async (req, res) => {
  try {
    await produccionModel.sync();

    if (!rolesPermitidos.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para ver producciones",
      });
    }

    let producciones;

    if (req.user.rol === "Empleado") {
      producciones = await produccionModel.findAll({
        where: { Persona_FK: req.user.id },
      });
    } else {
      producciones = await produccionModel.findAll();
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Listado de Producciones",
      body: producciones,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showIdProduccion = async (req, res) => {
  try {
    await produccionModel.sync();

    if (!rolesPermitidos.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para ver producciones",
      });
    }

    const idProduccion = req.params.id;

    const produccion = await produccionModel.findOne({
      where: { idProduccion },
    });
    if (!produccion)
      return res
        .status(404)
        .json({ ok: false, Message: "Produccion no Encontrada" });

    if (req.user.rol === "Empleado" && produccion.Persona_FK !== req.user.id) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para ver esta producción",
      });
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Produccion por id",
      body: produccion,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const updateProduccion = async (req, res) => {
  try {
    await produccionModel.sync();

    if (!rolesAdmin.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para modificar producciones",
      });
    }

    const idProduccion = req.params.id;

    const produccion = await produccionModel.findByPk(idProduccion);
    if (!produccion)
      return res
        .status(404)
        .json({ ok: false, Message: "Produccion no Encontrada" });

    const dataProduccion = req.body;
    await produccion.update({
      FechaProduccion: dataProduccion.FechaProduccion,
      Descripcion: dataProduccion.Descripcion,
    });

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Produccion Actualizada",
      body: produccion,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const deleteProduccion = async (req, res) => {
  try {
    await produccionModel.sync();

    if (!rolesAdmin.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para eliminar producciones",
      });
    }

    const idProduccion = req.params.id;

    const produccion = await produccionModel.findByPk(idProduccion);
    if (!produccion)
      return res
        .status(404)
        .json({ ok: false, Message: "Produccion no Encontrada" });

    await produccion.destroy();

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Produccion Eliminada",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};
