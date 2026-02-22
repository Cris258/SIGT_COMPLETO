import Joi from "@hapi/joi";

export default {
    createDetalleCarrito: Joi.object({
        Cantidad: Joi.number().integer().required(),
        Carrito_FK: Joi.number().integer().required(),
        Producto_FK: Joi.number().integer().required(),
    }),

    updateDetalleCarrito: Joi.object({
        Cantidad: Joi.number().integer(),
        Carrito_FK: Joi.number().integer(),
        Producto_FK: Joi.number().integer(),
    }),
};