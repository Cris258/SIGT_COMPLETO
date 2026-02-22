import Joi from "@hapi/joi";

export default {
    createMovimiento: Joi.object({
        Tipo: Joi.string().valid("Entrada", "Salida", "Ajuste", "Devolucion").required(),
        Cantidad: Joi.number().integer().required(),
        Fecha: Joi.date().required(),
        Motivo: Joi.string().allow(null, ''),
        Persona_FK: Joi.number().integer().required(),
        Producto_FK: Joi.number().integer().required(),
    }),

    updateMovimiento: Joi.object({
        Tipo: Joi.string().valid("Entrada", "Salida", "Ajuste", "Devolucion"),
        Cantidad: Joi.number().integer(),
        Fecha: Joi.date(),
        Motivo: Joi.string().allow(null, ''),
        Persona_FK: Joi.number().integer(),
        Producto_FK: Joi.number().integer(),
    }),
};