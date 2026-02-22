import jwt from 'jsonwebtoken';

const verifyToken = (req, res, next) => {
    try {
        let token = req.headers.authorization;
        if (!token) {
            return res.status(401).json({
                Message: 'No se proporcionó ningún Token',
            });
        }

        token = token.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;

        next();
    } catch (err) {
        return res.status(401).json({
            Message: 'Token no válido: ' + err.message,
        });
    }
};

export default verifyToken;
