let tokenBlacklist = [];

export const addTokenToBlacklist = (token) => {
    tokenBlacklist.push(token);
};

export const isTokenBlacklisted = (token) => {
    return tokenBlacklist.includes(token);
};

export const checkBlacklist = (req, res, next) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    if (token && isTokenBlacklisted(token)) {
        return res.status(401).json({
            ok: false,
            status: 401,
            Message: "Token Inválido (Usuario Cerró Sesión)",
        });
    }
    next();
};

export const getTokenBlacklist = () => tokenBlacklist;
export const pushToBlacklist = (token) => tokenBlacklist.push(token);
