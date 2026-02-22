import Joi from "@hapi/joi";

export default {
    createEstadoPersona: Joi.object({
        NombreEstado: Joi.string().required(),
        DescriptionEstado: Joi.string().allow(null, ''),
    }),

    updateEstadoPersona: Joi.object({
        NombreEstado: Joi.string(),
        DescriptionEstado: Joi.string().allow(null, ''),
    }),
};