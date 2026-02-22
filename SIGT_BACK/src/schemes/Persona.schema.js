import Joi from "@hapi/joi";

// 🔹 Schema base para Persona (Empleado / Admin / Cliente con Rol explícito)
const personaObject = Joi.object({
    NumeroDocumento: Joi.number().required(),
    TipoDocumento: Joi.string().valid("CC", "TI", "CE", "Pasaporte").required(),
    Primer_Nombre: Joi.string().required(),
    Segundo_Nombre: Joi.string().allow(null, "").optional(),
    Primer_Apellido: Joi.string().required(),
    Segundo_Apellido: Joi.string().allow(null, "").optional(),
    Telefono: Joi.number().required(),
    Correo: Joi.string().email().required(),
    Password: Joi.string().min(5).required(),
    Rol_FK: Joi.number().required(), // Admin, Empleado, Cliente (solo en createPersona)
});


// 🔹 Schema base exclusivamente para Clientes (Register)
const clienteObject = Joi.object({
    NumeroDocumento: Joi.number().required(),
    TipoDocumento: Joi.string().valid("CC", "TI", "CE", "Pasaporte").required(),
    Primer_Nombre: Joi.string().required(),
    Segundo_Nombre: Joi.string().allow(null, "").optional(),
    Primer_Apellido: Joi.string().required(),
    Segundo_Apellido: Joi.string().allow(null, "").optional(),
    Telefono: Joi.number().required(),
    Correo: Joi.string().email().required(),
    Password: Joi.string().min(5).required(),
});


export default {

    // 🔥 ACEPTA OBJETO O ARRAY PARA PERSONAS (Admin / Empleado / Cliente con Rol_FK)
    createPersona: Joi.alternatives().try(
        personaObject,
        Joi.array().items(personaObject)
    ),

    // 🔄 Update normal
    updatePersona: Joi.object({
        NumeroDocumento: Joi.number(),
        TipoDocumento: Joi.string().valid("CC", "TI", "CE", "Pasaporte"),
        Primer_Nombre: Joi.string(),
        Segundo_Nombre: Joi.string().allow(null, ""),
        Primer_Apellido: Joi.string(),
        Segundo_Apellido: Joi.string().allow(null, ""),
        Telefono: Joi.number(),
        Correo: Joi.string().email(),
        Rol_FK: Joi.number(),
        EstadoPersona_FK: Joi.number(),
    }),

    // 🟢 ACEPTA OBJETO O ARRAY EXCLUSIVO PARA CLIENTES (Register)
    createCliente: Joi.alternatives().try(
        clienteObject,
        Joi.array().items(clienteObject)
    ),
};
