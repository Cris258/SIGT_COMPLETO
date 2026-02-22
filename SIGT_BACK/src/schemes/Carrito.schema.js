import Joi from "@hapi/joi"

export default {
    createCarrito: Joi.object({
        FechaCreacion: Joi.date().required(),
        Estado: Joi.string().required(),
        Persona_FK: Joi.number().integer().required(),
    }),

    updateCarrito: Joi.object({
        FechaCreacion: Joi.date(),
        Estado: Joi.string(),
        Persona_FK: Joi.number().integer(),
    }),
}