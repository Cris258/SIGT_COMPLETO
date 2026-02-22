import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarCarrito from "../componentesListas/ModalEditarCarrito";
import ModalEliminarCarrito from "../componentesListas/ModalEliminarCarrito";
import reporteService from "../../services/reporteService";

const POR_PAGINA = 4;

export default function ListaCarritos() {
  const [carritos, setCarritos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [carritoSeleccionado, setCarritoSeleccionado] = useState(null);
  const [search, setSearch] = useState("");
  const [mostrarModalEditar, setMostrarModalEditar] = useState(false);
  const [mostrarModalEliminar, setMostrarModalEliminar] = useState(false);
  const [carritoExpandido, setCarritoExpandido] = useState(null);
  const [detallesCarrito, setDetallesCarrito] = useState({});
  const [paginaActual, setPaginaActual] = useState(1);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  useEffect(() => {
    cargarCarritos();
  }, []);

  const cargarCarritos = async () => {
    const token = localStorage.getItem("token");
    try {
      const res = await fetch("http://localhost:3001/api/carrito", {
        method: "GET",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      });
      if (!res.ok) throw new Error("Error al obtener carritos");
      const data = await res.json();
      const carritosConCliente = await Promise.all(
        data.body.map(async (carrito) => {
          try {
            const resPersona = await fetch(
              `http://localhost:3001/api/persona/${carrito.Persona_FK}`,
              { headers: { Authorization: `Bearer ${token}` } },
            );
            if (resPersona.ok) {
              const personaData = await resPersona.json();
              carrito.Persona = personaData.body;
            }
          } catch (err) {
            console.error("Error cargando cliente:", err);
          }
          return carrito;
        }),
      );
      setCarritos(carritosConCliente);
      setLoading(false);
    } catch (err) {
      console.error(err);
      setLoading(false);
    }
  };

  const cargarDetallesCarrito = async (idCarrito) => {
    if (detallesCarrito[idCarrito]) {
      setCarritoExpandido(carritoExpandido === idCarrito ? null : idCarrito);
      return;
    }
    const token = localStorage.getItem("token");
    try {
      const response = await fetch(
        `http://localhost:3001/api/detallecarrito/carrito/${idCarrito}`,
        { method: "GET", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } },
      );
      if (response.ok) {
        const data = await response.json();
        setDetallesCarrito((prev) => ({ ...prev, [idCarrito]: data.body }));
        setCarritoExpandido(idCarrito);
      }
    } catch (error) {
      console.error("Error al cargar detalles:", error);
    }
  };

  const abrirModalEditar = (carrito) => { setCarritoSeleccionado(carrito); setMostrarModalEditar(true); };
  const cerrarModalEditar = () => { setMostrarModalEditar(false); setCarritoSeleccionado(null); };
  const handleGuardarEdicion = (carritoActualizado) => {
    setCarritos((prev) => prev.map((c) => c.idCarrito === carritoActualizado.idCarrito ? carritoActualizado : c));
  };
  const abrirModalEliminar = (carrito) => { setCarritoSeleccionado(carrito); setMostrarModalEliminar(true); };
  const cerrarModalEliminar = () => { setMostrarModalEliminar(false); setCarritoSeleccionado(null); };
  const handleConfirmarEliminacion = (carritoEliminado) => {
    setCarritos((prev) => prev.filter((c) => c.idCarrito !== carritoEliminado.idCarrito));
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarCarritosAbandonados();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  const formatearFecha = (fecha) =>
    new Date(fecha).toLocaleDateString("es-CO", {
      year: "numeric", month: "short", day: "numeric",
      hour: "2-digit", minute: "2-digit",
    });

  const carritosFiltrados = carritos.filter(
    (c) =>
      (c.idCarrito?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Estado || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Persona_FK?.toString() || "").toLowerCase().includes(search.toLowerCase()),
  );

  const totalPaginas = Math.max(1, Math.ceil(carritosFiltrados.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const carritosPagina = carritosFiltrados.slice(inicio, inicio + POR_PAGINA);
  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando carritos...</p>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .lcar-wrapper { padding: 40px 32px; min-height: 100vh; }
        .lcar-card { background: rgba(253,242,255,0.60); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); border: 1.5px solid rgba(196,140,230,0.22); border-radius: 20px; box-shadow: 0 8px 40px rgba(160,80,200,0.12); overflow: hidden; }
        .lcar-header { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); padding: 26px 32px 20px; }
        .lcar-header h2 { color: #fff; font-weight: 700; font-size: 1.45rem; margin: 0 0 4px; }
        .lcar-header p { color: rgba(255,255,255,0.80); margin: 0; font-size: 0.88rem; }
        .lcar-counter { background: rgba(255,255,255,0.22); color: #fff; border-radius: 20px; padding: 4px 16px; font-size: 0.82rem; font-weight: 700; white-space: nowrap; }

        /* ── Botón reporte rosado ── */
        .lcar-btn-reporte {
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
          box-shadow: 0 3px 12px rgba(244,114,182,0.35);
          transition: opacity 0.2s, transform 0.15s, box-shadow 0.2s;
        }
        .lcar-btn-reporte:hover:not(:disabled) { opacity: 0.92; transform: translateY(-1px); box-shadow: 0 5px 16px rgba(244,114,182,0.50); }
        .lcar-btn-reporte:disabled { opacity: 0.65; cursor: not-allowed; }
        .lcar-btn-reporte .lcar-spinner-sm { width: 13px; height: 13px; border: 2px solid rgba(107,17,67,0.3); border-top-color: #6b1143; border-radius: 50%; animation: lcar-spin 0.7s linear infinite; }
        @keyframes lcar-spin { to { transform: rotate(360deg); } }

        .lcar-filters { padding: 20px 24px 6px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
        .lcar-search-wrap { position: relative; flex: 1; }
        .lcar-search-icon { position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: #b06ac4; font-size: 1rem; pointer-events: none; }
        .lcar-search { width: 100%; border: 1.8px solid #e8d0f8; border-radius: 10px; padding: 9px 14px 9px 40px; font-size: 0.93rem; background: rgba(255,255,255,0.75); color: #3d1a5c; outline: none; transition: border-color 0.2s, box-shadow 0.2s; }
        .lcar-search:focus { border-color: #9b59b6; box-shadow: 0 0 0 3px rgba(155,89,182,0.14); background: #fff; }
        .lcar-scroll { overflow-x: auto; padding: 16px 20px 8px; }
        .lcar-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 0.855rem; }
        .lcar-table thead th { background: rgba(210,160,240,0.18); color: #6a1b8a; font-weight: 700; font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.07em; padding: 11px 13px; border-bottom: 2px solid rgba(180,110,220,0.22); white-space: nowrap; }
        .lcar-table tbody tr { transition: background 0.15s; }
        .lcar-table tbody tr:nth-child(even) { background: rgba(245,220,255,0.20); }
        .lcar-table tbody tr:hover { background: rgba(230,190,255,0.32); }
        .lcar-table tbody td { padding: 10px 13px; border-bottom: 1px solid rgba(210,160,240,0.18); color: #2d1a40; vertical-align: middle; white-space: nowrap; }
        .lcar-table tbody tr:last-child td { border-bottom: none; }
        .lcar-chip-id { background: rgba(200,140,240,0.18); color: #6a1b8a; border-radius: 6px; padding: 2px 10px; font-weight: 700; font-size: 0.8rem; }
        .lcar-badge-pagado { background: #d1fae5; color: #065f46; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lcar-badge-pendiente { background: #fef9c3; color: #854d0e; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lcar-badge-cancelado { background: #fee2e2; color: #991b1b; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lcar-badge-otro { background: #f3f4f6; color: #6b7280; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lcar-badge-pagado::before, .lcar-badge-pendiente::before, .lcar-badge-cancelado::before, .lcar-badge-otro::before { content: "●"; font-size: 0.55rem; }
        .lcar-btn-eye { background: #f0f9ff; border: 1.5px solid #bae6fd; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; align-items: center; color: #0369a1; font-size: 1rem; }
        .lcar-btn-eye:hover { background: #e0f2fe; border-color: #0284c7; transform: scale(1.1); }
        .lcar-btn-edit { background: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lcar-btn-edit:hover { background: #dbeafe; border-color: #3b82f6; transform: scale(1.1); }
        .lcar-btn-del { background: #fff5f5; border: 1.5px solid #fecaca; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lcar-btn-del:hover { background: #fee2e2; border-color: #ef4444; transform: scale(1.1); }
        .lcar-detalle-row td { background: rgba(243,232,255,0.40) !important; }
        .lcar-detalle-inner { background: rgba(255,255,255,0.7); border-radius: 12px; border: 1px solid rgba(196,140,230,0.25); overflow: hidden; margin: 4px 0; }
        .lcar-detalle-inner table { width: 100%; border-collapse: collapse; font-size: 0.82rem; }
        .lcar-detalle-inner thead th { background: rgba(200,140,240,0.18); color: #6a1b8a; padding: 8px 12px; font-weight: 700; font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .lcar-detalle-inner tbody td { padding: 8px 12px; border-top: 1px solid rgba(210,160,240,0.15); color: #2d1a40; }
        .lcar-detalle-title { color: #6a1b8a; font-weight: 700; font-size: 0.9rem; margin-bottom: 10px; display: flex; align-items: center; gap: 6px; }
        .lcar-empty { text-align: center; padding: 52px 20px; }
        .lcar-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .lcar-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .lcar-empty small { color: #c8a0e0; }
        .lcar-page-info { text-align: center; font-size: 0.8rem; color: #9b59b6; font-weight: 600; padding: 0 24px 10px; }
        .lcar-pagination { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 0 24px 24px; flex-wrap: wrap; }
        .lcar-pg-btn { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-weight: 700; font-size: 0.85rem; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lcar-pg-btn:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lcar-pg-btn:disabled { opacity: 0.35; cursor: not-allowed; }
        .lcar-pg-btn.active { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); border-color: #9b45c7; color: #fff; box-shadow: 0 3px 10px rgba(155,69,199,0.3); }
        .lcar-pg-arrow { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-size: 1.1rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lcar-pg-arrow:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lcar-pg-arrow:disabled { opacity: 0.35; cursor: not-allowed; }
      `}</style>

      <div className="lcar-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
          <div className="lcar-card">

            {/* ── Header ── */}
            <div className="lcar-header">
              <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                  <h2 className="merriweather-font">
                    <i className="bi bi-cart3 me-2"></i>Lista de Carritos Registrados
                  </h2>
                  <p>Gestiona, edita y elimina los carritos del sistema</p>
                </div>
                {/* CONTADOR + BOTÓN REPORTE */}
                <div className="d-flex align-items-center gap-2 flex-wrap">
                  <span className="lcar-counter">
                    {carritosFiltrados.length} carrito{carritosFiltrados.length !== 1 ? "s" : ""}
                  </span>
                  <button
                    className="lcar-btn-reporte"
                    onClick={handleGenerarReporte}
                    disabled={generandoPDF}
                  >
                    {generandoPDF ? (
                      <>
                        <div className="lcar-spinner-sm" />
                        Generando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-file-earmark-pdf-fill"></i>
                        Reporte Carritos
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* ── Buscador ── */}
            <div className="lcar-filters">
              <div className="lcar-search-wrap">
                <i className="bi bi-search lcar-search-icon"></i>
                <input
                  type="text"
                  className="lcar-search"
                  placeholder="Buscar por ID, estado, cliente..."
                  value={search}
                  onChange={(e) => handleSearch(e.target.value)}
                />
              </div>
            </div>

            {/* ── Tabla ── */}
            <div className="lcar-scroll">
              <table className="lcar-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Fecha Creación</th>
                    <th>Estado</th>
                    <th>Cliente</th>
                    <th>Ver Detalles</th>
                    <th>Editar</th>
                    <th>Eliminar</th>
                  </tr>
                </thead>
                <tbody>
                  {carritosPagina.length > 0 ? (
                    carritosPagina.map((c, index) => (
                      <>
                        <tr key={c.idCarrito}>
                          <td><span className="lcar-chip-id">{inicio + index + 1}</span></td>
                          <td>{formatearFecha(c.FechaCreacion)}</td>
                          <td>
                            {c.Estado === "Pagado" && <span className="lcar-badge-pagado">Pagado</span>}
                            {c.Estado === "Pendiente" && <span className="lcar-badge-pendiente">Pendiente</span>}
                            {c.Estado === "Cancelado" && <span className="lcar-badge-cancelado">Cancelado</span>}
                            {!["Pagado", "Pendiente", "Cancelado"].includes(c.Estado) && (
                              <span className="lcar-badge-otro">{c.Estado}</span>
                            )}
                          </td>
                          <td style={{ fontWeight: 600, color: "#3d1a5c" }}>
                            {c.Persona ? `${c.Persona.Primer_Nombre} ${c.Persona.Primer_Apellido}` : "Cliente no disponible"}
                          </td>
                          <td>
                            <button className="lcar-btn-eye" onClick={() => cargarDetallesCarrito(c.idCarrito)} title="Ver detalles">
                              <i className={`bi ${carritoExpandido === c.idCarrito ? "bi-eye-slash" : "bi-eye"}`}></i>
                            </button>
                          </td>
                          <td>
                            <button className="lcar-btn-edit" onClick={() => abrirModalEditar(c)} title="Editar">
                              <img src="img/editar3.png" width="22" height="22" alt="Editar" />
                            </button>
                          </td>
                          <td>
                            <button className="lcar-btn-del" onClick={() => abrirModalEliminar(c)} title="Eliminar">
                              <img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" />
                            </button>
                          </td>
                        </tr>
                        {carritoExpandido === c.idCarrito && detallesCarrito[c.idCarrito] && (
                          <tr className="lcar-detalle-row">
                            <td colSpan="7" style={{ padding: "12px 20px 16px" }}>
                              <div className="lcar-detalle-title">
                                <i className="bi bi-box-seam"></i>Productos del Carrito #{c.idCarrito}
                              </div>
                              <div className="lcar-detalle-inner">
                                <table>
                                  <thead>
                                    <tr>
                                      <th>Nombre Producto</th>
                                      <th>Color</th>
                                      <th>Talla</th>
                                      <th>Cantidad</th>
                                      <th>Precio</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {detallesCarrito[c.idCarrito].map((detalle) => (
                                      <tr key={detalle.idDetalleCarrito}>
                                        <td>{detalle.Producto?.NombreProducto || "Producto no disponible"}</td>
                                        <td>{detalle.Producto?.Color || "N/A"}</td>
                                        <td>{detalle.Producto?.Talla || "N/A"}</td>
                                        <td>{detalle.Cantidad}</td>
                                        <td style={{ fontWeight: 600, color: "#7c3aad" }}>
                                          {detalle.Producto?.Precio ? `$${detalle.Producto.Precio.toLocaleString()}` : "N/A"}
                                        </td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>
                            </td>
                          </tr>
                        )}
                      </>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="7">
                        <div className="lcar-empty">
                          <i className="bi bi-inbox"></i>
                          <p>{search ? "No se encontraron resultados" : "No hay carritos registrados"}</p>
                          {search && <small>Intenta con otro término</small>}
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
                <p className="lcar-page-info">
                  Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, carritosFiltrados.length)} de {carritosFiltrados.length} carritos
                </p>
                <div className="lcar-pagination">
                  <button className="lcar-pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1}>«</button>
                  <button className="lcar-pg-arrow" onClick={() => setPaginaActual((p) => p - 1)} disabled={paginaSegura === 1}>‹</button>
                  {Array.from({ length: totalPaginas }, (_, i) => i + 1)
                    .filter((n) => n === 1 || n === totalPaginas || Math.abs(n - paginaSegura) <= 2)
                    .reduce((acc, n, i, arr) => {
                      if (i > 0 && n - arr[i - 1] > 1) acc.push("...");
                      acc.push(n);
                      return acc;
                    }, [])
                    .map((item, i) =>
                      item === "..." ? (
                        <span key={`d${i}`} style={{ color: "#b895d4", padding: "0 4px", lineHeight: "36px" }}>…</span>
                      ) : (
                        <button key={item} className={`lcar-pg-btn${paginaSegura === item ? " active" : ""}`} onClick={() => setPaginaActual(item)}>
                          {item}
                        </button>
                      ),
                    )}
                  <button className="lcar-pg-arrow" onClick={() => setPaginaActual((p) => p + 1)} disabled={paginaSegura === totalPaginas}>›</button>
                  <button className="lcar-pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas}>»</button>
                </div>
              </>
            )}

          </div>
        </div>
      </div>

      {mostrarModalEditar && (
        <ModalEditarCarrito carrito={carritoSeleccionado} onClose={cerrarModalEditar} onGuardar={handleGuardarEdicion} />
      )}
      {mostrarModalEliminar && (
        <ModalEliminarCarrito carrito={carritoSeleccionado} onClose={cerrarModalEliminar} onConfirmar={handleConfirmarEliminacion} />
      )}
    </>
  );
}