export default (schema) => {
    return async (req, res, next) => {
        try {
            await schema.validateAsync(req.body);
            next();
        } catch (err) {
            return res.status(400).json({
                ok: false,
                status: 400,
                Message: err.message
            });
        }
    }
};