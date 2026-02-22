const authorizeRole = (...rolesPermitidos) => {
  return (req, res, next) => {
    if (!req.user || !rolesPermitidos.includes(req.user.rol)) {
      return res.status(403).json({ message: "Acceso denegado: rol no autorizado" });
    }
    next();
  };
};

export default authorizeRole;