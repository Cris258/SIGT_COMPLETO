import EstadoPersonaModel from '../models/EstadoPersona.model.js';

export const createEstadoPersona = async (req, res) => {
    try {
        await EstadoPersonaModel.sync();
        const dataEstadoPersona = req.body;
        const createEstadoPersona = await EstadoPersonaModel.create({
            NombreEstado: dataEstadoPersona.NombreEstado,
            DescriptionEstado: dataEstadoPersona.DescriptionEstado,
        });
        res.status(201).json({
            ok: true,
            status: 201,
            Message: 'Estado del Usuario Creado',
            id: createEstadoPersona.idEstadoPersona,
        });
    } catch (error) {
        return res.status(500).json({
            Message: 'Algo salio mal con la solicitud',
            status: 500,
             error: error.message
        });
    }
};

export const showEstadoPersona = async (req, res) => {
    try {
        const estados = await EstadoPersonaModel.findAll();
        res.status(200).json({
            ok: true,
            status: 200,
            Message: 'Ver Estados',
            body: estados,
        });
    } catch (error) {
        return res.status(500).json({
            Message: 'Algo salio mal con la solicitud',
            status: 500,
             error: error.message
        });
    }
};

export const showEstadoPersonaId = async (req, res) => {
    try {
        const idEstados = req.params.id;
        const estados = await EstadoPersonaModel.findByPk(idEstados);
        if (estados) {
            res.status(200).json({
                ok: true,
                status: 200,
                Message: 'Mirar Estado por Id',
                body: estados,
            });
        } else {
            res.status(404).json({
                ok: false,
                status: 404,
                Message: 'Estado no Encontrado',
            });
        }
    } catch (error) {
        return res.status(500).json({
            Message: 'Algo salio mal con la solicitud',
            status: 500,
             error: error.message
        });
    }
};

export const updateEstadoPersona = async (req, res) => {
    try {
        await EstadoPersonaModel.sync();
        const idEstados = req.params.id;
        const dataEstadoPersona = req.body;
        const updateEstado = await EstadoPersonaModel.update({
            NombreEstado: dataEstadoPersona.NombreEstado,
            DescriptionEstado: dataEstadoPersona.DescriptionEstado,
        }, {
            where: {
                idEstadoPersona: idEstados
            }
        });
        res.status(200).json({
            ok: true,
            status: 200,
            Message: 'Estado Actualizado',
            body: updateEstado,
        });
    } catch (error) {
        return res.status(500).json({
            Message: 'Algo salio mal con la solicitud',
            status: 500,
             error: error.message
        });
    }
};

export const deleteEstadoPersona = async (req, res) => {
    try {
        await EstadoPersonaModel.sync();
        const idEstados = req.params.id;
        const deleteEstado = await EstadoPersonaModel.destroy({
            where: {
                idEstadoPersona: idEstados
            }
        });
        res.status(200).json({
            ok: true,
            status: 200,
            Message: 'Estado Eliminado',
            body: deleteEstado,
        });
    }
    catch (error) {
        return res.status(500).json({
            Message: 'Algo salio mal con la solicitud',
            status: 500,
             error: error.message
        });
    }
};