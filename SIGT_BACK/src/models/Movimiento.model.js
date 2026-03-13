import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Movimiento extends Model { }
Movimiento.init(
    {
        idMovimiento: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        Tipo: {
            type: DataTypes.ENUM("Entrada", "Salida", "Ajuste", "Devolucion"),
            allowNull: false,
        },
        Cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        Fecha: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        Motivo: {
            type: DataTypes.STRING,
            allowNull: true,
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
        },
        Produccion_FK: {
            type: DataTypes.INTEGER,
            allowNull: true,
            references: {
                model: 'Produccion',
                key: 'idProduccion',
            }
        }
    }, {sequelize, modelName: "Movimiento", tableName: "Movimientos", freezeTableName: true}
);

export default Movimiento;