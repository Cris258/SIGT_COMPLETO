import Joi from "@hapi/joi";

export default {
    createTarea: Joi.object({
        Descripcion: Joi.string().required(),
        FechaAsignacion: Joi.date().iso().required(),
        FechaLimite: Joi.date().iso().greater(Joi.ref("FechaAsignacion")).required(),
        EstadoTarea: Joi.string().valid("Pendiente", "En Progreso", "Completada", "Cancelada").required(),
        Prioridad: Joi.string().valid("Baja", "Media", "Alta", "Urgente").required(),
        Persona_FK: Joi.number().integer().required(),
        Producto_FK: Joi.number().integer().required(),
    }),

    updateTarea: Joi.object({
        Descripcion: Joi.string().min(3),
        FechaAsignacion: Joi.date().iso(),
        FechaLimite: Joi.date().iso().greater(Joi.ref("FechaAsignacion")),
        EstadoTarea: Joi.string().valid("Pendiente", "En Progreso", "Completada", "Cancelada"),
        Prioridad: Joi.string().valid("Baja", "Media", "Alta", "Urgente"),
        Persona_FK: Joi.number().integer(),
        Producto_FK: Joi.number().integer(),
    }),
};