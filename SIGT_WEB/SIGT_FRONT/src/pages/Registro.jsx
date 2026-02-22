import React, { useState } from "react";
import Swal from "sweetalert2";
import FooterLine from "../components/FooterLine";
import "../styles/styleRegistro.css";

function Registro() {
  const [showPassword, setShowPassword] = useState(false);
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
  });

  const togglePassword = () => {
    setShowPassword(!showPassword);
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch("http://localhost:3001/api/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (response.ok) {
        Swal.fire({
          title: "Registro exitoso",
          text: "Tu cuenta fue creada correctamente",
          icon: "success",
          confirmButtonText: "Aceptar",
          confirmButtonColor: "#bb4dbb",
        });

        // Limpiar los campos del formulario
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
        });
      } else {
        Swal.fire({
          title: "Error",
          text: data.Message || "No se pudo registrar",
          icon: "error",
          confirmButtonText: "Intentar de nuevo",
          confirmButtonColor: "#d33",
        });
      }
    } catch (error) {
      console.error("Error en el registro:", error);
      Swal.fire({
        title: "❌ Error de conexión",
        text: "No se pudo conectar con el servidor",
        icon: "error",
        confirmButtonText: "Cerrar",
        confirmButtonColor: "#d33",
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
                href="/"
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
                  ¡Bienvenido a Vibra Positiva Pijamas!
                  <br />
                  Regístrate para formar parte de nuestro equipo.
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

export default Registro;
