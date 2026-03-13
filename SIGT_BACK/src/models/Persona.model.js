import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Persona extends Model {}
Persona.init(
    {
        idPersona: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        NumeroDocumento: {
            type: DataTypes.INTEGER,
            allowNull: false,
            unique: true,
        },
        TipoDocumento: {
            type: DataTypes.ENUM("CC", "TI", "CE", "Pasaporte"),
            allowNull: false,
        },
        Primer_Nombre: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Segundo_Nombre: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        Primer_Apellido: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Segundo_Apellido: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        Telefono: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        Correo: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        Password: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Rol_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Roles',
                key: 'idRol',
            }
        },
        EstadoPersona_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'EstadoPersonas',
                key: 'idEstadoPersona',
            }
        }
    }, {sequelize, modelName: "Persona", tableName: "Personas", freezeTableName: true}
);

export default Persona;