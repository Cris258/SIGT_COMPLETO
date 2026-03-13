import express from 'express';
import cors from "cors";
import morgan from 'morgan';
import Carrito from '../routers/Carrito.router.js';
import DetalleCarrito from '../routers/DetalleCarrito.router.js';
import DetalleVenta from '../routers/DetalleVenta.router.js';
import { seedEstadoPersonas } from './seeders/estadoPersona.seeder.js';
import EstadoPersona from '../routers/EstadoPersona.router.js';
import Movimiento from '../routers/Movimiento.router.js';
import { seedPersonaInicial } from './seeders/persona.seeder.js';
import Persona from '../routers/Persona.router.js';
import Produccion from '../routers/Produccion.router.js';
import Producto from '../routers/Producto.router.js';
import { seedRoles } from './seeders/rol.seeder.js';
import Rol from '../routers/Rol.router.js';
import Tarea from '../routers/Tarera.router.js';
import Venta from '../routers/Venta.router.js';
import reporteRoutes from '../routers/reporteRoutes.js';

const app = express();

app.use(cors({
    origin: ['http://localhost:5173', 'http://127.0.0.1:5173', /^http:\/\/localhost:\d+$/, 'https://sigt-frontend-git-testing-cris258s-projects.vercel.app', /\.vercel\.app$/],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    optionsSuccessStatus: 200
}));

app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

export const initSeeders = async () => {
    await seedRoles();
    await seedEstadoPersonas();
    await seedPersonaInicial();
};

app.use('/api', Persona);
app.use('/api', Carrito);
app.use('/api', DetalleCarrito);
app.use('/api', DetalleVenta);
app.use('/api', EstadoPersona);
app.use('/api', Producto);
app.use('/api', Rol);
app.use('/api', Tarea);
app.use('/api', Venta);
app.use('/api', Produccion);
app.use('/api', Movimiento);
app.use('/api/reportes', reporteRoutes);
app.use((req, res, next) => {
    res.status(404).json(
        {
            Message: 'Endpoint no encontrado ❌'
        }
    );
}
);

export default app;