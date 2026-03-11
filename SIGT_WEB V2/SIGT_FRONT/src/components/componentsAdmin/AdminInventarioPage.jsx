import React, { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import ActualizarDatosModal from "../modalesCompartidos/ModalActualizarDatos";
import CambiarPasswordModal from "../modalesCompartidos/ModalCambiarPassword";
import axios from "axios";
import { Chart } from "chart.js/auto";
import reporteService from "../../services/reporteService";

export default function AdminInventarioPage() {
  const [usuario, setUsuario] = useState(null);
  const [productos, setProductos] = useState([]);
  const [topProductos, setTopProductos] = useState([]);
  const [estadisticas, setEstadisticas] = useState(null);
  const [loading, setLoading] = useState(true);
  const [paginaActual, setPaginaActual] = useState(0);
  const [generandoPDF, setGenerandoPDF] = useState(false);
  const POR_PAGINA = 10;

  const chartRef = useRef(null);
  const chartInstanceRef = useRef(null);

  const colorMap = {
    rojo: "#ff0000", azul: "#0000ff", verde: "#00ff00", amarillo: "#ffff00",
    negro: "#000000", blanco: "#ffffff", gris: "#808080", rosa: "#ffc0cb",
    morado: "#800080", naranja: "#ffa500", cafe: "#8b4513", café: "#8b4513",
    beige: "#f5f5dc", celeste: "#87ceeb", turquesa: "#40e0d0", violeta: "#ee82ee",
    fucsia: "#ff00ff", marino: "#000080", vino: "#722f37", crema: "#fffdd0",
  };

  const getColorCode = (colorName) => {
    if (!colorName) return "#cccccc";
    const color = colorName.toLowerCase().trim();
    return colorMap[color] || colorName;
  };

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
      const API_URL = "${import.meta.env.VITE_API_URL}/api";
      const resProd = await axios.get(`${API_URL}/productos`, config);
      setProductos(resProd.data.data || []);
      const resTop = await axios.get(`${API_URL}/top-productos`, config);
      setTopProductos(resTop.data.data || []);
      const resStats = await axios.get(`${API_URL}/estadisticas-inventario`, config);
      setEstadisticas(resStats.data.data || null);
      setLoading(false);
    } catch (error) {
      console.error("Error al cargar inventario:", error);
      setLoading(false);
    }
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarInventario();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  useEffect(() => {
    if (!estadisticas?.porTalla || loading) return;

    const timer = setTimeout(() => {
      const canvas = chartRef.current;
      if (!canvas) return;

      if (chartInstanceRef.current) {
        chartInstanceRef.current.destroy();
        chartInstanceRef.current = null;
      }

      const labels = estadisticas.porTalla.map((t) => t.Talla);
      const data = estadisticas.porTalla.map((t) => t.Cantidad);

      chartInstanceRef.current = new Chart(canvas, {
        type: "doughnut",
        data: {
          labels,
          datasets: [{
            data,
            backgroundColor: ["#36a2eb", "#ff6384", "#ffcd56", "#4bc0c0", "#9966ff", "#ff9f40"],
            borderWidth: 2,
            borderColor: "#fff",
          }],
        },
        options: {
          responsive: true,
          plugins: {
            legend: { position: "bottom" },
            tooltip: {
              callbacks: {
                label: (context) => {
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const value = context.parsed || 0;
                  const perc = ((value / total) * 100).toFixed(1);
                  return `${context.label}: ${value} (${perc}%)`;
                },
              },
            },
          },
        },
      });
    }, 100);

    return () => clearTimeout(timer);
  }, [estadisticas, loading]);

  const totalPaginas = Math.ceil(productos.length / POR_PAGINA);
  const productosPagina = productos.slice(
    paginaActual * POR_PAGINA,
    (paginaActual + 1) * POR_PAGINA,
  );

  const getStockBadgeClass = (stock) => {
  if (stock > 10) return "bg-success";
  if (stock > 5) return "bg-warning";
  return "bg-danger";
};

  return (
    <div>
      <nav className="navbar navbar-light d-md-none">
        <div className="container-fluid">
          <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#sidebarMenu">
            <span className="navbar-toggler-icon"></span>
          </button>
        </div>
      </nav>

      <div className="d-flex flex-column text-white flex-md-row">
        {/* SIDEBAR */}
        <div className="sidebar collapse d-md-block p-3 text-white" id="sidebarMenu">
          <div className="text-center text-white mb-4">
            <i className="bi bi-person-circle" style={{ fontSize: "3rem" }} />
            <h5 className="fw-bold mt-2">
              {usuario ? `${usuario.nombre} ${usuario.apellido}` : "Administrador"}
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
            <li className="nav-item"><a href="admin" className="nav-link custom-link">Empleados</a></li>
            <li className="nav-item"><a href="adminInventario" className="nav-link custom-link active">Inventario</a></li>
            <li className="nav-item"><a href="AdminCliente" className="nav-link custom-link">Clientes</a></li>
            <hr className="bg-light" />
            <li className="nav-item"><a href="RegistroProductos" className="nav-link custom-link">Registro Productos</a></li>
            <li className="nav-item"><a href="ListarProductos" className="nav-link custom-link">Administrar Productos</a></li>
            <li className="nav-item"><a href="ListaMovimientos" className="nav-link custom-link">Lista Movimientos</a></li>
          </ul>
        </div>

        {/* MAIN */}
        <main className="flex-grow-1 p-4 bg-light">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary"></div>
              <p>Cargando inventario...</p>
            </div>
          ) : (
            <>
              {/* TABLA INVENTARIO */}
              <div className="card shadow-sm mb-4">
                <div className="card-header d-flex justify-content-between align-items-center">
                  <span className="fw-bold">
                    <i className="bi bi-box me-2"></i>Inventario de Pijamas
                  </span>
                  {/* BOTONES: ACTUALIZAR + GENERAR REPORTE */}
                  <div className="d-flex gap-2">
                    <button
                      className="btn btn-sm"
                      onClick={cargarDatos}
                      style={{ backgroundColor: "#7cbbe4", color: "black" }}
                    >
                      <i className="bi bi-arrow-clockwise me-1"></i>Actualizar
                    </button>
                    <button
                      className="btn btn-sm"
                      onClick={handleGenerarReporte}
                      disabled={generandoPDF}
                      style={{ backgroundColor: "#7cbbe4", color: "black" }}
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
                  {productos.length === 0 ? (
                    <div className="alert alert-info">No hay productos registrados</div>
                  ) : (
                    <>
                      <table className="table table-hover table-bordered text-center">
                        <thead className="table-light">
                          <tr>
                            <th>#</th>
                            <th>Producto</th>
                            <th>Color</th>
                            <th>Talla</th>
                            <th>Stock</th>
                            <th>Precio</th>
                          </tr>
                        </thead>
                        <tbody>
                          {productosPagina.map((prod, index) => (
                            <tr key={prod.ID}>
                              <td><strong>{paginaActual * POR_PAGINA + index + 1}</strong></td>
                              <td>{prod.Nombre}</td>
                              <td>
                                <div className="d-flex align-items-center justify-content-center gap-2">
                                  <div
                                    style={{
                                      width: "24px", height: "24px", borderRadius: "50%",
                                      backgroundColor: getColorCode(prod.Color),
                                      border: "2px solid #ddd", boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                                    }}
                                    title={prod.Color}
                                  ></div>
                                  <span className="small text-muted">{prod.Color}</span>
                                </div>
                              </td>
                              <td>{prod.Talla}</td>
                              <td>
                                  <span className={`badge ${getStockBadgeClass(prod.Stock)}`}>                                  {prod.Stock}
                                </span>
                              </td>
                              <td>${prod.Precio?.toLocaleString()}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>

                      {productos.length > POR_PAGINA && (
                        <div className="d-flex justify-content-between align-items-center mt-3">
                          <button
                            className="btn btn-sm btn-outline-secondary"
                            onClick={() => setPaginaActual(Math.max(0, paginaActual - 1))}
                            disabled={paginaActual === 0}
                          >
                            <i className="bi bi-chevron-left"></i> Anterior
                          </button>
                          <span className="text-muted">
                            Página {paginaActual + 1} de {totalPaginas} ({productos.length} productos)
                          </span>
                          <button
                            className="btn btn-sm btn-outline-secondary"
                            onClick={() => setPaginaActual(Math.min(totalPaginas - 1, paginaActual + 1))}
                            disabled={paginaActual >= totalPaginas - 1}
                          >
                            Siguiente <i className="bi bi-chevron-right"></i>
                          </button>
                        </div>
                      )}
                    </>
                  )}
                </div>
              </div>

              {/* ESTADÍSTICAS Y TOP */}
              <div className="row g-3">
                <div className="col-12 col-lg-4">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-bar-chart-fill me-2"></i>Estadísticas por Talla
                    </div>
                    <div className="card-body d-flex justify-content-center">
                      {estadisticas?.porTalla ? (
                        <canvas ref={chartRef} style={{ maxWidth: "280px" }}></canvas>
                      ) : (
                        <div className="alert alert-secondary">No hay estadísticas</div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="col-12 col-lg-4">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-trophy-fill me-2"></i>Top 5 Productos más Vendidos
                    </div>
                    <div className="card-body p-2">
                      {topProductos.length === 0 ? (
                        <div className="alert alert-secondary">No hay datos suficientes</div>
                      ) : (
                        <ol className="list-group list-group-numbered">
                          {topProductos.map((prod) => (
                            <li key={prod.ID} className="list-group-item d-flex justify-content-between">
                              <div>
                                <strong>{prod.Nombre}</strong>
                                <div className="small text-muted d-flex align-items-center gap-1">
                                  <div style={{
                                    width: "16px", height: "16px", borderRadius: "50%",
                                    backgroundColor: getColorCode(prod.Color),
                                    border: "1px solid #ddd", display: "inline-block",
                                  }}></div>
                                  {prod.Color} - {prod.Talla}
                                </div>
                              </div>
                              <span className="badge bg-info">{prod.UnidadesVendidas}</span>
                            </li>
                          ))}
                        </ol>
                      )}
                    </div>
                  </div>
                </div>

                <div className="col-12 col-lg-4">
                  <div className="card shadow-sm h-100">
                    <div className="card-header fw-bold">
                      <i className="bi bi-calendar-event me-2"></i>Calendario
                    </div>
                    <div className="card-body p-0">
                      <iframe
                        src="https://calendar.google.com/calendar/embed?src=es.co%23holiday%40group.v.calendar.google.com&ctz=America%2FBogota"
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
}