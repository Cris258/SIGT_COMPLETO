import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class DetalleCarrito extends Model {}
DetalleCarrito.init(
    {
        idDetalleCarrito: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        Cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        Carrito_FK: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Carritos',
                key: 'idCarrito',
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
    }, {sequelize, modelName: "DetalleCarrito", tableName: "DetalleCarritos", freezeTableName: true}
);

export default DetalleCarrito;