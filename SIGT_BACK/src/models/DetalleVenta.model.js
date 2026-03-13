import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class DetalleVenta extends Model { }
DetalleVenta.init(
    {
        idDetalleVenta: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        Cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        PrecioUnitario: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false,
        },
        Producto_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: "Productos",
                key: "idProducto",
            },
        },
        Venta_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: "Venta",
                key: "idVenta",
            }
        },
    }, { sequelize, modelName: "DetalleVenta", tableName: "DetalleVenta", freezeTableName: true }
);

export default DetalleVenta;