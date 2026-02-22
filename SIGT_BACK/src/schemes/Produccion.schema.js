import Joi from "@hapi/joi";

export default {
    createProduccion: Joi.object({
        FechaProduccion: Joi.date().required(),
        CantidadProducida: Joi.number().integer().required(),
        Persona_FK: Joi.number().integer().required(),
        DetalleTarea_FK: Joi.number().integer().required(),
    }),

    updateProduccion: Joi.object({
        FechaProduccion: Joi.date(),
        CantidadProducida: Joi.number().integer(),
        Persona_FK: Joi.number().integer(),
        DetalleTarea_FK: Joi.number().integer(),
    }),
};