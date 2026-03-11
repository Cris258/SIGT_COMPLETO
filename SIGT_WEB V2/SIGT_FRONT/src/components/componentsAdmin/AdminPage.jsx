import React, { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import ActualizarDatosModal from "../modalesCompartidos/ModalActualizarDatos";
import CambiarPasswordModal from "../modalesCompartidos/ModalCambiarPassword";
import axios from "axios";
import { Chart } from "chart.js/auto";
import reporteService from "../../services/reporteService";

const AdminPage = () => {
  const [usuario, setUsuario] = useState(null);
  const [empleados, setEmpleados] = useState([]);
  const [topEmpleados, setTopEmpleados] = useState([]);
  const [estadisticas, setEstadisticas] = useState(null);
  const [paginaActual, setPaginaActual] = useState(0);
  const POR_PAGINA = 10;
  const [loading, setLoading] = useState(true);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  const chartRef = useRef(null);
  const chartInstanceRef = useRef(null);

  useEffect(() => {
    const nombre = localStorage.getItem("Primer_Nombre");
    const apellido = localStorage.getItem("Primer_Apellido");
    if (nombre && apellido) setUsuario({ nombre, apellido });
  }, []);

  useEffect(() => {
    cargarDatos();
    return () => {
      if (chartInstanceRef.current) chartInstanceRef.current.destroy();
    };
  }, []);

  const cargarDatos = async () => {
    try {
      setLoading(true);
      setPaginaActual(0);
      const token = localStorage.getItem("token");
      const config = { headers: { Authorization: `Bearer ${token}` } };
      const API_URL = `${import.meta.env.VITE_API_URL}/api`;
      const resEmpleados = await axios.get(`${API_URL}/empleados-tareas`, config);
      setEmpleados(resEmpleados.data.data || []);
      const resTop = await axios.get(`${API_URL}/top-empleados`, config);
      setTopEmpleados(resTop.data.data || []);
      const resStats = await axios.get(`${API_URL}/estadisticas`, config);
      setEstadisticas({ general: resStats.data.data || [] });
      setLoading(false);
    } catch (error) {
      console.error("Error al cargar datos:", error);
      if (error.response?.status === 401) {
        alert("Sesión expirada. Por favor, inicia sesión nuevamente.");
      }
      setLoading(false);
    }
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarEmpleados();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  useEffect(() => {
    if (!estadisticas?.general?.length || loading) return;

    const timer = setTimeout(() => {
      const canvas = chartRef.current;
      if (!canvas) return;

      if (chartInstanceRef.current) {
        chartInstanceRef.current.destroy();
        chartInstanceRef.current = null;
      }

      const labels = estadisticas.general.map((item) => item.EstadoTarea);
      const data = estadisticas.general.map((item) => item.Cantidad);
      const colors = {
        Completada: "#54e075ff",
        "En Progreso": "#ffd965ff",
        Pendiente: "#ee5666ff",
        Cancelada: "#6c757d",
      };
      const backgroundColors = labels.map((label) => colors[label] || "#007bff");

      chartInstanceRef.current = new Chart(canvas, {
        type: "doughnut",
        data: {
          labels,
          datasets: [{
            data,
            backgroundColor: backgroundColors,
            borderWidth: 2,
            borderColor: "#fff",
          }],
        },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          plugins: {
            legend: {
              position: "bottom",
              labels: { padding: 15, font: { size: 12 } },
            },
            tooltip: {
              callbacks: {
                label: (context) => {
                  const label = context.label || "";
                  const value = context.parsed || 0;
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const percentage = ((value / total) * 100).toFixed(1);
                  return `${label}: ${value} (${percentage}%)`;
                },
              },
            },
          },
        },
      });
    }, 100);

    return () => clearTimeout(timer);
  }, [estadisticas, loading]);

  const calcularProgreso = (hechas, total) => {
    if (total === 0) return 0;
    return Math.round((hechas / total) * 100);
  };

  const getProgressBarClass = (progreso) => {
  if (progreso >= 75) return "bg-success";
  if (progreso >= 50) return "bg-info";
  if (progreso >= 25) return "bg-warning";
  return "bg-danger";
};
const getEstadoTareaColor = (estadoTarea) => {
  if (estadoTarea === "Completada") return "#54e075ff";
  if (estadoTarea === "En Progreso") return "#ffd965ff";
  if (estadoTarea === "Pendiente") return "#ee5666ff";
  return "#6c757d";
};

  return (
    <div>
      {/* BOTÓN HAMBURGUESA SOLO EN MÓVIL */}
      <nav className="navbar navbar-light d-md-none">
        <div className="container-fluid">
          <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#sidebarMenu">
            <span className="navbar-toggler-icon" />
          </button>
        </div>
      </nav>

      {/* CONTENEDOR PRINCIPAL */}
      <div className="d-flex flex-column text-white flex-md-row">
        {/* SIDEBAR */}
        <div className="sidebar collapse d-md-block p-3 text-white" id="sidebarMenu">
          <div className="text-center text-white mb-4">
            <i className="bi bi-person-circle" style={{ fontSize: "3rem" }} />
            <h5 className="fw-bold mt-2">
              {usuario ? `${usuario.nombre} ${usuario.apellido}` : "Panel de Control"}
            </h5>
          </div>
          <ul className="nav flex-column text-center text-white">
            <li className="nav-item">
              <a href="#" className="nav-link custom-link" data-bs-toggle="modal" data-bs-target="#modalActualizarDatos">Actualizar Datos</a>
            </li>
            <li className="nav-item">
              <a href="#" className="nav-link custom-link" data-bs-toggle="modal" data-bs-target="#modalCambiarPassword">Cambiar Contraseña</a>
            </li>
            <li className="nav-item">
              <Link to="/RegistroUsuarios" className="nav-link custom-link">Registro de Usuarios</Link>
            </li>
            <li className="nav-item">
              <Link to="/ListaUsuarios" className="nav-link custom-link">Listar Usuarios</Link>
            </li>
            <hr className="bg-light" />
            <li className="nav-item"><a href="admin" className="nav-link custom-link active">Empleados</a></li>
            <li className="nav-item"><a href="adminInventario" className="nav-link custom-link">Inventario</a></li>
            <li className="nav-item"><a href="AdminCliente" className="nav-link custom-link">Clientes</a></li>
            <hr className="bg-light" />
            <li className="nav-item"><a href="ListarEmpleados" className="nav-link custom-link">Administrar Empleados</a></li>
            <li className="nav-item"><a href="AsignarTareaAdmin" className="nav-link custom-link">Asignar Tarea</a></li>
            <li className="nav-item"><a href="ListarTareas" className="nav-link custom-link">Administrar Tareas</a></li>
          </ul>
        </div>

        {/* MAIN */}
        <main className="flex-grow-1 p-4 bg-light">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary" role="status">
                <span className="visually-hidden">Cargando...</span>
              </div>
              <p className="mt-2">Cargando datos...</p>
            </div>
          ) : (
            <>
              {/* TABLA PRINCIPAL */}
              <div className="row g-4 mb-4">
                <div className="col-12">
                  <div className="card shadow-sm">
                    <div className="card-header d-flex justify-content-between align-items-center">
                      <span className="fw-bold">
                        <i className="bi bi-people-fill me-2"></i>Empleados y Tareas
                      </span>
                      {/* BOTONES: ACTUALIZAR + GENERAR REPORTE */}
                      <div className="d-flex gap-2">
                        <button
                          className="btn btn-sm"
                          onClick={cargarDatos}
                          style={{ backgroundColor: "#7cbbe4ff", color: "black" }}
                        >
                          <i className="bi bi-arrow-clockwise me-1"></i>Actualizar
                        </button>
                        <button
                          className="btn btn-sm"
                          onClick={handleGenerarReporte}
                          disabled={generandoPDF}
                          style={{ backgroundColor: "#7cbbe4ff", color: "black" }}
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
                    <div className="card-body table-responsive">
                      {empleados.length === 0 ? (
                        <div className="alert alert-info text-center">
                          <i className="bi bi-info-circle me-2"></i>No hay empleados registrados
                        </div>
                      ) : (
                        <>
                          <table className="table table-hover table-bordered align-middle text-center">
                            <thead className="table-light">
                              <tr>
                                <th>#</th><th>Empleado</th><th>Rol</th>
                                <th>Tareas Hechas</th><th>Pendientes</th>
                                <th>Total</th><th>Progreso</th>
                              </tr>
                            </thead>
                            <tbody>
                              {empleados
                                .sort((a, b) => b.TotalTareas - a.TotalTareas)
                                .slice(paginaActual * POR_PAGINA, (paginaActual + 1) * POR_PAGINA)
                                .map((emp, index) => {
                                  const progreso = calcularProgreso(emp.TareasHechas, emp.TotalTareas);
                                  const numeroSecuencial = paginaActual * POR_PAGINA + index + 1;
                                  return (
                                    <tr key={emp.ID}>
                                      <td><strong>{numeroSecuencial}</strong></td>
                                      <td className="text-start">
                                        <i className="bi bi-person-badge me-2"></i>{emp.Empleado}
                                      </td>
                                      <td>{emp.Rol}</td>
                                      <td>
                                        <span style={{ backgroundColor: "#A8E6CF", padding: "4px 8px", borderRadius: "5px" }}>
                                          {emp.TareasHechas}
                                        </span>
                                      </td>
                                      <td>
                                        <span style={{ backgroundColor: "#FFB6B9", padding: "4px 8px", borderRadius: "5px" }}>
                                          {emp.Pendientes}
                                        </span>
                                      </td>
                                      <td><strong>{emp.TotalTareas}</strong></td>
                                      <td>
                                        <div className="progress mx-auto" style={{ width: "100px", height: "20px" }}>
                                          <div
                                            className={`progress-bar ${getProgressBarClass(progreso)}`}                                            role="progressbar"
                                            style={{ width: `${progreso}%` }}
                                          >
                                            {progreso}%
                                          </div>
                                        </div>
                                      </td>
                                    </tr>
                                  );
                                })}
                            </tbody>
                          </table>
                          {empleados.length > POR_PAGINA && (
                            <div className="d-flex justify-content-between align-items-center mt-3">
                              <button
                                className="btn btn-sm btn-outline-secondary"
                                onClick={() => setPaginaActual(Math.max(0, paginaActual - 1))}
                                disabled={paginaActual === 0}
                              >
                                <i className="bi bi-chevron-left"></i> Anterior
                              </button>
                              <span className="text-muted">
                                Página {paginaActual + 1} de {Math.ceil(empleados.length / POR_PAGINA)} ({empleados.length} empleados)
                              </span>
                              <button
                                className="btn btn-sm btn-outline-secondary"
                                onClick={() => setPaginaActual(Math.min(Math.ceil(empleados.length / POR_PAGINA) - 1, paginaActual + 1))}
                                disabled={paginaActual >= Math.ceil(empleados.length / POR_PAGINA) - 1}
                              >
                                Siguiente <i className="bi bi-chevron-right"></i>
                              </button>
                            </div>
                          )}
                        </>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* FILA 2: ESTADÍSTICAS, TOP Y CALENDARIO */}
              <div className="row g-3 align-items-stretch text-center">

                {/* ESTADÍSTICAS */}
                <div className="col-12 col-lg-4 d-flex flex-column mb-3">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-bar-chart-fill me-2"></i>Estadísticas de Tareas
                    </div>
                    <div className="card-body d-flex flex-column justify-content-center p-3">
                      {estadisticas?.general?.length > 0 ? (
                        <>
                          <div className="mb-3" style={{ maxWidth: "280px", margin: "0 auto" }}>
                            <canvas ref={chartRef}></canvas>
                          </div>
                          <div className="mt-2">
  <div className="row text-start g-2">
    {estadisticas.general.map((item) => (
      <div key={item.EstadoTarea} className="col-12">
        <div className="d-flex justify-content-between align-items-center p-2 rounded" style={{ backgroundColor: "#e2e7e7ff" }}>
          <span className="d-flex align-items-center">
            <i
              className="bi bi-circle-fill me-2"
              style={{
                color: getEstadoTareaColor(item.EstadoTarea),
                fontSize: "10px",
              }}
            ></i>
            <span className="small">{item.EstadoTarea}</span>
          </span>
          <span className="badge bg-secondary">{item.Cantidad}</span>
        </div>
      </div>
    ))}
  </div>
</div>
                        </>
                      ) : (
                        <div className="alert alert-secondary mb-0">
                          <i className="bi bi-exclamation-circle me-2"></i>No hay tareas registradas
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* TOP 5 EMPLEADOS */}
                <div className="col-12 col-lg-4 d-flex flex-column mb-3">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-trophy-fill me-2"></i>Top 5 Empleados
                    </div>
                    <div className="card-body p-2" style={{ overflowY: "auto", maxHeight: "400px" }}>
                      {topEmpleados.length === 0 ? (
                        <div className="alert alert-secondary mb-0">
                          <i className="bi bi-info-circle me-2"></i>No hay datos suficientes
                        </div>
                      ) : (
                        <ol className="list-group list-group-numbered">
                          {topEmpleados.map((emp, index) => (
                            <li key={emp.idPersona} className="list-group-item d-flex justify-content-between align-items-start p-2 mb-2">
                              <div className="ms-2 me-auto text-start w-100">
                                <div className="fw-bold d-flex align-items-center mb-1">
                                  {index === 0 && <i className="bi bi-trophy-fill text-warning me-1" style={{ fontSize: "1.1rem" }}></i>}
                                  {index === 1 && <i className="bi bi-award-fill text-secondary me-1"></i>}
                                  {index === 2 && <i className="bi bi-award-fill text-danger me-1" style={{ opacity: 0.7 }}></i>}
                                  <span style={{ fontSize: "1rem" }}>{emp.NombreEmpleado}</span>
                                </div>
                                <p className="text-muted mb-2" style={{ fontSize: "0.85rem" }}>{emp.NombreRol}</p>
                                <div className="d-flex flex-wrap gap-1">
                                  <span className="badge bg-success" style={{ fontSize: "0.78rem" }} title="Completadas">
                                    <i className="bi bi-check-circle"></i> {emp.TareasCompletadas}
                                  </span>
                                  <span className="badge bg-warning text-dark" style={{ fontSize: "0.78rem" }} title="En Progreso">
                                    <i className="bi bi-hourglass-split"></i> {emp.TareasEnProgreso}
                                  </span>
                                  <span className="badge bg-danger" style={{ fontSize: "0.78rem" }} title="Pendientes">
                                    <i className="bi bi-exclamation-circle"></i> {emp.TareasPendientes}
                                  </span>
                                </div>
                              </div>
                              <span className="badge bg-primary rounded-pill align-self-center" title="Score de Rendimiento" style={{ fontSize: "0.9rem" }}>
                                {emp.ScoreRendimiento}
                              </span>
                            </li>
                          ))}
                        </ol>
                      )}
                    </div>
                  </div>
                </div>

                {/* CALENDARIO */}
                <div className="col-12 col-lg-4 d-flex flex-column mb-3">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-calendar-event me-2"></i>Calendario
                    </div>
                    <div className="card-body p-0">
                      <iframe
                        src="https://calendar.google.com/calendar/embed?src=es.co%23holiday%40group.v.calendar.google.com&ctz=America%2FBogota&mode=MONTH&showTitle=0&showNav=1&showDate=1&showPrint=0&showTabs=0&showCalendars=0&showTz=0"
                        style={{ border: "0", borderRadius: "8px" }}
                        width="100%"
                        height="400"
                        frameBorder="0"
                        scrolling="no"
                        title="Calendario de Festivos Colombia"
                      ></iframe>
                    </div>
                  </div>
                </div>

              </div>
            </>
          )}
        </main>
      </div>

      <ActualizarDatosModal />
      <CambiarPasswordModal />
    </div>
  );
};

export default AdminPage;