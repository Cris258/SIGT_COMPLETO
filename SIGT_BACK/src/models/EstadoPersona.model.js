import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class EstadoPersona extends Model { }
EstadoPersona.init({
    idEstadoPersona: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
    },
    NombreEstado: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    DescriptionEstado: {
        type: DataTypes.STRING,
        allowNull: true,
    },
}, { sequelize, modelName: "EstadoPersona", tableName: "EstadoPersonas", freezeTableName: true });

export default EstadoPersona;