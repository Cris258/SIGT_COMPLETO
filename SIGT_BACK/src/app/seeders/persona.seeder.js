import Persona from "../../models/Persona.model.js";
import bcrypt from "bcrypt";

export const seedPersonaInicial = async () => {
    try {
        const personaExiste = await Persona.findOne({
            where: { NumeroDocumento: 1141314753 }
        });

        if (!personaExiste) {
            const hashedPassword = await bcrypt.hash("111111", 10);

            const personaInicial = {
                NumeroDocumento: 1141314753,
                TipoDocumento: "CC",
                Primer_Nombre: "Cristian",
                Segundo_Nombre: "Mateo",
                Primer_Apellido: "Valencia",
                Segundo_Apellido: "Peña",
                Telefono: "3208478371",
                Correo: "crismatius46@gmail.com",
                Password: hashedPassword,
                Rol_FK: 1,
                EstadoPersona_FK: 1
            };

            await Persona.create(personaInicial);
            console.log('Persona inicial (SuperAdmin) creada correctamente');
        } else {
            console.log('La persona inicial ya existe en la base de datos');
        }
    } catch (error) {
        console.error('Error al crear persona inicial:', error.message);
    }
};