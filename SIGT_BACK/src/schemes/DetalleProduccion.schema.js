import Joi from "@hapi/joi";

export default {
    createDetalleProduccion: Joi.object({
        Cantidad: Joi.number().integer().required(),
        Producto_FK: Joi.number().integer().required(),
        Produccion_FK: Joi.number().integer().required(),
    }),

    updateDetalleProduccion: Joi.object({
        Cantidad: Joi.number().integer(),
        Producto_FK: Joi.number().integer(),
        Produccion_FK: Joi.number().integer(),
    }),
};