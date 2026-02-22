import multer from 'multer';

// Configurar multer para guardar archivos en memoria temporalmente
const storage = multer.memoryStorage();

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024, // Límite de 5MB
    },
    fileFilter: (req, file, cb) => {
        console.log('📸 Archivo recibido:', {
            fieldname: file.fieldname,
            originalname: file.originalname,
            mimetype: file.mimetype,
            size: file.size
        });

        // Permitir imágenes basándose en mimetype o extensión
        const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
        const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        
        const hasValidMime = allowedMimes.includes(file.mimetype);
        const hasValidExtension = allowedExtensions.some(ext => 
            file.originalname.toLowerCase().endsWith(ext)
        );

        if (hasValidMime || hasValidExtension) {
            cb(null, true);
        } else {
            console.log('Archivo rechazado:', file.mimetype);
            cb(new Error('Solo se permiten archivos de imagen (JPG, PNG, GIF, WEBP)'), false);
        }
    }
});

export default upload;