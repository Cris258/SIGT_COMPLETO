import { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

export default function RegistrarProduccion() {
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [tareasPendientes, setTareasPendientes] = useState([]);
  const [tareasEnProgreso, setTareasEnProgreso] = useState([]);
  const [errorMessage, setErrorMessage] = useState(null);
  
  // Estados para modales
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [confirmAction, setConfirmAction] = useState(null);
  const [successData, setSuccessData] = useState(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      console.error("❌ No se encontró token de autenticación");
      setErrorMessage("No se encontró token de autenticación");
      setInitialLoading(false);
      return;
    }
    cargarTareas();
  }, []);

  const cargarTareas = async () => {
    try {
      setLoading(true);
      setErrorMessage(null);
      
      const token = localStorage.getItem("token");
      const API_URL = "http://localhost:3001/api";

      console.log("📡 Cargando tareas...");

      const response = await fetch(`${API_URL}/tarea`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      console.log(`📡 Status: ${response.status}`);

      if (!response.ok) {
        throw new Error("Error al cargar tareas");
      }

      const data = await response.json();
      console.log("📄 Datos recibidos:", data);
      
      const todasLasTareas = data.body || [];

      // Función de ordenamiento
      const ordenarTareas = (tareas) => {
        return tareas.sort((a, b) => {
          // 1. Ordenar por fecha de vencimiento (más pronto primero)
          const fechaA = a.FechaVencimiento ? new Date(a.FechaVencimiento) : new Date('2099-12-31');
          const fechaB = b.FechaVencimiento ? new Date(b.FechaVencimiento) : new Date('2099-12-31');
          
          if (fechaA.getTime() !== fechaB.getTime()) {
            return fechaA - fechaB; // Fecha más cercana primero
          }

          // 2. Si las fechas son iguales, ordenar por prioridad
          const prioridadOrden = { 'Alta': 1, 'Urgente': 1, 'Media': 2, 'Baja': 3 };
          const prioridadA = prioridadOrden[a.Prioridad] || 4;
          const prioridadB = prioridadOrden[b.Prioridad] || 4;
          
          return prioridadA - prioridadB; // Alta (1) antes que Media (2) antes que Baja (3)
        });
      };

      const pendientes = ordenarTareas(
        todasLasTareas.filter((t) => t.EstadoTarea === "Pendiente")
      );
      const enProgreso = ordenarTareas(
        todasLasTareas.filter((t) => t.EstadoTarea === "En Progreso")
      );

      setTareasPendientes(pendientes);
      setTareasEnProgreso(enProgreso);
      
      console.log(
        `✅ Tareas cargadas: ${pendientes.length} pendientes, ${enProgreso.length} en progreso`
      );
    } catch (error) {
      console.error("❌ Error al cargar tareas:", error);
      setErrorMessage("Error al cargar las tareas. Por favor, intenta nuevamente.");
    } finally {
      setLoading(false);
      setInitialLoading(false);
    }
  };

 // Fuera del componente o al inicio del mismo, reemplaza la duplicada en línea 57
const ordenarTareas = (tareas) => {
  return [...tareas].sort((a, b) => {
    const fechaA = a.FechaVencimiento ? new Date(a.FechaVencimiento) : new Date("2099-12-31");
    const fechaB = b.FechaVencimiento ? new Date(b.FechaVencimiento) : new Date("2099-12-31");
    if (fechaA.getTime() !== fechaB.getTime()) return fechaA - fechaB;
    const prioridadOrden = { Alta: 1, Urgente: 1, Media: 2, Baja: 3 };
    return (prioridadOrden[a.Prioridad] || 4) - (prioridadOrden[b.Prioridad] || 4);
  });
};

const moverTareaAEnProgreso = (idTarea) => {
  const tareaActualizada = tareasPendientes.find(t => t.idTarea === idTarea);
  if (!tareaActualizada) return;
  setTareasPendientes(tareasPendientes.filter(t => t.idTarea !== idTarea));
  setTareasEnProgreso(ordenarTareas([...tareasEnProgreso, { ...tareaActualizada, EstadoTarea: "En Progreso" }]));
};

const moverTareaAPendiente = (idTarea) => {
  const tareaActualizada = tareasEnProgreso.find(t => t.idTarea === idTarea);
  if (!tareaActualizada) return;
  setTareasEnProgreso(tareasEnProgreso.filter(t => t.idTarea !== idTarea));
  setTareasPendientes(ordenarTareas([...tareasPendientes, { ...tareaActualizada, EstadoTarea: "Pendiente" }]));
};

const actualizarEstadoLocal = (idTarea, nuevoEstado) => {
  if (nuevoEstado === "En Progreso") moverTareaAEnProgreso(idTarea);
  else if (nuevoEstado === "Pendiente") moverTareaAPendiente(idTarea);
};

const cambiarEstadoTarea = async (idTarea, nuevoEstado) => {
  const API_URL = "http://localhost:3001/api";
  try {
    const token = localStorage.getItem("token");
    console.log(`🔄 Cambiando estado de tarea ${idTarea} a ${nuevoEstado}`);
    const response = await fetch(`${API_URL}/tarea/${idTarea}`, {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ EstadoTarea: nuevoEstado }),
    });
    console.log(`📡 Status: ${response.status}`);
    const result = await response.json();
    console.log(`📄 Response:`, result);
    if (response.ok) {
      actualizarEstadoLocal(idTarea, nuevoEstado);
      mostrarMensaje("success", "Estado actualizado correctamente");
    } else {
      mostrarMensaje("danger", result.Message || "Error al actualizar estado");
    }
  } catch (error) {
    console.error("❌ Error al cambiar estado:", error);
    mostrarMensaje("danger", "Error de conexión");
  }
};

  const completarTarea = async (idTarea) => {
    try {
      setLoading(true);
      const token = localStorage.getItem("token");
      const API_URL = "http://localhost:3001/api";

      console.log(`✅ Completando tarea ${idTarea}`);

      const response = await fetch(`${API_URL}/tarea/${idTarea}/completar`, {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      console.log(`📡 Status: ${response.status}`);
      const result = await response.json();
      console.log(`📄 Response:`, result);

      if (response.ok) {
        setSuccessData(result.data);
        setShowSuccessModal(true);
        await cargarTareas();
      } else {
        mostrarMensaje("danger", result.message || "Error al completar tarea");
      }
    } catch (error) {
      console.error("❌ Error al completar tarea:", error);
      mostrarMensaje("danger", "Error de conexión");
    } finally {
      setLoading(false);
    }
  };

  const confirmarCambioEstado = (idTarea, estadoActual, nuevoEstado) => {
    setConfirmAction({
      type: "cambioEstado",
      idTarea,
      estadoActual,
      nuevoEstado,
      mensaje: `¿Deseas cambiar el estado de "${estadoActual}" a "${nuevoEstado}"?`,
    });
    setShowConfirmModal(true);
  };

  const confirmarCompletarTarea = (idTarea, descripcion) => {
    setConfirmAction({
      type: "completar",
      idTarea,
      descripcion,
      mensaje: "¿Estás seguro de completar esta tarea?",
    });
    setShowConfirmModal(true);
  };

  const ejecutarAccion = () => {
    if (!confirmAction) return;

    if (confirmAction.type === "cambioEstado") {
      cambiarEstadoTarea(confirmAction.idTarea, confirmAction.nuevoEstado);
    } else if (confirmAction.type === "completar") {
      completarTarea(confirmAction.idTarea);
    }

    setShowConfirmModal(false);
    setConfirmAction(null);
  };

  const mostrarMensaje = (tipo, texto) => {
    // Crear y mostrar un toast de Bootstrap
    const toastHtml = `
      <div class="toast align-items-center text-white bg-${tipo} border-0" role="alert">
        <div class="d-flex">
          <div class="toast-body">${texto}</div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
      </div>
    `;
    
    const toastContainer = document.getElementById("toast-container");
    if (toastContainer) {
      toastContainer.insertAdjacentHTML("beforeend", toastHtml);
      const toastElement = toastContainer.lastElementChild;
      const toast = new window.bootstrap.Toast(toastElement);
      toast.show();
      
      setTimeout(() => toastElement.remove(), 5000);
    }
  };

  const getPrioridadColor = (prioridad) => {
    switch (prioridad) {
      case "Alta":
      case "Urgente":
        return "#ee5666";
      case "Media":
        return "#ffd965";
      case "Baja":
        return "#54e075";
      default:
        return "#6c757d";
    }
  };

  if (initialLoading) {
    return (
      <div
        className="d-flex justify-content-center align-items-center"
        style={{ minHeight: "100vh", backgroundColor: "#f8f9fa" }}
      >
        <div className="text-center">
          <div className="spinner-border" role="status" style={{ width: "3rem", height: "3rem", color: "#7c3aed" }}>
            <span className="visually-hidden">Cargando...</span>
          </div>
          <p className="mt-3 fw-medium" style={{ color: "#6b2d9e" }}>Cargando tareas...</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: "#f8f9fa", minHeight: "100vh" }}>
      {/* Toast Container */}
      <div
        id="toast-container"
        className="position-fixed top-0 end-0 p-3"
        style={{ zIndex: 1100 }}
      ></div>

      {/* Header */}
      <div className="bg-white shadow-sm sticky-top">
        <div className="container-fluid py-4 position-relative">
          <div className="text-center">
            <h2 className="mb-0 fw-bold" style={{ color: "#6b2d9e", fontSize: "2rem", letterSpacing: "-0.5px" }}>
              <i className="bi bi-clipboard-check me-2"></i>
              Registrar Producción
            </h2>
          </div>
          <div className="position-absolute top-50 end-0 translate-middle-y me-4">
            <button
              className="btn btn-sm shadow-sm"
              style={{ 
                backgroundColor: "#7c3aed", 
                borderColor: "#7c3aed", 
                color: "white",
                fontWeight: "500",
                padding: "0.5rem 1rem"
              }}
              onClick={cargarTareas}
              disabled={loading}
            >
              <i className="bi bi-arrow-clockwise me-1"></i>
              Actualizar
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="py-3 px-3" style={{ maxWidth: "1100px", margin: "0 auto" }}>
        {errorMessage ? (
          <div className="text-center py-5">
            <i className="bi bi-exclamation-triangle" style={{ fontSize: "4rem", color: "#dc3545" }}></i>
            <h4 className="mt-3" style={{ color: "#dc3545" }}>Error</h4>
            <p className="text-muted">{errorMessage}</p>
            <button 
              className="btn shadow-sm" 
              style={{ backgroundColor: "#7c3aed", borderColor: "#7c3aed", color: "white" }}
              onClick={cargarTareas}
            >
              <i className="bi bi-arrow-clockwise me-2"></i>
              Reintentar
            </button>
          </div>
        ) : (
          <>
            {/* Tareas Pendientes */}
            <SeccionTareas
              titulo="Tareas Pendientes"
              tareas={tareasPendientes}
              color="#a855f7"
              icon="bi-clock-history"
              estadoActual="Pendiente"
              onCambiarEstado={confirmarCambioEstado}
              onCompletar={confirmarCompletarTarea}
              getPrioridadColor={getPrioridadColor}
            />

            {/* Tareas En Progreso */}
            <div className="mt-3">
              <SeccionTareas
                titulo="Tareas En Progreso"
                tareas={tareasEnProgreso}
                color="#7c3aed"
                icon="bi-arrow-repeat"
                estadoActual="En Progreso"
                onCambiarEstado={confirmarCambioEstado}
                onCompletar={confirmarCompletarTarea}
                getPrioridadColor={getPrioridadColor}
              />
            </div>
          </>
        )}
      </div>

      {/* Modal de Confirmación */}
      {showConfirmModal && confirmAction && (
        <div
          className="modal show d-block"
          style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
          onClick={() => setShowConfirmModal(false)}
        >
          <div
            className="modal-dialog modal-dialog-centered"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title fw-bold" style={{ color: "#6b2d9e" }}>
                  {confirmAction.type === "completar" ? (
                    <span>
                      <i className="bi bi-check-circle-fill text-success me-2"></i>
                      Completar Tarea
                    </span>
                  ) : (
                    <span>
                      <i className="bi bi-arrow-left-right me-2" style={{ color: "#7c3aed" }}></i>
                      Confirmar Cambio de Estado
                    </span>
                  )}
                </h5>
                <button
                  type="button"
                  className="btn-close"
                  onClick={() => setShowConfirmModal(false)}
                ></button>
              </div>
              <div className="modal-body">
                <p className="fw-medium mb-3" style={{ fontSize: "1rem" }}>{confirmAction.mensaje}</p>
                {confirmAction.descripcion && (
                  <p className="text-muted small mb-3">{confirmAction.descripcion}</p>
                )}
                {confirmAction.type === "completar" && (
                  <div className="alert alert-warning d-flex align-items-center mb-0">
                    <i className="bi bi-info-circle me-2"></i>
                    <small>Esto actualizará el stock automáticamente</small>
                  </div>
                )}
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowConfirmModal(false)}
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  className={`btn ${
                    confirmAction.type === "completar"
                      ? "btn-success"
                      : ""
                  }`}
                  style={
                    confirmAction.type !== "completar"
                      ? { backgroundColor: "#7c3aed", borderColor: "#7c3aed", color: "white" }
                      : {}
                  }
                  onClick={ejecutarAccion}
                  disabled={loading}
                >
                  {loading ? (
                    <>
                      <span className="spinner-border spinner-border-sm me-2"></span>
                      Procesando...
                    </>
                  ) : (
                    "Confirmar"
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Éxito */}
      {showSuccessModal && successData && (
        <div
          className="modal show d-block"
          style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
          onClick={() => setShowSuccessModal(false)}
        >
          <div
            className="modal-dialog modal-dialog-centered"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-content">
              <div className="modal-header bg-success text-white">
                <h5 className="modal-title">
                  <i className="bi bi-check-circle-fill me-2"></i>
                  ¡Producción Completada!
                </h5>
                <button
                  type="button"
                  className="btn-close btn-close-white"
                  onClick={() => setShowSuccessModal(false)}
                ></button>
              </div>
              <div className="modal-body">
                <div className="mb-3 pb-3 border-bottom">
                  <div className="d-flex justify-content-between mb-2">
                    <span className="text-muted">Producto:</span>
                    <span className="fw-bold">
                      {successData.producto?.nombre || "N/A"}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span className="text-muted">Cantidad Producida:</span>
                    <span className="fw-bold">
                      {successData.cantidadProducida} unidades
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span className="text-muted">Stock Anterior:</span>
                    <span className="fw-bold">{successData.stock?.anterior || 0}</span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span className="text-muted">Stock Nuevo:</span>
                    <span className="fw-bold text-success">
                      {successData.stock?.nuevo || 0}
                    </span>
                  </div>
                </div>
                <div className="alert alert-success mb-0">
                  <i className="bi bi-info-circle me-2"></i>
                  <small>El stock se ha actualizado automáticamente</small>
                </div>
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-success"
                  onClick={() => setShowSuccessModal(false)}
                >
                  Cerrar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Componente para cada sección de tareas
function SeccionTareas({
  titulo,
  tareas,
  color,
  icon,
  estadoActual,
  onCambiarEstado,
  onCompletar,
  getPrioridadColor,
}) {
  return (
    <div className="mb-3">
      {/* Header de la sección */}
      <div
        className="rounded-4 p-3 mb-3 d-flex justify-content-between align-items-center shadow-sm"
        style={{ backgroundColor: color }}
      >
        <div className="d-flex align-items-center">
          <i className={`bi ${icon} text-white fs-5 me-2`}></i>
          <h5 className="text-white mb-0 fw-bold" style={{ fontSize: "1.1rem", letterSpacing: "-0.3px" }}>{titulo}</h5>
        </div>
        <span
          className="badge rounded-pill px-3 py-2"
          style={{ backgroundColor: "rgba(255, 255, 255, 0.3)", fontSize: "0.95rem", fontWeight: "600" }}
        >
          {tareas.length}
        </span>
      </div>

      {/* Lista de tareas */}
      {tareas.length === 0 ? (
        <div
          className="text-center py-5 rounded-3"
          style={{ backgroundColor: "white", border: "2px dashed #e0e0e0" }}
        >
          <i className="bi bi-inbox" style={{ fontSize: "3.5rem", color: "#b0b0b0" }}></i>
          <p className="text-muted mt-3 mb-0 fw-medium">No hay tareas {estadoActual.toLowerCase()}</p>
        </div>
      ) : (
        <div>
          {tareas.map((tarea) => (
            <div key={tarea.idTarea} className="card shadow-sm mb-3 border-0" style={{ borderLeft: `4px solid ${color}` }}>
              <div className="card-body p-3">
                <div className="d-flex justify-content-between align-items-start mb-3">
                  <h6 className="mb-0 flex-grow-1 me-2 fw-medium" style={{ fontSize: "1rem", color: "#2c2c2c", lineHeight: "1.5" }}>
                    {tarea.Descripcion || "Sin descripción"}
                  </h6>
                  <span
                    className="badge rounded-pill px-3 py-1"
                    style={{
                      backgroundColor: getPrioridadColor(tarea.Prioridad),
                      color: "white",
                      fontSize: "0.8rem",
                      fontWeight: "600"
                    }}
                  >
                    {tarea.Prioridad || "Media"}
                  </span>
                </div>

                {/* Botones de acción */}
                <div className="d-grid">
                  {estadoActual === "Pendiente" && (
                    <button
                      className="btn shadow-sm"
                      style={{ 
                        backgroundColor: color, 
                        borderColor: color, 
                        color: "white",
                        padding: "0.65rem",
                        fontSize: "0.95rem",
                        fontWeight: "500"
                      }}
                      onClick={() =>
                        onCambiarEstado(
                          tarea.idTarea,
                          "Pendiente",
                          "En Progreso"
                        )
                      }
                    >
                      <i className="bi bi-play-fill me-1"></i>
                      Iniciar
                    </button>
                  )}

                  {estadoActual === "En Progreso" && (
                    <div className="d-flex gap-2">
                      <button
                        className="btn btn-outline-warning flex-grow-1 shadow-sm"
                        style={{ 
                          padding: "0.65rem",
                          fontSize: "0.95rem",
                          fontWeight: "500"
                        }}
                        onClick={() =>
                          onCambiarEstado(
                            tarea.idTarea,
                            "En Progreso",
                            "Pendiente"
                          )
                        }
                      >
                        <i className="bi bi-pause-fill me-1"></i>
                        Pausar
                      </button>
                      <button
                        className="btn btn-success flex-grow-1 shadow-sm"
                        style={{ 
                          padding: "0.65rem",
                          fontSize: "0.95rem",
                          fontWeight: "500"
                        }}
                        onClick={() =>
                          onCompletar(
                            tarea.idTarea,
                            tarea.Descripcion || "Sin descripción"
                          )
                        }
                      >
                        <i className="bi bi-check-circle-fill me-1"></i>
                        Completar
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}