import React, { useState } from "react";
import FooterLine from "../components/FooterLine";

function RegistroTareas() {
  const [formData, setFormData] = useState({
    Descripcion: "",
    FechaAsignacion: "",
    FechaLimite: "",
    EstadoTarea: "",
    Prioridad: "",
    NumeroDocumento: "",
  });

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log("Datos Tarea:", formData);
    // Aquí llamas a tu API para guardar la tarea
  };

  return (
    <>
      <header className="py-3 shadow-sm merriweather-font">
        <div className="container">
          <div className="row g-0 justify-content-between align-items-center">
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
            <div className="col-md-8 d-flex flex-column align-items-center justify-content-center my-5">
              <form onSubmit={handleSubmit}>
                <p className="parrafo fs-5 text-black merriweather-font text-center">
                  Registro de Tareas
                  <br />
                  Ingresa la información de la tarea.
                </p>

                {/* Descripción */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="descripcion" className="form-label">
                    Descripción
                  </label>
                  <textarea
                    className="form-control"
                    id="descripcion"
                    name="Descripcion"
                    placeholder="Ej: Revisar inventario de pijamas..."
                    required
                    value={formData.Descripcion}
                    onChange={handleChange}
                  />
                </div>

                {/* Fecha Asignación */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="fechaAsignacion" className="form-label">
                    Fecha de Asignación
                  </label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    id="fechaAsignacion"
                    name="FechaAsignacion"
                    required
                    value={formData.FechaAsignacion}
                    onChange={handleChange}
                  />
                </div>

                {/* Fecha Límite */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="fechaLimite" className="form-label">
                    Fecha Límite
                  </label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    id="fechaLimite"
                    name="FechaLimite"
                    required
                    value={formData.FechaLimite}
                    onChange={handleChange}
                  />
                </div>

                {/* Estado Tarea */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="estadoTarea" className="form-label">
                    Estado de la Tarea
                  </label>
                  <select
                    className="form-select"
                    id="estadoTarea"
                    name="EstadoTarea"
                    required
                    value={formData.EstadoTarea}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione el estado
                    </option>
                    <option value="Pendiente">Pendiente</option>
                    <option value="En Proceso">En Proceso</option>
                    <option value="Finalizada">Finalizada</option>
                  </select>
                </div>

                {/* Prioridad */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="prioridad" className="form-label">
                    Prioridad
                  </label>
                  <select
                    className="form-select"
                    id="prioridad"
                    name="Prioridad"
                    required
                    value={formData.Prioridad}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione la prioridad
                    </option>
                    <option value="Alta">Alta</option>
                    <option value="Media">Media</option>
                    <option value="Baja">Baja</option>
                  </select>
                </div>

                {/* Número Documento */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="numDocumento" className="form-label">
                    Número de Documento (Responsable)
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    id="numDocumento"
                    name="NumeroDocumento"
                    placeholder="Ej: 1234567890"
                    required
                    value={formData.NumeroDocumento}
                    onChange={handleChange}
                  />
                </div>

                {/* Botón */}
                <div className="d-grid mt-5 ">
                  <button type="submit" className="boton">
                    Guardar Tarea
                  </button>
                </div>
              </form>
            </div>

            {/* Imagen lateral */}
            <div className="col-md-4 img-col">
              <img src="img/Logo Vibra Positiva.jpg" alt="Tarea" />
            </div>
          </div>
        </div>
      </section>

      <FooterLine />
    </>
  );
}

export default RegistroTareas;
