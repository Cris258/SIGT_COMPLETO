import sequelize from "../config/connect.db.js";
import { Model, DataTypes } from "sequelize";

class Producto extends Model { }
Producto.init(
    {
        idProducto: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        NombreProducto: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Color: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        Talla: {
            type: DataTypes.ENUM("XS", "S", "M", "L", "XL", "2", "4", "6", "8", "10", "12", "14", "16"),
            allowNull: false,
        },
        Estampado: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        Stock: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        Precio: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false,
        },
        ImagenUrl: {
            type: DataTypes.TEXT('long'),
            allowNull: true,
            defaultValue: null,
            comment: 'Array de URLs de imágenes (guardado como JSON string)',
            get() {
                const val = this.getDataValue('ImagenUrl');
                if (!val) return [];
                if (Array.isArray(val)) return val;
                try { return JSON.parse(val); } catch { return []; }
            },
            set(val) {
                if (!val || val.length === 0) {
                    this.setDataValue('ImagenUrl', null);
                } else {
                    this.setDataValue('ImagenUrl', JSON.stringify(val));
                }
            }
        },
        CloudinaryId: {
            type: DataTypes.TEXT('long'),
            allowNull: true,
            defaultValue: null,
            comment: 'Array de IDs de Cloudinary (guardado como JSON string)',
            get() {
                const val = this.getDataValue('CloudinaryId');
                if (!val) return [];
                if (Array.isArray(val)) return val;
                try { return JSON.parse(val); } catch { return []; }
            },
            set(val) {
                if (!val || val.length === 0) {
                    this.setDataValue('CloudinaryId', null);
                } else {
                    this.setDataValue('CloudinaryId', JSON.stringify(val));
                }
            }
        },
    },
    { sequelize, modelName: "Producto", tableName: "Productos", freezeTableName: true }
);

export default Producto;