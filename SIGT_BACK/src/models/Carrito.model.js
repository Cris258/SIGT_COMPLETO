import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Carrito extends Model { }
Carrito.init(
    {
        idCarrito: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        FechaCreacion: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        Estado: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Persona_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Personas',
                key: 'idPersona',
            }
        }
    }, { sequelize, modelName: "Carrito", tableName: "Carritos", freezeTableName: true }
);

export default Carrito;