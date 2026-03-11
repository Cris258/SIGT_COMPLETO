import React, { useState, useEffect } from "react";
import FooterLine from "../components/FooterLine";
import "../styles/styleRegistro.css";

import Swal from "sweetalert2";

function RegistroUsuarios() {
  const [showPassword, setShowPassword] = useState(false);
  const [roles, setRoles] = useState([]);
  const [formData, setFormData] = useState({
    NumeroDocumento: "",
    TipoDocumento: "",
    Primer_Nombre: "",
    Segundo_Nombre: "",
    Primer_Apellido: "",
    Segundo_Apellido: "",
    Telefono: "",
    Correo: "",
    Password: "",
    Rol_FK: "",
  });

  useEffect(() => {
    const fetchRoles = async () => {
      try {
        const token = localStorage.getItem("token");
        const response = await fetch("${import.meta.env.VITE_API_URL}/api/rol", {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });
        const data = await response.json();
        setRoles(data.body);
      } catch (error) {
        console.error("Error al obtener roles:", error);
      }
    };
    fetchRoles();
  }, []);

  const togglePassword = () => {
    setShowPassword(!showPassword);
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const envio = { ...formData };

    try {
      const token = localStorage.getItem("token");
      const response = await fetch("${import.meta.env.VITE_API_URL}/api/persona", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(envio),
      });

      const data = await response.json();
      if (response.ok) {
        Swal.fire({
          title: "¡Registro exitoso!",
          text: "El usuario fue registrado correctamente ",
          icon: "success",
          confirmButtonColor: "#bb4dbb",
          confirmButtonText: "Aceptar",
        });
        console.log("Respuesta:", data);
        setFormData({
          NumeroDocumento: "",
          TipoDocumento: "",
          Primer_Nombre: "",
          Segundo_Nombre: "",
          Primer_Apellido: "",
          Segundo_Apellido: "",
          Telefono: "",
          Correo: "",
          Password: "",
          Rol_FK: "",
        });
      } else {
        Swal.fire({
          title: "Error",
          text: data.Message || "No se pudo registrar",
          icon: "error",
          confirmButtonColor: "#d33",
          confirmButtonText: "Intentar de nuevo",
        });
      }
    } catch (error) {
      console.error("Error en el registro:", error);
      Swal.fire({
        title: "Error de conexión",
        text: "No se pudo conectar con el servidor ❌",
        icon: "warning",
        confirmButtonColor: "#f39c12",
        confirmButtonText: "Reintentar",
      });
    }
  };

  return (
    <>
      <header className="py-3 shadow-sm merriweather-font">
        <div className="container">
          <div className="row g-0 justify-content-between align-items-center">
            {/* Logo + Título */}
            <div className="col-auto d-flex align-items-center ps-2">
              <img
                src="/img/Logo Vibra Positiva.jpg"
                alt="Logo"
                className="minilogo me-2"
              />
              <h1 className="titulo fw-bold text-uppercase mb-0 fs-7 ms-2">
                Vibra Positiva Pijamas
              </h1>
            </div>
            <nav className="menu col-auto d-flex flex-column flex-md-row align-items-center gap-1 gap-md-2">
              <a
                href="admin"
                className="co1 d-flex align-items-center text-center text-black text-decoration-none"
              >
                <div className="login d-flex align-items-center gap-1">
                  <span>Volver</span>
                  <div className="icono">
                    <i className="bi bi-box-arrow-left"></i>
                  </div>
                </div>
              </a>
            </nav>
          </div>
        </div>
      </header>
      <section className="container">
        <div className="card shadow-lg border-0 overflow-hidden">
          <div className="row text-center align-items-stretch">
            {/* Formulario */}
            <div className="col-md-8 d-flex flex-column align-items-center justify-content-center my-5">
              <form onSubmit={handleSubmit}>
                <p className="parrafo fs-5 text-black merriweather-font text-center">
                  ¡Vibra Positiva Pijamas!
                  <br />
                  Regístra a una Persona para que forme parte de nuestro equipo.
                </p>

                {/* Número Documento */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="numDocumento" className="form-label">
                    Número Documento
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    id="numDocumento"
                    name="NumeroDocumento"
                    placeholder="Escriba su número de documento"
                    required
                    value={formData.NumeroDocumento}
                    onChange={handleChange}
                  />
                </div>

                {/* Tipo Documento */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="documento" className="form-label">
                    Tipo Documento
                  </label>
                  <select
                    className="form-select"
                    id="documento"
                    name="TipoDocumento"
                    required
                    value={formData.TipoDocumento}
                    onChange={handleChange}
                  >
                    <option value="" disabled defaultValue>
                      Seleccione su tipo de documento
                    </option>
                    <option value="CC">CC</option>
                    <option value="TI">TI</option>
                    <option value="CE">CE</option>
                    <option value="Pasaporte">Pasaporte</option>
                  </select>
                </div>

                {/* Primer Nombre */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="nombre" className="form-label">
                    Primer Nombre
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="nombre"
                    name="Primer_Nombre"
                    placeholder="Escriba su nombre"
                    required
                    value={formData.Primer_Nombre}
                    onChange={handleChange}
                  />
                </div>

                {/* Segundo Nombre */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="segundoNombre" className="form-label">
                    Segundo Nombre
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="segundoNombre"
                    name="Segundo_Nombre"
                    placeholder="Escriba su segundo nombre (opcional)"
                    value={formData.Segundo_Nombre}
                    onChange={handleChange}
                  />
                </div>

                {/* Primer Apellido */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="apellido" className="form-label">
                    Primer Apellido
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="apellido"
                    name="Primer_Apellido"
                    placeholder="Escriba su primer apellido"
                    required
                    value={formData.Primer_Apellido}
                    onChange={handleChange}
                  />
                </div>

                {/* Segundo Apellido */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="segundoApellido" className="form-label">
                    Segundo Apellido
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="segundoApellido"
                    name="Segundo_Apellido"
                    placeholder="Escriba su segundo apellido (opcional)"
                    value={formData.Segundo_Apellido}
                    onChange={handleChange}
                  />
                </div>

                {/* Teléfono */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="telefono" className="form-label">
                    Número de Teléfono
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    id="telefono"
                    name="Telefono"
                    placeholder="Ej: 3123456789"
                    required
                    value={formData.Telefono}
                    onChange={handleChange}
                  />
                </div>

                {/* Correo */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="correo" className="form-label">
                    Correo electrónico
                  </label>
                  <input
                    type="email"
                    className="form-control"
                    id="correo"
                    name="Correo"
                    placeholder="sucorreo@ejemplo.com"
                    required
                    value={formData.Correo}
                    onChange={handleChange}
                  />
                </div>

                {/* Contraseña con toggle */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="clave" className="form-label">
                    Contraseña
                  </label>
                  <div className="input-group">
                    <input
                      type={showPassword ? "text" : "password"}
                      id="clave"
                      name="Password"
                      className="form-control"
                      placeholder="Ingrese su contraseña"
                      required
                      value={formData.Password}
                      onChange={handleChange}
                    />
                    <button
                      className="btn btn-outline-secondary"
                      type="button"
                      onClick={togglePassword}
                    >
                      {showPassword ? (
                        <i className="bi bi-eye-slash"></i>
                      ) : (
                        <i className="bi bi-eye"></i>
                      )}
                    </button>
                  </div>
                </div>

                {/* Rol */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="rol" className="form-label">
                    Rol
                  </label>
                  <select
                    className="form-select"
                    id="rol"
                    name="Rol_FK"
                    required
                    value={formData.Rol_FK}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione un rol
                    </option>
                    {roles
                      .filter((rolItem) => rolItem.NombreRol !== "SuperAdmin")
                      .map((rolItem) => (
                        <option key={rolItem.idRol} value={rolItem.idRol}>
                          {rolItem.NombreRol}
                        </option>
                      ))}
                  </select>
                </div>

                {/* Botón */}
                <div className="d-grid mt-5 ">
                  <button type="submit" className="boton">
                    Registrarse
                  </button>
                </div>
              </form>
            </div>

            {/* Imagen lateral */}
            <div className="col-md-4 img-col">
              <img src="img/Logo Vibra Positiva.jpg" alt="Registro" />
            </div>
          </div>
        </div>
      </section>
      <FooterLine />
    </>
  );
}

export default RegistroUsuarios;
