import rolModel from "../models/Rol.model.js";

export const createRol = async (req, res) => {
    try {
        await rolModel.sync();
        const dataRol = req.body;
        const createRol = await rolModel.create(
            {
                NombreRol: dataRol.NombreRol,
                DescripcionRol: dataRol.DescripcionRol,
            }
        );
        res.status(201).json(
            {
                ok: true,
                status: 201,
                Message: "Rol Creado",
                id: createRol.idRol,
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

export const showRol = async (req, res) => {
    try {
        await rolModel.sync();
        const showRol = await rolModel.findAll();
        res.status(200).json(
            {
                ok: true,
                status: 200,
                Message: "Ver Rol",
                body: showRol
            }
        )
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

export const showIdRol = async (req, res) => {
    try {
        await rolModel.sync();
        const idRol = req.params.id;
        const showIdRol = await rolModel.findOne(
            {
                where: {
                    idRol: idRol
                }
            }
        );
        res.status(200).json(
            {
                ok: true,
                status: 200,
                Message: "Ver Rol por id",
                body: showIdRol,
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

export const updateRol = async (req, res) => {
    try {
        await rolModel.sync();
        const dataRol = req.body;
        const idRol = req.params.id;
        const updateRol = await rolModel.update(
            {
                NombreRol: dataRol.NombreRol,
                DescripcionRol: dataRol.DescripcionRol,
            },
            {
                where: {
                    idRol: idRol
                }
            }
        );
        res.status(200).json(
            {
                ok: true,
                status: 200,
                Message: "Rol Actualizado",
                body: updateRol,
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

export const deleteRol = async (req, res) => {
    try {
        await rolModel.sync();
        const idRol = req.params.id;
        const deleteRol = await rolModel.destroy(
            {
                where: {
                    idRol: idRol
                }
            }
        );
        res.status(200).json(
            {
                ok: true,
                status: 200,
                Message: "Rol Eliminado",
                body: deleteRol,
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