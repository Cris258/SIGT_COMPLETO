import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarTarea from "../componentesListas/ModalEditarTarea";
import ModalEliminarTarea from "../componentesListas/ModalEliminarTarea";
import reporteService from "../../services/reporteService";

const POR_PAGINA = 4;

export default function ListaTareas() {
  const [tareas, setTareas] = useState([]);
  const [empleados, setEmpleados] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tareaSeleccionada, setTareaSeleccionada] = useState(null);
  const [search, setSearch] = useState("");
  const [mostrarModalEditar, setMostrarModalEditar] = useState(false);
  const [mostrarModalEliminar, setMostrarModalEliminar] = useState(false);
  const [paginaActual, setPaginaActual] = useState(1);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  useEffect(() => {
    cargarDatos();
  }, []);

  const cargarDatos = async () => {
    const token = localStorage.getItem("token");
    try {
      const [resTareas, resPersonas] = await Promise.all([
        fetch(`${import.meta.env.VITE_API_URL}/api/tarea`, {
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        }),
        fetch(`${import.meta.env.VITE_API_URL}/api/persona`, {
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        }),
      ]);
      const dataTareas = await resTareas.json();
      const dataPersonas = await resPersonas.json();

      setTareas(dataTareas.body || []);
      setEmpleados(
        (dataPersonas.body || []).filter(
          (p) => p.Rol?.NombreRol?.toLowerCase() === "empleado"
        )
      );
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const cargarTareas = () => cargarDatos();

  const getNombreEmpleado = (id) => {
    const emp = empleados.find((e) => e.idPersona === id);
    if (!emp) return id || "N/A";
    return `${emp.Primer_Nombre || ""} ${emp.Primer_Apellido || ""}`.trim();
  };

  const abrirModalEditar = (tarea) => {
    setTareaSeleccionada(tarea);
    setMostrarModalEditar(true);
  };

  const cerrarModalEditar = () => {
    setMostrarModalEditar(false);
    setTareaSeleccionada(null);
  };

  const handleGuardarEdicion = (tareaActualizada) => {
    setTareas((prev) =>
      prev.map((t) =>
        t.idTarea === tareaActualizada.idTarea ? tareaActualizada : t
      )
    );
    cargarTareas();
  };

  const abrirModalEliminar = (tarea) => {
    setTareaSeleccionada(tarea);
    setMostrarModalEliminar(true);
  };

  const cerrarModalEliminar = () => {
    setMostrarModalEliminar(false);
    setTareaSeleccionada(null);
  };

  const handleConfirmarEliminacion = (tareaEliminada) => {
    setTareas((prev) =>
      prev.filter((t) => t.idTarea !== tareaEliminada.idTarea)
    );
    cargarTareas();
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarProduccion();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  const PRIORIDAD_ORDEN = { "Alta": 1, "Media": 2, "Baja": 3 };

  const tareasFiltradas = tareas
    .filter(
      (t) =>
        (t.Descripcion || "").toLowerCase().includes(search.toLowerCase()) ||
        (t.Prioridad || "").toLowerCase().includes(search.toLowerCase()) ||
        (t.EstadoTarea || "").toLowerCase().includes(search.toLowerCase())
    )
    .sort((a, b) => {
      const fechaA = a.FechaLimite ? new Date(a.FechaLimite) : new Date("9999-12-31");
      const fechaB = b.FechaLimite ? new Date(b.FechaLimite) : new Date("9999-12-31");
      if (fechaA - fechaB !== 0) return fechaA - fechaB;
      return (PRIORIDAD_ORDEN[a.Prioridad] ?? 99) - (PRIORIDAD_ORDEN[b.Prioridad] ?? 99);
    });

  const totalPaginas = Math.max(1, Math.ceil(tareasFiltradas.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const tareasPagina = tareasFiltradas.slice(inicio, inicio + POR_PAGINA);

  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando tareas...</p>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .lt-wrapper {
          padding: 40px 32px;
          min-height: 100vh;
        }

        .lt-card {
          background: rgba(253, 242, 255, 0.60);
          backdrop-filter: blur(14px);
          -webkit-backdrop-filter: blur(14px);
          border: 1.5px solid rgba(196, 140, 230, 0.22);
          border-radius: 20px;
          box-shadow: 0 8px 40px rgba(160, 80, 200, 0.12);
          overflow: hidden;
        }

        .lt-header {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          padding: 26px 32px 20px;
        }
        .lt-header h2 {
          color: #fff;
          font-weight: 700;
          font-size: 1.45rem;
          margin: 0 0 4px;
        }
        .lt-header p {
          color: rgba(255,255,255,0.80);
          margin: 0;
          font-size: 0.88rem;
        }
        .lt-counter {
          background: rgba(255,255,255,0.22);
          color: #fff;
          border-radius: 20px;
          padding: 4px 16px;
          font-size: 0.82rem;
          font-weight: 700;
          white-space: nowrap;
        }

        /* ── Botón reporte ── */
        .lt-btn-reporte {
          display: inline-flex;
          align-items: center;
          gap: 7px;
          background: linear-gradient(135deg, #f9a8d4 0%, #f472b6 100%);
          color: #6b1143;
          border: none;
          border-radius: 20px;
          padding: 6px 18px;
          font-size: 0.82rem;
          font-weight: 700;
          cursor: pointer;
          white-space: nowrap;
          box-shadow: 0 3px 12px rgba(244, 114, 182, 0.35);
          transition: opacity 0.2s, transform 0.15s, box-shadow 0.2s;
        }
        .lt-btn-reporte:hover:not(:disabled) {
          opacity: 0.92;
          transform: translateY(-1px);
          box-shadow: 0 5px 16px rgba(244, 114, 182, 0.50);
        }
        .lt-btn-reporte:disabled {
          opacity: 0.65;
          cursor: not-allowed;
        }
        .lt-btn-reporte .spinner-border {
          width: 13px;
          height: 13px;
          border-width: 2px;
        }

        .lt-filters {
          padding: 20px 24px 6px;
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          align-items: center;
        }
        .lt-search-wrap {
          position: relative;
          flex: 1;
        }
        .lt-search-icon {
          position: absolute;
          left: 13px;
          top: 50%;
          transform: translateY(-50%);
          color: #b06ac4;
          font-size: 1rem;
          pointer-events: none;
        }
        .lt-search {
          width: 100%;
          border: 1.8px solid #e8d0f8;
          border-radius: 10px;
          padding: 9px 14px 9px 40px;
          font-size: 0.93rem;
          background: rgba(255,255,255,0.75);
          color: #3d1a5c;
          outline: none;
          transition: border-color 0.2s, box-shadow 0.2s;
        }
        .lt-search:focus {
          border-color: #9b59b6;
          box-shadow: 0 0 0 3px rgba(155,89,182,0.14);
          background: #fff;
        }

        .lt-scroll {
          overflow-x: auto;
          padding: 16px 20px 28px;
        }
        .lt-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          font-size: 0.855rem;
        }
        .lt-table thead th {
          background: rgba(210, 160, 240, 0.18);
          color: #6a1b8a;
          font-weight: 700;
          font-size: 0.74rem;
          text-transform: uppercase;
          letter-spacing: 0.07em;
          padding: 11px 13px;
          border-bottom: 2px solid rgba(180, 110, 220, 0.22);
          white-space: nowrap;
        }
        .lt-table tbody tr {
          transition: background 0.15s;
        }
        .lt-table tbody tr:nth-child(even) {
          background: rgba(245, 220, 255, 0.20);
        }
        .lt-table tbody tr:hover {
          background: rgba(230, 190, 255, 0.32);
        }
        .lt-table tbody td {
          padding: 10px 13px;
          border-bottom: 1px solid rgba(210, 160, 240, 0.18);
          color: #2d1a40;
          vertical-align: middle;
          white-space: nowrap;
        }
        .lt-table tbody tr:last-child td {
          border-bottom: none;
        }

        .lt-chip-id {
          background: rgba(200, 140, 240, 0.18);
          color: #6a1b8a;
          border-radius: 6px;
          padding: 2px 10px;
          font-weight: 700;
          font-size: 0.8rem;
        }

        .lt-badge-alta { background: #fee2e2; color: #991b1b; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-badge-media { background: #fef9c3; color: #854d0e; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-badge-baja { background: #d1fae5; color: #065f46; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-badge-default { background: #f3f4f6; color: #6b7280; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-badge-alta::before, .lt-badge-media::before, .lt-badge-baja::before, .lt-badge-default::before { content: "●"; font-size: 0.55rem; }

        .lt-estado-completada { background: #d1fae5; color: #065f46; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-estado-progreso { background: #fef9c3; color: #854d0e; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-estado-pendiente { background: #fee2e2; color: #991b1b; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-estado-default { background: #f3f4f6; color: #6b7280; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lt-estado-completada::before, .lt-estado-progreso::before, .lt-estado-pendiente::before, .lt-estado-default::before { content: "●"; font-size: 0.55rem; }

        .lt-chip-emp { background: rgba(200, 140, 240, 0.15); color: #5b2182; border-radius: 6px; padding: 3px 10px; font-size: 0.8rem; font-weight: 600; display: inline-flex; align-items: center; gap: 5px; }

        .lt-btn-edit { background: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lt-btn-edit:hover { background: #dbeafe; border-color: #3b82f6; transform: scale(1.1); }
        .lt-btn-del { background: #fff5f5; border: 1.5px solid #fecaca; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lt-btn-del:hover { background: #fee2e2; border-color: #ef4444; transform: scale(1.1); }

        .lt-empty { text-align: center; padding: 52px 20px; }
        .lt-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .lt-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .lt-empty small { color: #c8a0e0; }

        .lt-pagination { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 0 24px 24px; flex-wrap: wrap; }
        .lt-page-info { text-align: center; font-size: 0.8rem; color: #9b59b6; font-weight: 600; padding: 0 24px 10px; }
        .lt-pg-btn { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-weight: 700; font-size: 0.85rem; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lt-pg-btn:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lt-pg-btn:disabled { opacity: 0.35; cursor: not-allowed; }
        .lt-pg-btn.active { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); border-color: #9b45c7; color: #fff; box-shadow: 0 3px 10px rgba(155,69,199,0.3); }
        .lt-pg-arrow { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-size: 1.1rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lt-pg-arrow:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lt-pg-arrow:disabled { opacity: 0.35; cursor: not-allowed; }
      `}</style>

      <div className="lt-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
          <div className="lt-card">

            {/* ── Header ── */}
            <div className="lt-header">
              <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                  <h2 className="merriweather-font">
                    <i className="bi bi-clipboard2-check-fill me-2"></i>
                    Lista de Tareas Asignadas
                  </h2>
                  <p>Gestiona, edita y elimina las tareas del sistema</p>
                </div>
                {/* CONTADOR + BOTÓN REPORTE */}
                <div className="d-flex align-items-center gap-2 flex-wrap">
                  <span className="lt-counter">
                    {tareasFiltradas.length} tarea{tareasFiltradas.length !== 1 ? "s" : ""}
                  </span>
                  <button
                    className="lt-btn-reporte"
                    onClick={handleGenerarReporte}
                    disabled={generandoPDF}
                  >
                    {generandoPDF ? (
                      <>
                        <span className="spinner-border" role="status" aria-hidden="true"></span>
                        Generando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-file-earmark-pdf-fill"></i>
                        Reporte Producción
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* ── Buscador ── */}
            <div className="lt-filters">
              <div className="lt-search-wrap">
                <i className="bi bi-search lt-search-icon"></i>
                <input
                  type="text"
                  className="lt-search"
                  placeholder="Buscar por descripción, prioridad, estado..."
                  value={search}
                  onChange={(e) => handleSearch(e.target.value)}
                />
              </div>
            </div>

            {/* ── Tabla ── */}
            <div className="lt-scroll">
              <table className="lt-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Descripción</th>
                    <th>Fecha Asignación</th>
                    <th>Fecha Límite</th>
                    <th>Prioridad</th>
                    <th>Estado</th>
                    <th>Empleado</th>
                    <th>Editar</th>
                    <th>Eliminar</th>
                  </tr>
                </thead>
                <tbody>
                  {tareasPagina.length > 0 ? (
                    tareasPagina.map((t, index) => (
                      <tr key={t.idTarea}>
                        <td><span className="lt-chip-id">{String(inicio + index + 1).padStart(3, "0")}</span></td>
                        <td className="text-start">{t.Descripcion}</td>
                        <td>
                          {t.FechaAsignacion
                            ? new Date(t.FechaAsignacion).toLocaleDateString("es-CO")
                            : "N/A"}
                        </td>
                        <td>
                          {t.FechaLimite
                            ? new Date(t.FechaLimite).toLocaleDateString("es-CO")
                            : "N/A"}
                        </td>
                        <td>
                          {(() => {
                            switch (t.Prioridad) {
                              case "Alta": return <span className="lt-badge-alta">Alta</span>;
                              case "Media": return <span className="lt-badge-media">Media</span>;
                              case "Baja": return <span className="lt-badge-baja">Baja</span>;
                              default: return <span className="lt-badge-default">{t.Prioridad || "N/A"}</span>;
                            }
                          })()}
                        </td>
                        <td>
                          {(() => {
                            switch (t.EstadoTarea) {
                              case "Completada": return <span className="lt-estado-completada">Completada</span>;
                              case "En Progreso": return <span className="lt-estado-progreso">En Progreso</span>;
                              case "Pendiente": return <span className="lt-estado-pendiente">Pendiente</span>;
                              default: return <span className="lt-estado-default">{t.EstadoTarea || "N/A"}</span>;
                            }
                          })()}
                        </td>
                        <td>
                          <span className="lt-chip-emp">
                            <i className="bi bi-person-fill" style={{ fontSize: "0.7rem" }}></i>
                            {getNombreEmpleado(t.Persona_FK)}
                          </span>
                        </td>
                        <td>
                          <button className="lt-btn-edit" onClick={() => abrirModalEditar(t)} title="Editar">
                            <img src="img/editar3.png" width="22" height="22" alt="Editar" />
                          </button>
                        </td>
                        <td>
                          <button className="lt-btn-del" onClick={() => abrirModalEliminar(t)} title="Eliminar">
                            <img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="9">
                        <div className="lt-empty">
                          <i className="bi bi-inbox"></i>
                          <p>{search ? "No se encontraron resultados" : "No hay tareas registradas"}</p>
                          {search && <small>Intenta con otro término de búsqueda</small>}
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* ── Paginador ── */}
            {totalPaginas > 1 && (
              <>
                <p className="lt-page-info">
                  Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, tareasFiltradas.length)} de {tareasFiltradas.length} tareas
                </p>
                <div className="lt-pagination">
                  <button className="lt-pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1} title="Primera">«</button>
                  <button className="lt-pg-arrow" onClick={() => setPaginaActual(p => p - 1)} disabled={paginaSegura === 1} title="Anterior">‹</button>

                  {Array.from({ length: totalPaginas }, (_, i) => i + 1)
                    .filter(n => n === 1 || n === totalPaginas || Math.abs(n - paginaSegura) <= 2)
                    .reduce((acc, n, i, arr) => {
                      if (i > 0 && n - arr[i - 1] > 1) acc.push("...");
                      acc.push(n);
                      return acc;
                    }, [])
                    .map((item, i) =>
                      item === "..." ? (
                        <span
                          key={`ellipsis-${i === 1 ? "start" : "end"}`}
                          style={{ color: "#b895d4", padding: "0 4px", lineHeight: "36px" }}
                        >
                          …
                        </span>) : (
                        <button
                          key={item}
                          className={`lt-pg-btn${paginaSegura === item ? " active" : ""}`}
                          onClick={() => setPaginaActual(item)}
                        >{item}</button>
                      )
                    )
                  }

                  <button className="lt-pg-arrow" onClick={() => setPaginaActual(p => p + 1)} disabled={paginaSegura === totalPaginas} title="Siguiente">›</button>
                  <button className="lt-pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas} title="Última">»</button>
                </div>
              </>
            )}

          </div>
        </div>
      </div>

      {mostrarModalEditar && (
        <ModalEditarTarea
          tarea={tareaSeleccionada}
          onClose={cerrarModalEditar}
          onGuardar={handleGuardarEdicion}
        />
      )}

      {mostrarModalEliminar && (
        <ModalEliminarTarea
          tarea={tareaSeleccionada}
          onClose={cerrarModalEliminar}
          onConfirmar={handleConfirmarEliminacion}
        />
      )}
    </>
  );
}