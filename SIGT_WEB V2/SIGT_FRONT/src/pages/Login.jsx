import React, { useState } from "react";
import Swal from "sweetalert2";
import "../styles/styleRegistro.css";
import Footer from "../components/componentsMain(tienda)/Footer";

function Login() {
  const [correo, setCorreo] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const togglePassword = () => setShowPassword(!showPassword);

 const guardarSesion = (data) => {
  if (data.token) localStorage.setItem("token", data.token);
  if (data.rol) localStorage.setItem("rol", data.rol);
  if (data.id) localStorage.setItem("idPersona", data.id);
  if (data.nombre) localStorage.setItem("Primer_Nombre", data.nombre);
  if (data.apellido) localStorage.setItem("Primer_Apellido", data.apellido);
};

const getRutaPorRol = (rol) => {
  switch (rol) {
    case "SuperAdmin":
    case "Administrador": return "/admin";
    case "Empleado": return "/empleado";
    case "Cliente": return "/TiendaLine";
    default: return "/";
  }
};

const redirigirSegunRol = (rol) => {
  Swal.fire({
    title: "¡Bienvenido!",
    text: "Inicio de sesión exitoso",
    icon: "success",
  }).then(() => {
    window.location.href = getRutaPorRol(rol);
  });
};

const handleSubmit = async (e) => {
  e.preventDefault();
  try {
    const response = await fetch("http://localhost:3001/api/persona/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ Correo: correo, Password: password }),
    });
    const data = await response.json();
    if (response.ok) {
      guardarSesion(data);
      redirigirSegunRol(data.rol);
    } else {
      Swal.fire({
        title: "Inicio no válido",
        text: data.message || "Usuario o contraseña incorrecta",
        icon: "error",
      });
    }
  } catch (error) {
    Swal.fire({
      title: "Error de conexión",
      text: "No se pudo conectar con el servidor",
      icon: "error",
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
      <section className="container my-5">
        <div className="card shadow-lg border-0 overflow-hidden">
          <div className="row text-center align-items-stretch">
            <div className="col-md-8 d-flex flex-column align-items-center justify-content-center my-4">
              <form onSubmit={handleSubmit}>
                <p className="parrafo fs-5 text-black merriweather-font">
                  ¡Bienvenido a Vibra Positiva Pijamas!
                  <br />
                  Inicia Sesión para tener acceso a nuestro contenido.
                </p>

                <div className="mb-3">
                  <label className="form-label text-start d-block">
                    Correo
                  </label>
                  <input
                    type="email"
                    className="form-control no-spinner"
                    value={correo}
                    onChange={(e) => setCorreo(e.target.value)}
                    placeholder="Escriba su Correo Electronico"
                    required
                  />
                </div>

                <div className="mb-4">
                  <label className="form-label text-start d-block">
                    Contraseña
                  </label>
                  <div className="input-group">
                    <input
                      type={showPassword ? "text" : "password"}
                      className="form-control"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
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

                <div className="d-grid mb-4">
                  <button type="submit" className="boton-login">
                    Iniciar sesión
                  </button>
                </div>

                <div className="text-center mb-2">
                  <a href="/ForgotPasswordPage" className="link-login">
                    ¿Olvidó su contraseña?
                  </a>
                </div>

                <div className="text-center">
                  <p>
                    No te has registrado
                    <a href="/registro" className="link-login">
                      {" "}
                      Registrate
                    </a>{" "}
                    aqui
                  </p>
                </div>
              </form>
            </div>

            <div className="col-md-4 img-col">
              <img src="img/Logo Vibra Positiva.jpg" alt="Registro" />
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}

export default Login;
