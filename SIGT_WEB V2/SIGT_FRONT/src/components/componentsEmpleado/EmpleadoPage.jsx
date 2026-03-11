import React, { useState, useEffect } from "react";
import ActualizarDatosModal from "../modalesCompartidos/ModalActualizarDatos";
import CambiarPasswordModal from "../modalesCompartidos/ModalCambiarPassword";
import reporteService from "../../services/reporteService";

const EmpleadoPage = () => {
  const [usuario, setUsuario] = useState(null);
  const [tareas, setTareas] = useState([]);
  const [tareasFiltradas, setTareasFiltradas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [tareaSeleccionada, setTareaSeleccionada] = useState(null);
  const [showDetalleModal, setShowDetalleModal] = useState(false);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  useEffect(() => {
    const nombre = localStorage.getItem("Primer_Nombre");
    const apellido = localStorage.getItem("Primer_Apellido");
    if (nombre && apellido) setUsuario({ nombre, apellido });
  }, []);

  useEffect(() => { cargarDatos(); }, []);
  useEffect(() => { ordenarYFiltrarTareas(); }, [tareas, searchQuery]);

  const cargarDatos = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem("token");
      const API_URL = `${import.meta.env.VITE_API_URL}/api`;
      const resTareas = await fetch(`${API_URL}/tarea`, {
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      });
      if (!resTareas.ok) throw new Error("Error al cargar tareas");
      const dataTareas = await resTareas.json();
      setTareas(dataTareas.body || []);
      setLoading(false);
    } catch (error) {
      console.error("❌ Error al cargar datos:", error);
      setTareas([]);
      setLoading(false);
    }
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarMisTareas();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

const getPrioridadEstado = (estado) => {
  switch (estado) {
    case "Pendiente": return 1;
    case "En Progreso": return 2;
    case "Completada": return 3;
    default: return 4;
  }
};

const getPrioridadOrden = (prioridad) => {
  const orden = { Alta: 1, Urgente: 1, Media: 2, Baja: 3 };
  return orden[prioridad] || 4;
};

const compararFechas = (a, b) => {
  if (!a.FechaLimite || !b.FechaLimite) return 0;
  const fechaA = new Date(a.FechaLimite);
  const fechaB = new Date(b.FechaLimite);
  return fechaA.getTime() !== fechaB.getTime() ? fechaA - fechaB : 0;
};

const compararTareas = (a, b) => {
  const estadoA = a.EstadoTarea || "Pendiente";
  const estadoB = b.EstadoTarea || "Pendiente";
  const diffEstado = getPrioridadEstado(estadoA) - getPrioridadEstado(estadoB);
  if (diffEstado !== 0) return diffEstado;

  const esActiva = estadoA === "Pendiente" || estadoA === "En Progreso";
  if (!esActiva) return 0;

  const diffFecha = compararFechas(a, b);
  if (diffFecha !== 0) return diffFecha;

  return getPrioridadOrden(a.Prioridad) - getPrioridadOrden(b.Prioridad);
};

const filtrarTareas = (tareasOrdenadas) => {
  if (searchQuery.trim() === "") return tareasOrdenadas;
  const query = searchQuery.toLowerCase();
  return tareasOrdenadas.filter((tarea) =>
    (tarea.Descripcion || "").toLowerCase().includes(query) ||
    (tarea.EstadoTarea || "").toLowerCase().includes(query) ||
    (tarea.Prioridad || "").toLowerCase().includes(query)
  );
};

const ordenarYFiltrarTareas = () => {
  const tareasOrdenadas = [...tareas].sort(compararTareas);
  setTareasFiltradas(filtrarTareas(tareasOrdenadas));
};

  const getPrioridadColor = (prioridad) => {
    switch (prioridad) {
      case "Alta": case "Urgente": return "#ee5666";
      case "Media": return "#ffd965";
      case "Baja": return "#54e075";
      default: return "#6c757d";
    }
  };

  const getEstadoColor = (estado) => {
    switch (estado) {
      case "Completada": return "#54e075";
      case "En Progreso": return "#ffd965";
      case "Pendiente": return "#ee5666";
      default: return "#6c757d";
    }
  };

  const getEstadoIcon = (estado) => {
    switch (estado) {
      case "Completada": return "bi-check-circle";
      case "En Progreso": return "bi-arrow-repeat";
      case "Pendiente": return "bi-clock-history";
      default: return "bi-question-circle";
    }
  };

  

  const formatearFecha = (fecha) => {
    if (!fecha) return "N/A";
    try { return new Date(fecha).toLocaleDateString("es-CO"); }
    catch { return "N/A"; }
  };

  const abrirDetalles = (tarea) => { setTareaSeleccionada(tarea); setShowDetalleModal(true); };

  const calcularEstadisticas = () => ({
    pendientes: tareasFiltradas.filter(t => t.EstadoTarea === "Pendiente").length,
    enProgreso: tareasFiltradas.filter(t => t.EstadoTarea === "En Progreso").length,
    completadas: tareasFiltradas.filter(t => t.EstadoTarea === "Completada").length,
  });

  const stats = calcularEstadisticas();

  return (
    <div>
      <nav className="navbar navbar-light d-md-none" style={{ backgroundColor: "#800080" }}>
        <div className="container-fluid">
          <button
            className="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#sidebarMenu"
            style={{ borderColor: "white" }}
          >
            <span className="navbar-toggler-icon" style={{ filter: "brightness(0) invert(1)" }} />
          </button>
          <span className="navbar-brand text-white fw-bold">Panel de Empleado</span>
        </div>
      </nav>

      <div className="d-flex flex-column text-white flex-md-row">
        {/* SIDEBAR */}
        <div className="sidebar collapse d-md-block p-3 text-white" id="sidebarMenu">
          <div className="text-center text-white mb-4">
            <i className="bi bi-person-circle" style={{ fontSize: "3rem" }} />
            <h5 className="fw-bold mt-2">
              {usuario ? `${usuario.nombre} ${usuario.apellido}` : "Empleado"}
            </h5>
          </div>
          <ul className="nav flex-column text-center text-white">
            <li className="nav-item">
              <a href="#" className="nav-link custom-link" data-bs-toggle="modal" data-bs-target="#modalActualizarDatos">Actualizar Datos</a>
            </li>
            <li className="nav-item">
              <a href="#" className="nav-link custom-link" data-bs-toggle="modal" data-bs-target="#modalCambiarPassword">Cambiar Contraseña</a>
            </li>
            <hr className="bg-light" />
            <li className="nav-item">
              <a href="detalleproduccion" className="nav-link custom-link">Registrar Producción</a>
            </li>
            <li className="nav-item">
              <a href="HistorialProduccion" className="nav-link custom-link">Historial de Producción</a>
            </li>
          </ul>
        </div>

        {/* MAIN */}
        <main className="flex-grow-1 p-4 bg-light">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border" style={{ color: "#7c3aed" }} role="status">
                <span className="visually-hidden">Cargando...</span>
              </div>
              <p className="mt-3 fw-medium" style={{ color: "#6b2d9e" }}>Cargando tareas...</p>
            </div>
          ) : (
            <div className="row g-4 mb-4">
              <div className="col-12">

                {/* HEADER DE TAREAS */}
                <div className="card shadow-sm mb-3" style={{ backgroundColor: "#7cbbe4" }}>
                  <div className="card-body">
                    <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
                      <div className="d-flex align-items-center">
                        <i className="bi bi-list-task me-2 text-white" style={{ fontSize: "1.5rem" }}></i>
                        <h4 className="mb-0 text-white fw-bold">Mis Tareas</h4>
                      </div>
                      {/* BOTONES: ACTUALIZAR + GENERAR REPORTE */}
                      <div className="d-flex gap-2">
                        <button className="btn btn-light shadow-sm" onClick={cargarDatos} disabled={loading}>
                          <i className="bi bi-arrow-clockwise me-1"></i>Actualizar
                        </button>
                        <button
                          className="btn btn-light shadow-sm"
                          onClick={handleGenerarReporte}
                          disabled={generandoPDF}
                        >
                          {generandoPDF ? (
                            <>
                              <span className="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
                              Generando...
                            </>
                          ) : (
                            <>
                              <i className="bi bi-file-earmark-pdf me-1"></i>Generar Reporte
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                {/* BARRA DE BÚSQUEDA */}
                {tareas.length > 0 && (
                  <div className="card shadow-sm mb-3">
                    <div className="card-body">
                      <div className="input-group">
                        <span className="input-group-text bg-white border-end-0">
                          <i className="bi bi-search"></i>
                        </span>
                        <input
                          type="text"
                          className="form-control border-start-0"
                          placeholder="Buscar tareas..."
                          value={searchQuery}
                          onChange={(e) => setSearchQuery(e.target.value)}
                        />
                        {searchQuery && (
                          <button className="btn btn-outline-secondary" onClick={() => setSearchQuery("")}>
                            <i className="bi bi-x-lg"></i>
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}

                {/* ESTADÍSTICAS */}
                {tareas.length > 0 && (
                  <div className="row g-2 mb-3">
                    <div className="col-md-4">
                      <div className="card shadow-sm text-center border-0 h-100" style={{ borderLeft: "4px solid #ee5666", backgroundColor: "#fff5f5" }}>
                        <div className="card-body py-2 px-3">
                          <div className="d-flex align-items-center justify-content-between">
                            <div className="text-start">
                              <h3 className="mb-0 fw-bold" style={{ color: "#ee5666" }}>{stats.pendientes}</h3>
                              <small className="fw-bold" style={{ color: "#ee5666", fontSize: "0.75rem" }}>Pendientes</small>
                            </div>
                            <i className="bi bi-clock-history" style={{ fontSize: "2rem", color: "#ee5666", opacity: 0.3 }}></i>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div className="col-md-4">
                      <div className="card shadow-sm text-center border-0 h-100" style={{ borderLeft: "4px solid #f59e0b", backgroundColor: "#fffef0" }}>
                        <div className="card-body py-2 px-3">
                          <div className="d-flex align-items-center justify-content-between">
                            <div className="text-start">
                              <h3 className="mb-0 fw-bold" style={{ color: "#f59e0b" }}>{stats.enProgreso}</h3>
                              <small className="fw-bold" style={{ color: "#f59e0b", fontSize: "0.75rem" }}>En Progreso</small>
                            </div>
                            <i className="bi bi-arrow-repeat" style={{ fontSize: "2rem", color: "#f59e0b", opacity: 0.3 }}></i>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div className="col-md-4">
                      <div className="card shadow-sm text-center border-0 h-100" style={{ borderLeft: "4px solid #54e075", backgroundColor: "#f0fef4" }}>
                        <div className="card-body py-2 px-3">
                          <div className="d-flex align-items-center justify-content-between">
                            <div className="text-start">
                              <h3 className="mb-0 fw-bold" style={{ color: "#54e075" }}>{stats.completadas}</h3>
                              <small className="fw-bold" style={{ color: "#54e075", fontSize: "0.75rem" }}>Completadas</small>
                            </div>
                            <i className="bi bi-check-circle" style={{ fontSize: "2rem", color: "#54e075", opacity: 0.3 }}></i>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* LISTA DE TAREAS */}
                {tareasFiltradas.length === 0 ? (
                  <div className="card shadow-sm border-0">
                    <div className="card-body text-center py-5">
                      <i className={`bi ${searchQuery ? "bi-search" : "bi-inbox"} text-muted`} style={{ fontSize: "3.5rem", opacity: 0.5 }}></i>
                      <h5 className="mt-3 text-muted">
                        {searchQuery ? "No se encontraron tareas" : "No tienes tareas asignadas"}
                      </h5>
                    </div>
                  </div>
                ) : (
                  <div className="row g-3">
                    {tareasFiltradas.map((tarea, index) => (
                      <div className="col-12" key={tarea.idTarea || index}>
                        <div
                          className="card shadow-sm border-0"
                          style={{ borderLeft: `4px solid ${getEstadoColor(tarea.EstadoTarea)}`, cursor: "pointer", transition: "all 0.2s ease" }}
                          onClick={() => abrirDetalles(tarea)}
                          onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-2px)"; e.currentTarget.style.boxShadow = "0 4px 12px rgba(0,0,0,0.15)"; }}
                          onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = ""; }}
                        >
                          <div className="card-body p-3">
                            <div className="d-flex justify-content-between align-items-start mb-2">
                              <span className="badge bg-secondary" style={{ fontSize: "0.7rem" }}>#{String(index + 1).padStart(3, "0")}</span>
                              <span className="badge" style={{ backgroundColor: getPrioridadColor(tarea.Prioridad), color: "white", fontSize: "0.7rem" }}>
                                {tarea.Prioridad || "Media"}
                              </span>
                            </div>
                            <h6 className="mb-2 fw-bold" style={{ fontSize: "0.95rem", lineHeight: "1.4" }}>
                              {tarea.Descripcion || "Sin descripción"}
                            </h6>
                            <div className="d-flex flex-wrap gap-2 mb-2" style={{ fontSize: "0.75rem" }}>
                              <span className="text-muted"><i className="bi bi-calendar-event me-1"></i>{formatearFecha(tarea.FechaAsignacion)}</span>
                              <span className="text-muted"><i className="bi bi-calendar-check me-1"></i>{formatearFecha(tarea.FechaLimite)}</span>
                            </div>
                            <span className="badge px-2 py-1" style={{ backgroundColor: getEstadoColor(tarea.EstadoTarea), color: "white", fontSize: "0.75rem" }}>
                              <i className={`bi ${getEstadoIcon(tarea.EstadoTarea)} me-1`}></i>
                              {tarea.EstadoTarea || "Pendiente"}
                            </span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </main>
      </div>

      {/* MODAL DE DETALLES */}
      {showDetalleModal && tareaSeleccionada && (
        <div className="modal show d-block" style={{ backgroundColor: "rgba(0,0,0,0.5)" }} onClick={() => setShowDetalleModal(false)}>
          <div className="modal-dialog modal-dialog-centered" onClick={(e) => e.stopPropagation()}>
            <div className="modal-content border-0 shadow-lg">
              <div className="modal-header border-0" style={{ backgroundColor: "#7cbbe4" }}>
                <h5 className="modal-title text-white fw-bold">
                  <i className="bi bi-info-circle me-2"></i>Detalles de la Tarea
                </h5>
                <button type="button" className="btn-close btn-close-white" onClick={() => setShowDetalleModal(false)}></button>
              </div>
              <div className="modal-body p-4">
                <div className="mb-4">
                  <label className="text-muted small mb-2 text-uppercase fw-bold" style={{ fontSize: "0.7rem" }}>Descripción</label>
                  <p className="mb-0" style={{ fontSize: "1rem", lineHeight: "1.6" }}>{tareaSeleccionada.Descripcion || "N/A"}</p>
                </div>
                <div className="row g-3 mb-4">
                  <div className="col-6">
                    <label className="text-muted small mb-2 text-uppercase fw-bold" style={{ fontSize: "0.7rem" }}>Estado</label>
                    <div>
                      <span className="badge px-3 py-2" style={{ backgroundColor: getEstadoColor(tareaSeleccionada.EstadoTarea), fontSize: "0.85rem" }}>
                        <i className={`bi ${getEstadoIcon(tareaSeleccionada.EstadoTarea)} me-1`}></i>
                        {tareaSeleccionada.EstadoTarea || "Pendiente"}
                      </span>
                    </div>
                  </div>
                  <div className="col-6">
                    <label className="text-muted small mb-2 text-uppercase fw-bold" style={{ fontSize: "0.7rem" }}>Prioridad</label>
                    <div>
                      <span className="badge px-3 py-2" style={{ backgroundColor: getPrioridadColor(tareaSeleccionada.Prioridad), fontSize: "0.85rem" }}>
                        {tareaSeleccionada.Prioridad || "Media"}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="row g-3">
                  <div className="col-6">
                    <label className="text-muted small mb-2 text-uppercase fw-bold" style={{ fontSize: "0.7rem" }}>Fecha Asignación</label>
                    <p className="mb-0 d-flex align-items-center">
                      <i className="bi bi-calendar-event me-2" style={{ color: "#7cbbe4" }}></i>
                      <span className="fw-medium">{formatearFecha(tareaSeleccionada.FechaAsignacion)}</span>
                    </p>
                  </div>
                  <div className="col-6">
                    <label className="text-muted small mb-2 text-uppercase fw-bold" style={{ fontSize: "0.7rem" }}>Fecha Límite</label>
                    <p className="mb-0 d-flex align-items-center">
                      <i className="bi bi-calendar-check me-2" style={{ color: "#7cbbe4" }}></i>
                      <span className="fw-medium">{formatearFecha(tareaSeleccionada.FechaLimite)}</span>
                    </p>
                  </div>
                </div>
              </div>
              <div className="modal-footer border-0 bg-light">
                <button type="button" className="btn btn-secondary px-4" onClick={() => setShowDetalleModal(false)}>Cerrar</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <ActualizarDatosModal />
      <CambiarPasswordModal />
    </div>
  );
};

export default EmpleadoPage;