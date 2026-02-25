import React, { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

export default function ProduccionHistorial() {
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [tareasCompletadas, setTareasCompletadas] = useState([]);
  const [errorMessage, setErrorMessage] = useState(null);

  // Filtros
  const [filtroSeleccionado, setFiltroSeleccionado] = useState("Todos");
  const [searchQuery, setSearchQuery] = useState("");

  // Estadísticas
  const [estadisticas, setEstadisticas] = useState({
    total: 0,
    hoy: 0,
    semana: 0,
    mes: 0,
  });

  // Modal
  const [tareaSeleccionada, setTareaSeleccionada] = useState(null);
  const [showDetalleModal, setShowDetalleModal] = useState(false);

  useEffect(() => {
    cargarDatos();
  }, []);

  const cargarDatos = async () => {
    setInitialLoading(true);
    try {
      const token = localStorage.getItem("token");
      const idPersona = localStorage.getItem("idPersona");

      if (!token) {
        setErrorMessage("No se encontró token de autenticación");
        setInitialLoading(false);
        return;
      }

      if (!idPersona) {
        setErrorMessage("No se encontró información del usuario");
        setInitialLoading(false);
        return;
      }

      await cargarHistorial();
    } catch (error) {
      console.error("❌ Error al cargar datos:", error);
      setErrorMessage("Error al cargar datos");
    } finally {
      setInitialLoading(false);
    }
  };

  const cargarHistorial = async () => {
    setLoading(true);
    setErrorMessage(null);

    try {
      const token = localStorage.getItem("token");
      const idPersona = localStorage.getItem("idPersona");
      const API_URL = "http://localhost:3001/api";

      console.log("📡 Cargando historial de producción...");

      // Usar el endpoint específico del empleado
      const response = await fetch(`${API_URL}/tarea/empleado/${idPersona}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      console.log(`📡 Status: ${response.status}`);

      if (!response.ok) {
        throw new Error("Error al cargar historial");
      }

      const data = await response.json();
      console.log("📄 Datos recibidos:", data);

      const todasLasTareas = data.body || [];

      // Filtrar solo las tareas completadas
      let completadas = todasLasTareas.filter(
        (t) => t.EstadoTarea === "Completada"
      );

      // Cargar datos adicionales para cada tarea
      for (let tarea of completadas) {
        if (tarea.Producto_FK) {
          await cargarProducto(tarea);
        }
        await cargarProduccion(tarea);
      }

      // Ordenar por fecha de completado (más reciente primero)
      completadas.sort((a, b) => {
        const fechaA = new Date(a.updatedAt || new Date());
        const fechaB = new Date(b.updatedAt || new Date());
        return fechaB - fechaA;
      });

      calcularEstadisticas(completadas);
      setTareasCompletadas(completadas);

      console.log(
        `✅ Historial cargado: ${completadas.length} tareas completadas`
      );
    } catch (error) {
      console.error("❌ Error al cargar historial:", error);
      setErrorMessage("Error de conexión");
    } finally {
      setLoading(false);
    }
  };

  const cargarProducto = async (tarea) => {
    try {
      const token = localStorage.getItem("token");
      const API_URL = "http://localhost:3001/api";
      const productoId = tarea.Producto_FK;

      console.log(`📦 Cargando producto ${productoId}`);

      const response = await fetch(`${API_URL}/producto/${productoId}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (response.ok) {
        const data = await response.json();
        if (data.body) {
          tarea.Producto = data.body;
          console.log(
            `✅ Producto cargado: ${
              data.body.NombreProducto || data.body.Nombre || data.body.nombre
            }`
          );
        }
      } else {
        console.log(`⚠️ No se pudo cargar producto ${productoId}`);
        tarea.Producto = null;
      }
    } catch (error) {
      console.error("❌ Error al cargar producto:", error);
      tarea.Producto = null;
    }
  };

  const cargarProduccion = async (tarea) => {
    try {
      const token = localStorage.getItem("token");
      const API_URL = "http://localhost:3001/api";
      const tareaId = tarea.idTarea;

      const response = await fetch(
        `${API_URL}/produccion?Tarea_FK=${tareaId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        const producciones = data.body;

        if (producciones && producciones.length > 0) {
          const produccion = producciones[0];
          tarea.CantidadProducida = produccion.CantidadProducida;
          console.log(
            `✅ Producción cargada: ${produccion.CantidadProducida} unidades`
          );
        } else {
          tarea.CantidadProducida = 0;
        }
      } else {
        tarea.CantidadProducida = 0;
      }
    } catch (error) {
      console.error("❌ Error al cargar producción:", error);
      tarea.CantidadProducida = 0;
    }
  };

  const calcularEstadisticas = (tareas) => {
    const ahora = new Date();
    const hoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
    const inicioSemana = new Date(hoy);
    inicioSemana.setDate(hoy.getDate() - ahora.getDay() + 1);
    const inicioMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);

    let tareasHoy = 0;
    let tareasSemana = 0;
    let tareasMes = 0;

    tareas.forEach((tarea) => {
      const fechaCompletado = new Date(
        tarea.FechaCompletado || tarea.updatedAt
      );

      if (fechaCompletado >= hoy) {
        tareasHoy++;
      }
      if (fechaCompletado >= inicioSemana) {
        tareasSemana++;
      }
      if (fechaCompletado >= inicioMes) {
        tareasMes++;
      }
    });

    setEstadisticas({
      total: tareas.length,
      hoy: tareasHoy,
      semana: tareasSemana,
      mes: tareasMes,
    });
  };

  const aplicarFiltros = () => {
    let tareasFiltradas = [...tareasCompletadas];

    // Aplicar filtro de tiempo
    const ahora = new Date();
    switch (filtroSeleccionado) {
      case "Hoy":
        const hoy = new Date(
          ahora.getFullYear(),
          ahora.getMonth(),
          ahora.getDate()
        );
        tareasFiltradas = tareasFiltradas.filter((t) => {
          const fecha = new Date(t.FechaCompletado || t.updatedAt);
          return fecha >= hoy;
        });
        break;
      case "Esta Semana":
        const inicioSemana = new Date(ahora);
        inicioSemana.setDate(ahora.getDate() - ahora.getDay() + 1);
        tareasFiltradas = tareasFiltradas.filter((t) => {
          const fecha = new Date(t.FechaCompletado || t.updatedAt);
          return fecha >= inicioSemana;
        });
        break;
      case "Este Mes":
        const inicioMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
        tareasFiltradas = tareasFiltradas.filter((t) => {
          const fecha = new Date(t.FechaCompletado || t.updatedAt);
          return fecha >= inicioMes;
        });
        break;
      default:
        break;
    }

    // Aplicar búsqueda
    if (searchQuery.trim() !== "") {
      const query = searchQuery.toLowerCase();
      tareasFiltradas = tareasFiltradas.filter((t) => {
        const descripcion = (t.Descripcion || "").toLowerCase();
        const producto = (
          t.Producto?.NombreProducto ||
          t.Producto?.Nombre ||
          t.Producto?.nombre ||
          ""
        ).toLowerCase();
        return descripcion.includes(query) || producto.includes(query);
      });
    }

    return tareasFiltradas;
  };

  const formatearFecha = (fecha) => {
    if (!fecha) return "N/A";
    try {
      const dateTime = new Date(fecha);
      const ahora = new Date();
      const diferencia = Math.floor((ahora - dateTime) / (1000 * 60 * 60 * 24));

      if (diferencia === 0) {
        return `Hoy a las ${dateTime.toLocaleTimeString("es-CO", {
          hour: "2-digit",
          minute: "2-digit",
        })}`;
      } else if (diferencia === 1) {
        return `Ayer a las ${dateTime.toLocaleTimeString("es-CO", {
          hour: "2-digit",
          minute: "2-digit",
        })}`;
      } else if (diferencia < 7) {
        return `Hace ${diferencia} días`;
      } else {
        return dateTime.toLocaleString("es-CO", {
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
      }
    } catch {
      return "N/A";
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

  const abrirDetalles = (tarea) => {
    setTareaSeleccionada(tarea);
    setShowDetalleModal(true);
  };

  const tareasFiltradas = aplicarFiltros();

  if (initialLoading) {
    return (
      <div
        className="d-flex justify-content-center align-items-center"
        style={{ minHeight: "100vh", backgroundColor: "#f8f9fa" }}
      >
        <div className="text-center">
          <div
            className="spinner-border"
            role="status"
            style={{ width: "3rem", height: "3rem", color: "#7c3aed" }}
          >
            <span className="visually-hidden">Cargando...</span>
          </div>
          <p className="mt-3 fw-medium" style={{ color: "#6b2d9e" }}>
            Cargando historial...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: "#f8f9fa", minHeight: "100vh" }}>
      {/* Header */}
      <div className="bg-white shadow-sm sticky-top">
        <div className="container-fluid py-4 position-relative">
          <div className="text-center">
            <h2
              className="mb-0 fw-bold"
              style={{
                color: "#6b2d9e",
                fontSize: "2rem",
                letterSpacing: "-0.5px",
              }}
            >
              <i className="bi bi-clock-history me-2"></i>
              Historial de Producción
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
                padding: "0.5rem 1rem",
              }}
              onClick={cargarHistorial}
              disabled={loading}
            >
              <i className="bi bi-arrow-clockwise me-1"></i>
              Actualizar
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="py-4 px-3" style={{ maxWidth: "1200px", margin: "0 auto" }}>
        {errorMessage ? (
          <div className="text-center py-5">
            <i
              className="bi bi-exclamation-triangle"
              style={{ fontSize: "4rem", color: "#dc3545" }}
            ></i>
            <h4 className="mt-3" style={{ color: "#dc3545" }}>
              Error
            </h4>
            <p className="text-muted">{errorMessage}</p>
            <button
              className="btn shadow-sm"
              style={{
                backgroundColor: "#7c3aed",
                borderColor: "#7c3aed",
                color: "white",
              }}
              onClick={cargarHistorial}
            >
              <i className="bi bi-arrow-clockwise me-2"></i>
              Reintentar
            </button>
          </div>
        ) : (
          <>
            {/* Estadísticas */}
            <div
              className="card border-0 shadow-sm mb-4"
              style={{
                background: "linear-gradient(135deg, #7B2CBF 0%, #9D4EDD 100%)",
              }}
            >
              <div className="card-body p-4">
                <div className="d-flex align-items-center mb-4">
                  <i
                    className="bi bi-bar-chart text-white me-3"
                    style={{ fontSize: "1.8rem" }}
                  ></i>
                  <h5 className="text-white mb-0 fw-bold">
                    Resumen de Producción
                  </h5>
                </div>
                <div className="row g-3">
                  <div className="col-6 col-md-3">
                    <div
                      className="p-3 rounded-3 text-center"
                      style={{ backgroundColor: "rgba(255,255,255,0.2)" }}
                    >
                      <i
                        className="bi bi-check-circle"
                        style={{ fontSize: "2rem", color: "white" }}
                      ></i>
                      <h3 className="text-white fw-bold mt-2 mb-0">
                        {estadisticas.total}
                      </h3>
                      <small className="text-white" style={{ opacity: 0.9 }}>Total</small>
                    </div>
                  </div>
                  <div className="col-6 col-md-3">
                    <div
                      className="p-3 rounded-3 text-center"
                      style={{ backgroundColor: "rgba(255,255,255,0.2)" }}
                    >
                      <i
                        className="bi bi-calendar-day"
                        style={{ fontSize: "2rem", color: "white" }}
                      ></i>
                      <h3 className="text-white fw-bold mt-2 mb-0">
                        {estadisticas.hoy}
                      </h3>
                      <small className="text-white" style={{ opacity: 0.9 }}>Hoy</small>
                    </div>
                  </div>
                  <div className="col-6 col-md-3">
                    <div
                      className="p-3 rounded-3 text-center"
                      style={{ backgroundColor: "rgba(255,255,255,0.2)" }}
                    >
                      <i
                        className="bi bi-calendar-range"
                        style={{ fontSize: "2rem", color: "white" }}
                      ></i>
                      <h3 className="text-white fw-bold mt-2 mb-0">
                        {estadisticas.semana}
                      </h3>
                      <small className="text-white" style={{ opacity: 0.9 }}>Esta Semana</small>
                    </div>
                  </div>
                  <div className="col-6 col-md-3">
                    <div
                      className="p-3 rounded-3 text-center"
                      style={{ backgroundColor: "rgba(255,255,255,0.2)" }}
                    >
                      <i
                        className="bi bi-calendar-month"
                        style={{ fontSize: "2rem", color: "white" }}
                      ></i>
                      <h3 className="text-white fw-bold mt-2 mb-0">
                        {estadisticas.mes}
                      </h3>
                      <small className="text-white" style={{ opacity: 0.9 }}>Este Mes</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Filtros */}
            <div className="d-flex gap-2 mb-3 flex-wrap">
              {["Todos", "Hoy", "Esta Semana", "Este Mes"].map((filtro) => (
                <button
                  key={filtro}
                  className={`btn ${
                    filtroSeleccionado === filtro
                      ? "btn-primary"
                      : "btn-outline-secondary"
                  }`}
                  style={
                    filtroSeleccionado === filtro
                      ? {
                          backgroundColor: "#7B2CBF",
                          borderColor: "#7B2CBF",
                        }
                      : {}
                  }
                  onClick={() => setFiltroSeleccionado(filtro)}
                >
                  {filtro}
                </button>
              ))}
            </div>

            {/* Barra de búsqueda */}
            <div className="card border-0 shadow-sm mb-4">
              <div className="card-body">
                <div className="input-group">
                  <span className="input-group-text bg-white border-end-0">
                    <i className="bi bi-search"></i>
                  </span>
                  <input
                    type="text"
                    className="form-control border-start-0"
                    placeholder="Buscar por descripción o producto..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                  {searchQuery && (
                    <button
                      className="btn btn-outline-secondary"
                      onClick={() => setSearchQuery("")}
                    >
                      <i className="bi bi-x-lg"></i>
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* Lista de tareas */}
            {tareasFiltradas.length === 0 ? (
              <div
                className="card border-0 shadow-sm"
                style={{ backgroundColor: "#f8f9fa" }}
              >
                <div className="card-body text-center py-5">
                  <i
                    className="bi bi-inbox"
                    style={{ fontSize: "4rem", color: "#b0b0b0" }}
                  ></i>
                  <h4 className="mt-3 text-muted fw-medium">
                    No hay tareas completadas
                  </h4>
                  <p className="text-muted">
                    Completa tus primeras tareas de producción para ver el
                    historial aquí
                  </p>
                </div>
              </div>
            ) : (
              <>
                <p className="text-muted mb-3 fw-medium">
                  {tareasFiltradas.length}{" "}
                  {tareasFiltradas.length === 1 ? "tarea encontrada" : "tareas encontradas"}
                </p>
                {tareasFiltradas.map((tarea) => (
                  <div
                    key={tarea.idTarea}
                    className="card shadow-sm mb-3 border-0"
                    style={{
                      borderLeft: "4px solid #54e075",
                      cursor: "pointer",
                      transition: "all 0.3s ease",
                    }}
                    onClick={() => abrirDetalles(tarea)}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = "translateY(-4px)";
                      e.currentTarget.style.boxShadow =
                        "0 8px 16px rgba(0,0,0,0.1)";
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = "translateY(0)";
                      e.currentTarget.style.boxShadow = "";
                    }}
                  >
                    <div className="card-body p-3">
                      <div className="d-flex align-items-start">
                        <div
                          className="p-2 rounded-3 me-3"
                          style={{ backgroundColor: "#f0fef4" }}
                        >
                          <i
                            className="bi bi-check-circle"
                            style={{ fontSize: "1.5rem", color: "#54e075" }}
                          ></i>
                        </div>
                        <div className="flex-grow-1">
                          <div className="d-flex justify-content-between align-items-start mb-2">
                            <div className="flex-grow-1 me-2">
                              <h6
                                className="mb-1 fw-bold"
                                style={{ fontSize: "1.05rem" }}
                              >
                                {tarea.Descripcion || "Sin descripción"}
                              </h6>
                              <p
                                className="mb-1 text-muted"
                                style={{ fontSize: "0.9rem" }}
                              >
                                {tarea.Producto?.NombreProducto ||
                                  tarea.Producto?.Nombre ||
                                  tarea.Producto?.nombre ||
                                  "N/A"}
                              </p>
                              <span
                                className="badge px-2 py-1"
                                style={{
                                  backgroundColor: "#f0fef4",
                                  color: "#22c55e",
                                  fontSize: "0.75rem",
                                  border: "1px solid #bbf7d0",
                                }}
                              >
                                {tarea.EstadoTarea || "Completada"}
                              </span>
                            </div>
                            <span
                              className="badge px-3 py-2"
                              style={{
                                backgroundColor: getPrioridadColor(
                                  tarea.Prioridad
                                ),
                                color: "white",
                                fontSize: "0.75rem",
                              }}
                            >
                              {tarea.Prioridad || "Media"}
                            </span>
                          </div>
                          <hr className="my-2" />
                          <div className="d-flex justify-content-between align-items-center text-muted">
                            <small>
                              <i className="bi bi-box-seam me-1"></i>
                              {tarea.CantidadProducida || 0} unidades
                            </small>
                            <small>
                              <i className="bi bi-clock me-1"></i>
                              {formatearFecha(
                                tarea.FechaCompletado || tarea.updatedAt
                              )}
                            </small>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </>
            )}
          </>
        )}
      </div>

      {/* Modal de Detalles */}
      {showDetalleModal && tareaSeleccionada && (
        <div
          className="modal show d-block"
          style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
          onClick={() => setShowDetalleModal(false)}
        >
          <div
            className="modal-dialog modal-dialog-centered modal-dialog-scrollable"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-content">
              <div
                className="modal-header"
                style={{ backgroundColor: "#7c3aed" }}
              >
                <h5 className="modal-title text-white fw-bold">
                  <i className="bi bi-info-circle-fill me-2"></i>
                  Detalles de Producción
                </h5>
                <button
                  type="button"
                  className="btn-close btn-close-white"
                  onClick={() => setShowDetalleModal(false)}
                ></button>
              </div>
              <div className="modal-body">
                <DetailRow
                  icon="bi-file-text"
                  label="Descripción"
                  value={
                    tareaSeleccionada.Descripcion || "Sin descripción"
                  }
                />
                <hr />

                <DetailRow
                  icon="bi-box-seam"
                  label="Producto"
                  value={
                    tareaSeleccionada.Producto?.NombreProducto ||
                    tareaSeleccionada.Producto?.Nombre ||
                    tareaSeleccionada.Producto?.nombre ||
                    "N/A"
                  }
                />

                {tareaSeleccionada.Producto && (
                  <div className="row g-2 mb-3">
                    {tareaSeleccionada.Producto.Color && (
                      <div className="col-6">
                        <DetailRow
                          icon="bi-palette"
                          label="Color"
                          value={tareaSeleccionada.Producto.Color}
                          small
                        />
                      </div>
                    )}
                    {tareaSeleccionada.Producto.Talla && (
                      <div className="col-6">
                        <DetailRow
                          icon="bi-rulers"
                          label="Talla"
                          value={tareaSeleccionada.Producto.Talla}
                          small
                        />
                      </div>
                    )}
                  </div>
                )}

                {tareaSeleccionada.Producto?.Estampado && (
                  <DetailRow
                    icon="bi-stars"
                    label="Estampado"
                    value={tareaSeleccionada.Producto.Estampado}
                    small
                  />
                )}

                <hr />

                <DetailRow
                  icon="bi-check-circle"
                  label="Estado"
                  value={tareaSeleccionada.EstadoTarea || "Completada"}
                  valueColor="#22c55e"
                />

                <DetailRow
                  icon="bi-box-seam"
                  label="Cantidad Producida"
                  value={`${tareaSeleccionada.CantidadProducida || 0} unidades`}
                />

                <DetailRow
                  icon="bi-exclamation-circle"
                  label="Prioridad"
                  value={tareaSeleccionada.Prioridad || "Media"}
                  valueColor={getPrioridadColor(tareaSeleccionada.Prioridad)}
                />

                <hr />

                <DetailRow
                  icon="bi-calendar-check"
                  label="Completado"
                  value={formatearFecha(
                    tareaSeleccionada.FechaCompletado ||
                      tareaSeleccionada.updatedAt
                  )}
                  valueColor="#22c55e"
                />
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowDetalleModal(false)}
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

// Componente auxiliar para mostrar detalles
function DetailRow({ icon, label, value, valueColor, small }) {
  return (
    <div className={`mb-3 ${small ? "mb-2" : ""}`}>
      <div className="d-flex align-items-start">
        <i
          className={`bi ${icon} me-2 text-muted`}
          style={{ fontSize: small ? "1rem" : "1.2rem" }}
        ></i>
        <div className="flex-grow-1">
          <small
            className="text-muted d-block fw-bold"
            style={{ fontSize: small ? "0.75rem" : "0.85rem" }}
          >
            {label}
          </small>
          <span
            className="fw-medium"
            style={{
              color: valueColor || "#2c2c2c",
              fontSize: small ? "0.9rem" : "1rem",
            }}
          >
            {value}
          </span>
        </div>
      </div>
    </div>
  );
}