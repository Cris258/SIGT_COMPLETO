import EstadoPersona from "../../models/EstadoPersona.model.js";

export const seedEstadoPersonas = async () => {
    try {
        const estadosIniciales = [
            { 
                NombreEstado: "Activo", 
                DescriptionEstado: "Perfil Activo" 
            },
            { 
                NombreEstado: "Inactivo", 
                DescriptionEstado: "Perfil Inactivo por tiempo Indefinido" 
            }
        ];

        for (const estado of estadosIniciales) {
            await EstadoPersona.findOrCreate({
                where: { NombreEstado: estado.NombreEstado },
                defaults: estado
            });
        }
        
        console.log('Estados de persona iniciales verificados/creados correctamente');
    } catch (error) {
        console.error('Error al crear estados de persona iniciales:', error.message);
    }
};