import Joi from "@hapi/joi";

export default {
    createRol: Joi.object({
        NombreRol: Joi.string().required(),
        DescripcionRol: Joi.string().allow(null, ''),
    }),

    updateRol: Joi.object({
        NombreRol: Joi.string(),
        DescripcionRol: Joi.string().allow(null, ''),
    }),
};