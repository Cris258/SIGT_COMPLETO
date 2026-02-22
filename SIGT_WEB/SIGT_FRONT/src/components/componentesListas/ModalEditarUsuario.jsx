import { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

import Swal from "sweetalert2";

export default function ModalEditarUsuario({ usuario, onClose, onGuardar }) {
  const [formData, setFormData] = useState({
    NumeroDocumento: "",
    TipoDocumento: "",
    Primer_Nombre: "",
    Segundo_Nombre: "",
    Primer_Apellido: "",
    Segundo_Apellido: "",
    Telefono: "",
    Correo: "",
    Rol_FK: "",
    EstadoPersona_FK: 1,
  });

  const estados = [
    { id: 1, nombre: "Activo" },
    { id: 2, nombre: "Inactivo" },
  ];

  const roles = [
    { id: 2, nombre: "Administrador" },
    { id: 3, nombre: "Empleado" },
    { id: 4, nombre: "Cliente" },
  ];

  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (usuario) {
      console.log("📦 Usuario seleccionado:", usuario);

      setFormData({
        NumeroDocumento: usuario.NumeroDocumento || "",
        TipoDocumento: usuario.TipoDocumento || "",
        Primer_Nombre: usuario.Primer_Nombre || "",
        Segundo_Nombre: usuario.Segundo_Nombre || "",
        Primer_Apellido: usuario.Primer_Apellido || "",
        Segundo_Apellido: usuario.Segundo_Apellido || "",
        Telefono: usuario.Telefono || "",
        Correo: usuario.Correo || "",
        Rol_FK: usuario.Rol_FK || "",
        EstadoPersona_FK: usuario.EstadoPersona_FK || 1,
      });
    }
  }, [usuario]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));

    if (errors[name]) {
      setErrors((prev) => ({
        ...prev,
        [name]: "",
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.NumeroDocumento || formData.NumeroDocumento.toString().trim() === "") {
      newErrors.NumeroDocumento = "El número de documento es requerido";
    }

    if (!formData.TipoDocumento) {
      newErrors.TipoDocumento = "El tipo de documento es requerido";
    }

    if (!formData.Primer_Nombre.trim()) {
      newErrors.Primer_Nombre = "El primer nombre es requerido";
    }

    if (!formData.Primer_Apellido.trim()) {
      newErrors.Primer_Apellido = "El primer apellido es requerido";
    }

    if (!formData.Telefono.trim()) {
      newErrors.Telefono = "El teléfono es requerido";
    } else if (!/^\d{10}$/.test(formData.Telefono)) {
      newErrors.Telefono = "El teléfono debe tener 10 dígitos";
    }

    if (!formData.Correo.trim()) {
      newErrors.Correo = "El correo es requerido";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.Correo)) {
      newErrors.Correo = "El formato del correo no es válido";
    }

    if (!formData.Rol_FK) {
      newErrors.Rol_FK = "Debe seleccionar un rol";
    }

    if (!formData.EstadoPersona_FK) {
      newErrors.EstadoPersona_FK = "Debe seleccionar un estado";
    }

    const nameRegex = /^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$/;

    if (formData.Primer_Nombre && !nameRegex.test(formData.Primer_Nombre)) {
      newErrors.Primer_Nombre = "El nombre solo puede contener letras";
    }

    if (formData.Segundo_Nombre && !nameRegex.test(formData.Segundo_Nombre)) {
      newErrors.Segundo_Nombre = "El nombre solo puede contener letras";
    }

    if (formData.Primer_Apellido && !nameRegex.test(formData.Primer_Apellido)) {
      newErrors.Primer_Apellido = "El apellido solo puede contener letras";
    }

    if (formData.Segundo_Apellido && !nameRegex.test(formData.Segundo_Apellido)) {
      newErrors.Segundo_Apellido = "El apellido solo puede contener letras";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    console.log("🔄 Iniciando actualización de usuario...");

    if (!validateForm()) {
      console.log("❌ Validación fallida");
      return;
    }

    setLoading(true);

    try {
      const datosParaActualizar = {
        TipoDocumento: formData.TipoDocumento,
        NumeroDocumento: formData.NumeroDocumento,
        Primer_Nombre: formData.Primer_Nombre.trim(),
        Segundo_Nombre: formData.Segundo_Nombre.trim(),
        Primer_Apellido: formData.Primer_Apellido.trim(),
        Segundo_Apellido: formData.Segundo_Apellido.trim(),
        Telefono: formData.Telefono.trim(),
        Correo: formData.Correo.trim(),
        Rol_FK: parseInt(formData.Rol_FK),
        EstadoPersona_FK: parseInt(formData.EstadoPersona_FK),
      };

      const token = localStorage.getItem("token");

      console.log(
        "📤 Enviando actualización a:",
        `http://localhost:3001/api/persona/${usuario.idPersona}`
      );
      console.log("📦 Datos:", datosParaActualizar);

      const response = await fetch(
        `http://localhost:3001/api/persona/${usuario.idPersona}`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(datosParaActualizar),
        }
      );

      const result = await response.json();
      console.log("📥 Respuesta del servidor:", result);

      if (response.ok) {
        Swal.fire({
          icon: "success",
          title: "Usuario actualizado",
          text: "El usuario se actualizó correctamente",
          confirmButtonColor: "#3085d6",
        });

        const rolSeleccionado = roles.find(r => r.id === parseInt(formData.Rol_FK));

        const usuarioActualizado = {
          ...usuario,
          ...datosParaActualizar,
          Rol: rolSeleccionado ? { NombreRol: rolSeleccionado.nombre } : usuario.Rol,
        };

        onGuardar(usuarioActualizado);
        onClose();
      } else {
        if (result.errors) {
          setErrors(result.errors);
        } else {
          Swal.fire({
            icon: "error",
            title: "Error",
            text: result.message || "Error al actualizar el usuario",
            confirmButtonColor: "#d33",
          });
        }
      }
    } catch (error) {
      console.error("💥 Error:", error);
      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "Por favor, intente nuevamente.",
        confirmButtonColor: "#d33",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!usuario) return null;


  return (
    <div
      className="modal fade show"
      style={{ display: "block", backgroundColor: "rgba(0,0,0,0.5)" }}
      tabIndex="-1"
    >
      <div className="modal-dialog modal-dialog-centered modal-lg">
        <div className="modal-content rounded-3 shadow">
          <div className="modal-header">
            <h5 className="modal-title">Editar Usuario</h5>
            <button
              type="button"
              className="btn-close"
              onClick={onClose}
              aria-label="Cerrar"
            ></button>
          </div>

          <div className="modal-body bg-light">
            {loading && (
              <div className="text-center mb-3">
                <div className="spinner-border text-primary" role="status">
                  <span className="visually-hidden">Cargando...</span>
                </div>
              </div>
            )}

            <div className="row g-3">
              <div className="col-md-6">
                <label className="form-label">
                  Tipo de Documento <span className="text-danger">*</span>
                </label>
                <select
                  className={`form-select ${
                    errors.TipoDocumento ? "is-invalid" : ""
                  }`}
                  name="TipoDocumento"
                  value={formData.TipoDocumento}
                  onChange={handleInputChange}
                  disabled={loading}
                >
                  <option value="">Seleccione...</option>
                  <option value="CC">Cédula de Ciudadanía</option>
                  <option value="TI">Tarjeta de Identidad</option>
                  <option value="CE">Cédula de Extranjería</option>
                  <option value="PA">Pasaporte</option>
                </select>
                {errors.TipoDocumento && (
                  <div className="invalid-feedback">{errors.TipoDocumento}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Número de Documento <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.NumeroDocumento ? "is-invalid" : ""
                  }`}
                  name="NumeroDocumento"
                  value={formData.NumeroDocumento}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.NumeroDocumento && (
                  <div className="invalid-feedback">
                    {errors.NumeroDocumento}
                  </div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Primer Nombre <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.Primer_Nombre ? "is-invalid" : ""
                  }`}
                  name="Primer_Nombre"
                  value={formData.Primer_Nombre}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.Primer_Nombre && (
                  <div className="invalid-feedback">{errors.Primer_Nombre}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">Segundo Nombre</label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.Segundo_Nombre ? "is-invalid" : ""
                  }`}
                  name="Segundo_Nombre"
                  value={formData.Segundo_Nombre}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.Segundo_Nombre && (
                  <div className="invalid-feedback">
                    {errors.Segundo_Nombre}
                  </div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Primer Apellido <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.Primer_Apellido ? "is-invalid" : ""
                  }`}
                  name="Primer_Apellido"
                  value={formData.Primer_Apellido}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.Primer_Apellido && (
                  <div className="invalid-feedback">
                    {errors.Primer_Apellido}
                  </div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">Segundo Apellido</label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.Segundo_Apellido ? "is-invalid" : ""
                  }`}
                  name="Segundo_Apellido"
                  value={formData.Segundo_Apellido}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.Segundo_Apellido && (
                  <div className="invalid-feedback">
                    {errors.Segundo_Apellido}
                  </div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Teléfono <span className="text-danger">*</span>
                </label>
                <input
                  type="tel"
                  className={`form-control ${
                    errors.Telefono ? "is-invalid" : ""
                  }`}
                  name="Telefono"
                  value={formData.Telefono}
                  onChange={handleInputChange}
                  placeholder="Ej: 3001234567"
                  disabled={loading}
                />
                {errors.Telefono && (
                  <div className="invalid-feedback">{errors.Telefono}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Correo <span className="text-danger">*</span>
                </label>
                <input
                  type="email"
                  className={`form-control ${
                    errors.Correo ? "is-invalid" : ""
                  }`}
                  name="Correo"
                  value={formData.Correo}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.Correo && (
                  <div className="invalid-feedback">{errors.Correo}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Rol <span className="text-danger">*</span>
                </label>
                <select
                  name="Rol_FK"
                  value={formData.Rol_FK}
                  onChange={handleInputChange}
                  className={`form-select ${errors.Rol_FK ? "is-invalid" : ""}`}
                  disabled={loading}
                >
                  <option value="">Seleccione un rol</option>
                  {roles.map((rol) => (
                    <option key={rol.id} value={rol.id}>
                      {rol.nombre}
                    </option>
                  ))}
                </select>
                {errors.Rol_FK && (
                  <div className="invalid-feedback">{errors.Rol_FK}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Estado <span className="text-danger">*</span>
                </label>
                <select
                  name="EstadoPersona_FK"
                  value={formData.EstadoPersona_FK}
                  onChange={handleInputChange}
                  className={`form-select ${errors.EstadoPersona_FK ? "is-invalid" : ""}`}
                  disabled={loading}
                >
                  <option value="">Seleccione un estado</option>
                  {estados.map((estado) => (
                    <option key={estado.id} value={estado.id}>
                      {estado.nombre}
                    </option>
                  ))}
                </select>
                {errors.EstadoPersona_FK && (
                  <div className="invalid-feedback">{errors.EstadoPersona_FK}</div>
                )}
              </div>
            </div>
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onClose}
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleSubmit}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                  ></span>
                  Actualizando...
                </>
              ) : (
                "Guardar Cambios"
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}