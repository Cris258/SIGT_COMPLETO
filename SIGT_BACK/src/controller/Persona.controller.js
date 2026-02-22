import personaModel from "../models/Persona.model.js";
import Rol from "../models/Rol.model.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import nodemailer from "nodemailer";

export const createPersona = async (req, res) => {
  try {
    await personaModel.sync();

    const data = req.body;

    // Verificar si llega un solo objeto o un array
    const isArray = Array.isArray(data);

    const salt = await bcrypt.genSalt(10);

    // Si es array → procesar todos
    if (isArray) {
      const usuariosPreparados = await Promise.all(
        data.map(async (user) => ({
          ...user,
          Password: await bcrypt.hash(user.Password, salt),
          Rol_FK: parseInt(user.Rol_FK),
          EstadoPersona_FK: 1,
        }))
      );

      const resultado = await personaModel.bulkCreate(usuariosPreparados);

      return res.status(201).json({
        ok: true,
        status: 201,
        message: "Usuarios creados correctamente",
        cantidad: resultado.length,
      });
    }

    // Si es solo un objeto → comportamiento original
    const passwordHash = await bcrypt.hash(data.Password, salt);

    const createPersona = await personaModel.create({
      NumeroDocumento: data.NumeroDocumento,
      TipoDocumento: data.TipoDocumento,
      Primer_Nombre: data.Primer_Nombre,
      Segundo_Nombre: data.Segundo_Nombre,
      Primer_Apellido: data.Primer_Apellido,
      Segundo_Apellido: data.Segundo_Apellido,
      Telefono: data.Telefono,
      Correo: data.Correo,
      Password: passwordHash,
      Rol_FK: parseInt(data.Rol_FK),
      EstadoPersona_FK: 1,
    });

    return res.status(201).json({
      ok: true,
      status: 201,
      message: "Usuario creado correctamente",
      id: createPersona.idPersona,
      Persona: createPersona.Primer_Nombre,
    });
  } catch (error) {
    console.error("Error al crear usuario(s): ", error);
    return res.status(500).json({
      ok: false,
      status: 500,
      message: "Error en la solicitud",
      error: error.message,
    });
  }
};

export const showPersona = async (req, res) => {
  try {
    await personaModel.sync();
    const showPersona = await personaModel.findAll({
      include: [
        {
          model: Rol,
          attributes: ["NombreRol"],
        },
      ],
    });

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Usuario",
      body: showPersona,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const showPersonaId = async (req, res) => {
  try {
    const idPersona = req.params.id;
    const persona = await personaModel.findOne({
      where: {
        idPersona: idPersona,
      },
    });
    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Ver Usuario por id :)",
      body: persona,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const updatePersona = async (req, res) => {
  try {
    await personaModel.sync();
    const idPersona = req.params.id;
    const dataPersona = req.body;

    const updatePersona = await personaModel.update(
      {
        NumeroDocumento: dataPersona.NumeroDocumento,
        TipoDocumento: dataPersona.TipoDocumento,
        Primer_Nombre: dataPersona.Primer_Nombre,
        Segundo_Nombre: dataPersona.Segundo_Nombre,
        Primer_Apellido: dataPersona.Primer_Apellido,
        Segundo_Apellido: dataPersona.Segundo_Apellido,
        Telefono: dataPersona.Telefono,
        Correo: dataPersona.Correo,
        Rol_FK: dataPersona.Rol_FK,
        EstadoPersona_FK: dataPersona.EstadoPersona_FK,
      },
      {
        where: {
          idPersona: idPersona,
        },
      }
    );
    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Usuario Actualizado :)",
      body: updatePersona,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salio mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const deletePersona = async (req, res) => {
  try {
    await personaModel.sync();
    const idPersona = req.params.id;
    const personaToDelete = await personaModel.findOne({
      where: { idPersona },
      include: [{ model: Rol, attributes: ["NombreRol"] }],
    });

    if (!personaToDelete) {
      return res.status(404).json({ Message: "Usuario no encontrado" });
    }

    const rolSolicitante = req.user.rol;
    const rolObjetivo = personaToDelete.Rol.NombreRol;

    if (rolSolicitante === "Administrador") {
      if (rolObjetivo === "Administrador" || rolObjetivo === "SuperAdmin") {
        return res.status(403).json({
          Message:
            "Acceso denegado: un Administrador no puede eliminar a otro Administrador ni a un SuperAdmin.",
        });
      }
    }

    if (rolSolicitante === "SuperAdmin") {
      if (personaToDelete.idPersona === req.user.id) {
        return res.status(403).json({
          Message:
            "Acceso denegado: un SuperAdmin no puede eliminarse a sí mismo.",
        });
      }
    }

    await personaModel.destroy({ where: { idPersona } });

    res.status(200).json({
      ok: true,
      status: 200,
      Message: "Usuario eliminado correctamente",
      eliminado: {
        id: personaToDelete.idPersona,
        correo: personaToDelete.Correo,
        rol: rolObjetivo,
      },
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

export const registerPersona = async (req, res) => {
  try {
    await personaModel.sync();

    let personas = req.body;

    // Convertir a array si es un solo objeto
    if (!Array.isArray(personas)) {
      personas = [personas];
    }

    const resultados = [];
    const errores = [];

    for (const persona of personas) {
      const {
        NumeroDocumento,
        TipoDocumento,
        Primer_Nombre,
        Segundo_Nombre,
        Primer_Apellido,
        Segundo_Apellido,
        Telefono,
        Correo,
        Password,
      } = persona;

      // Validación de campos obligatorios
      if (
        !NumeroDocumento ||
        !TipoDocumento ||
        !Primer_Nombre ||
        !Primer_Apellido ||
        !Telefono ||
        !Correo ||
        !Password
      ) {
        errores.push({
          Correo: Correo || null,
          error:
            "Faltan campos obligatorios: Documento, TipoDocumento, Nombre, Apellido, Teléfono, Correo y Contraseña.",
        });
        continue;
      }

      // Verificar si el correo ya está en uso
      const existingUser = await personaModel.findOne({ where: { Correo } });
      if (existingUser) {
        errores.push({
          Correo,
          error: "El correo ya está registrado",
        });
        continue;
      }

      // Encriptar contraseña
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(Password, salt);

      // Crear usuario
      const newPersona = await personaModel.create({
        NumeroDocumento,
        TipoDocumento,
        Primer_Nombre,
        Segundo_Nombre,
        Primer_Apellido,
        Segundo_Apellido,
        Telefono,
        Correo,
        Password: passwordHash,
        Rol_FK: 4, // Cliente
        EstadoPersona_FK: 1,
      });

      resultados.push({
        idPersona: newPersona.idPersona,
        Correo: newPersona.Correo,
        Nombre: `${newPersona.Primer_Nombre} ${newPersona.Primer_Apellido}`,
      });
    }

    return res.status(201).json({
      ok: errores.length === 0,
      Message:
        errores.length === 0
          ? "Registros completados :)"
          : "Algunos registros tuvieron errores",
      registrados: resultados,
      errores: errores,
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      status: 500,
      Message: "Algo salió mal en el registro",
      error: error.message,
    });
  }
};

export const loginPersona = async (req, res) => {
  try {
    const { Correo, Password } = req.body;

    if (!Correo || !Password) {
      return res.status(400).json({
        Message: "Faltan campos obligatorios: Correo y contraseña.",
      });
    }

    const persona = await personaModel.findOne({
      where: { Correo },
      include: [{ model: Rol, attributes: ["NombreRol"] }],
    });

    if (!persona) {
      return res.status(404).json({ Message: "Usuario no encontrado" });
    }

    if (persona.EstadoPersona_FK === 2) {
      return res.status(403).json({
        Message:
          "Cuenta Inactiva, pidale a un Administrador que le cambie el estado",
      });
    }

    const isMatch = await bcrypt.compare(Password, persona.Password);

    if (!isMatch) {
      return res.status(401).json({ Message: "Credenciales no válidas" });
    }

    const token = jwt.sign(
      {
        id: persona.idPersona,
        correo: persona.Correo,
        rol: persona.Rol.NombreRol,
      },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.status(200).json({
      ok: true,
      status: 200,
      Message: `Bienvenido ${persona.Primer_Nombre} :)`,
      id: persona.idPersona,
      rol: persona.Rol.NombreRol,
      token: token,
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal con la solicitud",
      status: 500,
      error: error.message,
    });
  }
};

import { pushToBlacklist } from "../middleware/tokenBlacklist.js";

export const logoutPersona = async (req, res) => {
  try {
    const token = req.headers["authorization"]?.split(" ")[1];
    if (!token) {
      return res.status(400).json({
        ok: false,
        status: 400,
        Message: "Token no Proporcionado",
      });
    }
    pushToBlacklist(token);
    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Sesión cerrada correctamente",
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      status: 500,
      Message: "Error al cerrar sesión",
      error: error.message,
    });
  }
};

export const changePassword = async (req, res) => {
  try {
    const idPersona = req.params.id;
    const { currentPassword, newPassword } = req.body;

    const persona = await personaModel.findByPk(idPersona);
    if (!persona) {
      return res.status(404).json({ Message: "Usuario no encontrado" });
    }

    const isMatch = await bcrypt.compare(currentPassword, persona.Password);
    if (!isMatch) {
      return res
        .status(400)
        .json({ Message: "La contraseña actual no es correcta" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await persona.update({ Password: hashedPassword });

    return res.status(200).json({
      ok: true,
      status: 200,
      Message: "Contraseña actualizada con éxito",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Algo salió mal al cambiar la contraseña",
      error: error.message,
    });
  }
};

//  Solicitud de recuperación (genera token y lo envía al correo)
export const forgotPassword = async (req, res) => {
  try {
    const { Correo } = req.body;

    // 1. Verificar que el correo exista en la BD
    const persona = await personaModel.findOne({ where: { Correo } });
    if (!persona) {
      return res.status(404).json({ Message: "El correo no está registrado" });
    }

    // 2. Generar token temporal
    const token = jwt.sign(
      { idPersona: persona.idPersona, Correo: persona.Correo },
      process.env.JWT_SECRET,
      { expiresIn: "15m" }
    );

    // 3. Configurar transporte de correo (ejemplo con Gmail)
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      tls: {
        rejectUnauthorized: false, // ← AGREGAR ESTO
      },
    });

    // 4. Enviar correo con el enlace
    const resetLink = `http://localhost:3000/reset-password?token=${token}`;
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: persona.Correo,
      subject: "Recuperación de contraseña",
      html: `
        <h3>Hola ${persona.Primer_Nombre},</h3>
        <p>Has solicitado recuperar tu contraseña. Haz clic en el enlace para restablecerla:</p>
        <a href="${resetLink}" target="_blank">Restablecer contraseña</a>
        <p>El enlace expira en 15 minutos.</p>
      `,
    });

    return res.status(200).json({
      ok: true,
      Message: "Correo de recuperación enviado",
      resetLink, // solo para pruebas
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error en la solicitud de recuperación",
      error: error.message,
    });
  }
};

// Restablecer contraseña (usa el token recibido)
export const resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const persona = await personaModel.findOne({
      where: { idPersona: decoded.idPersona },
    });
    if (!persona) {
      return res.status(404).json({ Message: "Usuario no encontrado" });
    }
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);
    persona.Password = passwordHash;
    await persona.save();

    return res.status(200).json({
      ok: true,
      Message: "Contraseña actualizada exitosamente",
    });
  } catch (error) {
    return res.status(500).json({
      Message: "Error al restablecer contraseña",
      error: error.message,
    });
  }
};

import db from "../config/connect.db.js";

// Obtener clientes con sus compras
export const obtenerClientesConCompras = async (req, res) => {
  try {
    const query = `
      SELECT 
        p.idPersona AS ID,
        p.Primer_Nombre AS Nombre,
        p.Primer_Apellido AS Apellido,
        p.Correo AS Email,
        p.Telefono,
        ep.NombreEstado AS Estado,
        COUNT(DISTINCT v.idVenta) AS TotalCompras,
        COALESCE(SUM(dv.Cantidad * dv.PrecioUnitario), 0) AS TotalGastado
      FROM personas p
      INNER JOIN roles r ON p.Rol_FK = r.idRol
      INNER JOIN estadopersonas ep ON p.EstadoPersona_FK = ep.idEstadoPersona
      LEFT JOIN venta v ON p.idPersona = v.Persona_FK
      LEFT JOIN detalleventa dv ON v.idVenta = dv.Venta_FK
      WHERE r.NombreRol = 'Cliente'
      GROUP BY p.idPersona
      ORDER BY TotalCompras DESC
    `;

    const [clientes] = await db.query(query);

    res.json({
      success: true,
      data: clientes,
    });
  } catch (error) {
    console.error("Error al obtener clientes:", error);
    res.status(500).json({
      success: false,
      message: "Error al obtener clientes",
      error: error.message,
    });
  }
};

// Obtener top 5 mejores clientes
export const obtenerTopClientes = async (req, res) => {
  try {
    const query = `
      SELECT 
        p.idPersona AS ID,
        p.Primer_Nombre AS Nombre,
        p.Primer_Apellido AS Apellido,
        p.Correo AS Email,
        COUNT(DISTINCT v.idVenta) AS TotalCompras,
        COALESCE(SUM(dv.Cantidad * dv.PrecioUnitario), 0) AS TotalGastado
      FROM personas p
      INNER JOIN roles r ON p.Rol_FK = r.idRol
      LEFT JOIN venta v ON p.idPersona = v.Persona_FK
      LEFT JOIN detalleventa dv ON v.idVenta = dv.Venta_FK
      WHERE r.NombreRol = 'Cliente'
      GROUP BY p.idPersona
      ORDER BY TotalGastado DESC
      LIMIT 5
    `;

    const [topClientes] = await db.query(query);

    res.json({
      success: true,
      data: topClientes,
    });
  } catch (error) {
    console.error("Error al obtener top clientes:", error);
    res.status(500).json({
      success: false,
      message: "Error al obtener top clientes",
      error: error.message,
    });
  }
};

// Obtener estadísticas de clientes
export const obtenerEstadisticasClientes = async (req, res) => {
  try {
    const query = `
      SELECT 
        ep.NombreEstado AS Estado,
        COUNT(*) AS Cantidad
      FROM personas p
      INNER JOIN roles r ON p.Rol_FK = r.idRol
      INNER JOIN estadopersonas ep ON p.EstadoPersona_FK = ep.idEstadoPersona
      WHERE r.NombreRol = 'Cliente'
      GROUP BY ep.NombreEstado
    `;

    const [porEstado] = await db.query(query);

    res.json({
      success: true,
      data: {
        porEstado,
      },
    });
  } catch (error) {
    console.error("Error al obtener estadísticas:", error);
    res.status(500).json({
      success: false,
      message: "Error al obtener estadísticas",
      error: error.message,
    });
  }
};

const PersonaController = {
  createPersona,
  showPersona,
  showPersonaId,
  updatePersona,
  deletePersona,
  registerPersona,
  loginPersona,
  logoutPersona,
  changePassword,
  forgotPassword,
  resetPassword,
  obtenerClientesConCompras,
  obtenerTopClientes,
  obtenerEstadisticasClientes,
};

export default PersonaController;
