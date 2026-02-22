import movimientoModel from "../models/Movimiento.model.js";

const rolesAdmin = ["SuperAdmin", "Administrador"];

export const createMovimiento = async (req, res) => {
  try {
    await movimientoModel.sync();
    const dataMovimiento = req.body;

    // Cliente solo puede crear movimientos tipo "Salida" (compras)
    if (req.user.rol === "Cliente" && dataMovimiento.Tipo !== "Salida") {
      return res.status(403).json({
        ok: false,
        Message: "Los clientes solo pueden realizar compras (Salida)",
      });
    }

    // Empleado no puede crear movimientos manualmente
    if (req.user.rol === "Empleado") {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para registrar movimientos",
      });
    }

    const personaId =
      req.user.rol === "Cliente"
        ? req.user.id
        : parseInt(dataMovimiento.Persona_FK);

    const createMovimiento = await movimientoModel.create({
      Tipo: dataMovimiento.Tipo,
      Cantidad: dataMovimiento.Cantidad,
      Fecha: dataMovimiento.Fecha,
      Motivo: dataMovimiento.Motivo,
      Persona_FK: personaId,
      Producto_FK: dataMovimiento.Producto_FK,
    });

    res.status(201).json({
      ok: true,
      status: 201,
      Message: "Movimiento Creado",
      id: createMovimiento.idMovimiento,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showMovimiento = async (req, res) => {
  try {
    await movimientoModel.sync();
    let movimientos;

    if (req.user.rol === "Cliente") {
      // Cliente solo ve sus propias compras
      movimientos = await movimientoModel.findAll({
        where: { Persona_FK: req.user.id, Tipo: "Salida" },
      });
    } else if (req.user.rol === "Empleado") {
      // Empleado ve los movimientos de sus producciones (Entradas)
      movimientos = await movimientoModel.findAll({
        where: { Persona_FK: req.user.id, Tipo: "Entrada" },
      });
    } else {
      // SuperAdmin y Administrador ven todos
      movimientos = await movimientoModel.findAll();
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Listado de Movimientos",
      body: movimientos,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showIdMovimiento = async (req, res) => {
  try {
    await movimientoModel.sync();
    const idMovimiento = req.params.id;

    const movimiento = await movimientoModel.findOne({
      where: { idMovimiento },
    });
    if (!movimiento)
      return res
        .status(404)
        .json({ ok: false, Message: "Movimiento no Encontrado" });

    // Cliente solo puede ver sus propias compras
    if (req.user.rol === "Cliente") {
      if (
        movimiento.Persona_FK !== req.user.id ||
        movimiento.Tipo !== "Salida"
      ) {
        return res
          .status(403)
          .json({
            ok: false,
            Message: "No tienes permiso para ver este movimiento",
          });
      }
    }

    // Empleado solo puede ver sus propias producciones
    if (req.user.rol === "Empleado") {
      if (
        movimiento.Persona_FK !== req.user.id ||
        movimiento.Tipo !== "Entrada"
      ) {
        return res
          .status(403)
          .json({
            ok: false,
            Message: "No tienes permiso para ver este movimiento",
          });
      }
    }

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Movimiento por id",
      body: movimiento,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const updateMovimiento = async (req, res) => {
  try {
    await movimientoModel.sync();
    const idMovimiento = req.params.id;

    // Solo SuperAdmin y Administrador pueden actualizar
    if (!rolesAdmin.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para modificar movimientos",
      });
    }

    const movimiento = await movimientoModel.findByPk(idMovimiento);
    if (!movimiento)
      return res
        .status(404)
        .json({ ok: false, Message: "Movimiento no Encontrado" });

    const dataMovimiento = req.body;
    await movimiento.update({
      Tipo: dataMovimiento.Tipo,
      Cantidad: dataMovimiento.Cantidad,
      Fecha: dataMovimiento.Fecha,
      Motivo: dataMovimiento.Motivo,
    });

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Movimiento Actualizado",
      body: movimiento,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const deleteMovimiento = async (req, res) => {
  try {
    await movimientoModel.sync();
    const idMovimiento = req.params.id;

    // Solo SuperAdmin y Administrador pueden eliminar
    if (!rolesAdmin.includes(req.user.rol)) {
      return res.status(403).json({
        ok: false,
        Message: "No tienes permiso para eliminar movimientos",
      });
    }

    const movimiento = await movimientoModel.findByPk(idMovimiento);
    if (!movimiento)
      return res
        .status(404)
        .json({ ok: false, Message: "Movimiento no Encontrado" });

    await movimiento.destroy();

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Movimiento Eliminado",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};
