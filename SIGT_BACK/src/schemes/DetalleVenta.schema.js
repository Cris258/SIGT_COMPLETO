import Joi from "@hapi/joi";

export default {
    createDetalleVenta: Joi.object({
        Cantidad: Joi.number().integer().required(),
        PrecioUnitario: Joi.number().required(),
        Producto_FK: Joi.number().integer().required(),
        Venta_FK: Joi.number().integer().required(),
    }),

    updateDetalleVenta: Joi.object({
        Cantidad: Joi.number().integer(),
        PrecioUnitario: Joi.number(),
        Producto_FK: Joi.number().integer(),
        Venta_FK: Joi.number().integer(),
    }),
};