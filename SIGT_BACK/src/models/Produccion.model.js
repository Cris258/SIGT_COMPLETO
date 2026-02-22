import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Produccion extends Model { }
Produccion.init(
    {
        idProduccion: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        FechaProduccion: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        CantidadProducida : {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        Persona_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Personas',
                key: 'idPersona',
            }
        },
        Tarea_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Tareas',
                key: 'idTarea',
            }
        },
    }, {sequelize, modelName: "Produccion", tableName: "Produccion"}
);

export default Produccion;