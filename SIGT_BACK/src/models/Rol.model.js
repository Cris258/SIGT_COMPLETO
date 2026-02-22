import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Rol extends Model {}
Rol.init(
    {
        idRol: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        NombreRol: {
            type: DataTypes.ENUM("SuperAdmin", "Administrador", "Empleado", "Cliente"),
            allowNull: false,
            unique: false,
        },
        DescripcionRol: {
            type: DataTypes.STRING,
            allowNull: true,
        },
    }, { sequelize, modelName: "Rol", tableName: "Roles" }
);

export default Rol;