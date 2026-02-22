import Rol from "../../models/Rol.model.js";

export const seedRoles = async () => {
    try {
        // Verifica si ya existen roles
        const count = await Rol.count();
        
        if (count === 0) {
            const rolesIniciales = [
                {
                    NombreRol: "SuperAdmin",
                    DescripcionRol: "SuperAdmin"
                },
                {
                    NombreRol: "Administrador",
                    DescripcionRol: "Administrador"
                },
                {
                    NombreRol: "Empleado",
                    DescripcionRol: "Empleado"
                },
                {
                    NombreRol: "Cliente",
                    DescripcionRol: "Cliente"
                }
            ];

            await Rol.bulkCreate(rolesIniciales);
            console.log('Roles iniciales creados correctamente');
        } else {
            console.log('Los roles ya existen en la base de datos');
        }
    } catch (error) {
        console.error('Error al crear roles iniciales:', error.message);
    }
};