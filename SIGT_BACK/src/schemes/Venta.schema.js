import Joi from "@hapi/joi";

export default {
    createVenta: Joi.object({
        Fecha: Joi.date().required(),
        Total: Joi.number().precision(2).required(),
        DireccionEntrega: Joi.string().required(),
        Ciudad: Joi.string().required(),
        Departamento: Joi.string().required(),
        Persona_FK: Joi.number().integer().required(),
    }),

    updateVenta: Joi.object({
        Fecha: Joi.date(),
        Total: Joi.number().precision(2),
        DireccionEntrega: Joi.string(),
        Ciudad: Joi.string(),
        Departamento: Joi.string(),
        Persona_FK: Joi.number().integer(),
    }),
};