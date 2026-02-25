import React, { useState } from "react";
import Swal from "sweetalert2";
import Footer from "../components/componentsMain(tienda)/Footer";

function RecuperarContraseña() {
  const [numDocumento, setNumDocumento] = useState("");
  const [correo, setCorreo] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();

    if (!numDocumento || !correo) {
      Swal.fire("Error", "Por favor complete todos los campos", "error");
      return;
    }

    Swal.fire(
      "Solicitud enviada",
      `Se ha enviado la solicitud de recuperación para ${correo}`,
      "success"
    );

    // Limpiar campos
    setNumDocumento("");
    setCorreo("");
  };

  return (
    <>
      <section className="container my-5">
        <div className="card shadow-lg border-0 overflow-hidden">
          <div className="container">
            <div className="row text-center align-items-stretch">
              <div className="col-md-8 d-flex flex-column align-items-center justify-content-center my-4">
                <h2>Recuperar contraseña</h2>
                <form onSubmit={handleSubmit}>
                  <div className="mb-3">
                    <label className="form-label text-start d-block">
                      Número Documento
                    </label>
                    <input
                      type="number"
                      className="form-control"
                      value={numDocumento}
                      onChange={(e) => setNumDocumento(e.target.value)}
                      placeholder="Escriba su número de documento"
                      required
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-start d-block">
                      Correo electrónico
                    </label>
                    <input
                      type="email"
                      className="form-control"
                      value={correo}
                      onChange={(e) => setCorreo(e.target.value)}
                      placeholder="sucorreo@ejemplo.com"
                      required
                    />
                  </div>

                  <div className="d-grid">
                    <button type="submit" className="boton">
                      Enviar solicitud
                    </button>
                  </div>
                </form>
              </div>
              <div className="col-md-4 p-0">
                <img
                  src="img/Logo Vibra Positiva.jpg"
                  className="img-fluid img h-100"
                  alt="Diseño"
                />
              </div>
            </div>
          </div>
        </div>
      </section>
      <Footer/>
    </>
    
  );
}

export default RecuperarContraseña;
