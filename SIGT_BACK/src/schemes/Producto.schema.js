import Joi from "@hapi/joi";

export default {
    createProducto: Joi.object({
        NombreProducto: Joi.string().required(),
        Color: Joi.string().required(),
        Talla: Joi.string().valid("XS", "S", "M", "L", "XL", "2", "4", "6", "8", "10", "12", "14", "16").required(),
        Estampado: Joi.string().allow(null, ""),
        Stock: Joi.number().integer().min(0).required(),
        Precio: Joi.number().min(0).required(),
    }).unknown(true),

    updateProducto: Joi.object({
        NombreProducto: Joi.string(),
        Color: Joi.string(),
        Talla: Joi.string().valid("XS", "S", "M", "L", "XL", "2", "4", "6", "8", "10", "12", "14", "16"),
        Estampado: Joi.string().allow(null, ""),
        Stock: Joi.number().integer().min(0),
        Precio: Joi.number().min(0),
    }).min(1).unknown(true),
};