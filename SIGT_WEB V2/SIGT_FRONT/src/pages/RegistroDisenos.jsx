import React, { useState } from "react";
import FooterLine from "../components/FooterLine";
import "../styles/styleRegistro.css";

function RegistroDiseños() {
  const [formData, setFormData] = useState({
    NombreDiseño: "",
    Descripcion: "",
    Precio: "",
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const envio = { ...formData };

    try {
      const token = localStorage.getItem("token");
      const response = await fetch("http://localhost:3001/api/diseno", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(envio),
      });

      const data = await response.json();
      if (response.ok) {
        alert("Diseño registrado exitosamente ✅");
        console.log("Respuesta:", data);
        setFormData({
          NombreDiseño: "",
          Descripcion: "",
          Precio: "",
        });
      } else {
        alert("Error: " + (data.Message || "No se pudo registrar el diseño"));
      }
    } catch (error) {
      console.error("Error en el registro:", error);
      alert("Error de conexión con el servidor ❌");
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
                href="/adminInventario"
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
                  Registra un nuevo diseño en el catálogo.
                </p>

                {/* Nombre Diseño */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="nombreDiseno" className="form-label">
                    Nombre del Diseño
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="nombreDiseno"
                    name="NombreDiseño"
                    placeholder="Ej: Diseño Unicornio Mágico"
                    required
                    value={formData.NombreDiseño}
                    onChange={handleChange}
                  />
                </div>

                {/* Descripción */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="descripcion" className="form-label">
                    Descripción
                  </label>
                  <textarea
                    className="form-control"
                    id="descripcion"
                    name="Descripcion"
                    placeholder="Describe el diseño, sus características y detalles..."
                    required
                    rows="4"
                    value={formData.Descripcion}
                    onChange={handleChange}
                  />
                </div>

                {/* Precio */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="precio" className="form-label">
                    Precio (COP)
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    id="precio"
                    name="Precio"
                    placeholder="Ej: 50000"
                    required
                    min="0"
                    step="100"
                    value={formData.Precio}
                    onChange={handleChange}
                  />
                </div>

                {/* Botón */}
                <div className="d-grid mt-5">
                  <button type="submit" className="boton">
                    Registrar Diseño
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

export default RegistroDiseños;