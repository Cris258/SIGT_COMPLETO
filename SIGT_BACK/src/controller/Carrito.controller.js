import carritoModel from "../models/Carrito.model.js";

export const createCarrito = async (req, res) => {
    try {
        await carritoModel.sync();
        const dataCarrito = req.body;
        const personaId = req.user.rol === "Cliente" ? req.user.id : parseInt(dataCarrito.Persona_FK);
        const createCarrito = await carritoModel.create({
            FechaCreacion: dataCarrito.FechaCreacion,
            Estado: dataCarrito.Estado,
            Persona_FK: personaId,
        });
        res.status(201).json(
            {
                ok: true,
                status: 201,
                Message: "Carrito Creado",
                id: createCarrito.idCarrito,
            }
        );
    } catch (error) {
        return res.status(500).json(
            {
                Message: "Algo salio mal con la solicitud",
                status: 500,
                error: error.message
            }
        );
    }
};

export const showCarrito = async (req, res) => {
    try {
        await carritoModel.sync();
        let carritos;

        if (req.user.rol === "Cliente") {
            carritos = await carritoModel.findAll({ where: { Persona_FK: req.user.id } });
        } else {
            carritos = await carritoModel.findAll();
        }

        res.status(200).json({
            ok: true,
            status: 200,
            Message: "Listado de Carritos",
            body: carritos,
        });
    } catch (error) {
        return res.status(500).json({
            Message: "Algo salió mal con la solicitud",
            status: 500,
            error: error.message,
        });
    }
};

export const showIdCarrito = async (req, res) => {
    try {
        await carritoModel.sync();
        const idCarrito = req.params.id;

        const carrito = await carritoModel.findOne({ where: { idCarrito } });
        if (!carrito) return res.status(404).json({ ok: false, Message: "Carrito no Encontrado" });

        if (req.user.rol === "Cliente" && carrito.Persona_FK !== req.user.id) {
            return res.status(403).json({ ok: false, Message: "No tienes permiso para ver este carrito" });
        }

        res.status(200).json({
            ok: true,
            status: 200,
            Message: "Ver Carrito por id",
            body: carrito,
        });
    } catch (error) {
        return res.status(500).json({
            Message: "Algo salió mal con la solicitud",
            status: 500,
            error: error.message,
        });
    }
};

export const updateCarrito = async (req, res) => {
    try {
        await carritoModel.sync();
        const idCarrito = req.params.id;

        const carrito = await carritoModel.findByPk(idCarrito);
        if (!carrito) return res.status(404).json({ ok: false, Message: "Carrito no Encontrado" });

        if (req.user.rol === "Cliente" && carrito.Persona_FK !== req.user.id) {
            return res.status(403).json({ ok: false, Message: "No tienes permiso para modificar este carrito" });
        }

        const dataCarrito = req.body;
        await carrito.update({
            FechaCreacion: dataCarrito.FechaCreacion,
            Estado: dataCarrito.Estado,
        });

        res.status(200).json({
            ok: true,
            status: 200,
            Message: "Carrito Actualizado",
            body: carrito,
        });
    } catch (error) {
        return res.status(500).json({
            Message: "Algo salió mal con la solicitud",
            status: 500,
            error: error.message,
        });
    }
};

export const deleteCarrito = async (req, res) => {
    try {
        await carritoModel.sync();
        const idCarrito = req.params.id;

        const carrito = await carritoModel.findByPk(idCarrito);
        if (!carrito) return res.status(404).json({ ok: false, Message: "Carrito no Encontrado" });

        if (req.user.rol === "Cliente" && carrito.Persona_FK !== req.user.id) {
            return res.status(403).json({ ok: false, Message: "No tienes permiso para eliminar este carrito" });
        }

        await carrito.destroy();

        res.status(200).json({
            ok: true,
            status: 200,
            Message: "Carrito Eliminado",
        });
    } catch (error) {
        return res.status(500).json({
            Message: "Algo salió mal con la solicitud",
            status: 500,
            error: error.message,
        });
    }
};