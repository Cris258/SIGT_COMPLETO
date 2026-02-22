import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Tarea extends Model { }
Tarea.init(
    {
        idTarea: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        Descripcion: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        FechaAsignacion: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        FechaLimite: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        EstadoTarea: {
            type: DataTypes.ENUM('Pendiente','En Progreso','Completada','Cancelada'),
            allowNull: false,
        },
        Prioridad: {
            type: DataTypes.ENUM('Baja','Media','Alta','Urgente'),
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
        Producto_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Productos',
                key: 'idProducto',
            }
        }
    }, {sequelize, modelName: "Tarea"}
);

export default Tarea;