import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarVenta from "../componentesListas/ModalEditarVenta";
import ModalEliminarVenta from "../componentesListas/ModalEliminarVenta";
import reporteService from "../../services/reporteService";

const POR_PAGINA = 4;

export default function ListaVentas() {
  const [ventas, setVentas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [ventaSeleccionada, setVentaSeleccionada] = useState(null);
  const [search, setSearch] = useState("");
  const [mostrarModalEditar, setMostrarModalEditar] = useState(false);
  const [mostrarModalEliminar, setMostrarModalEliminar] = useState(false);
  const [ventaExpandida, setVentaExpandida] = useState(null);
  const [detallesVenta, setDetallesVenta] = useState({});
  const [paginaActual, setPaginaActual] = useState(1);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  useEffect(() => {
    cargarVentas();
  }, []);

  const cargarVentas = async () => {
    const token = localStorage.getItem("token");
    try {
      const res = await fetch("http://localhost:3001/api/venta", {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });
      if (!res.ok) throw new Error("Error al obtener ventas");
      const data = await res.json();
      const ventasConCliente = await Promise.all(
        data.body.map(async (venta) => {
          try {
            const resPersona = await fetch(
              `http://localhost:3001/api/persona/${venta.Persona_FK}`,
              { headers: { Authorization: `Bearer ${token}` } },
            );
            if (resPersona.ok) {
              const personaData = await resPersona.json();
              venta.Persona = personaData.body;
            }
          } catch (err) {
            console.error("Error cargando cliente:", err);
          }
          return venta;
        }),
      );
      setVentas(ventasConCliente);
      setLoading(false);
    } catch (err) {
      console.error(err);
      setLoading(false);
    }
  };

  const cargarDetallesVenta = async (idVenta) => {
    if (detallesVenta[idVenta]) {
      setVentaExpandida(ventaExpandida === idVenta ? null : idVenta);
      return;
    }
    const token = localStorage.getItem("token");
    try {
      const response = await fetch(
        `http://localhost:3001/api/detalleventa/venta/${idVenta}`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        },
      );
      if (response.ok) {
        const data = await response.json();
        setDetallesVenta((prev) => ({ ...prev, [idVenta]: data.body }));
        setVentaExpandida(idVenta);
      }
    } catch (error) {
      console.error("Error al cargar detalles:", error);
    }
  };

  const abrirModalEditar = (venta) => {
    setVentaSeleccionada(venta);
    setMostrarModalEditar(true);
  };
  const cerrarModalEditar = () => {
    setMostrarModalEditar(false);
    setVentaSeleccionada(null);
  };
  const handleGuardarEdicion = (ventaActualizada) => {
    setVentas((prev) =>
      prev.map((v) =>
        v.idVenta === ventaActualizada.idVenta ? ventaActualizada : v,
      ),
    );
  };
  const abrirModalEliminar = (venta) => {
    setVentaSeleccionada(venta);
    setMostrarModalEliminar(true);
  };
  const cerrarModalEliminar = () => {
    setMostrarModalEliminar(false);
    setVentaSeleccionada(null);
  };
  const handleConfirmarEliminacion = (ventaEliminada) => {
    setVentas((prev) =>
      prev.filter((v) => v.idVenta !== ventaEliminada.idVenta),
    );
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarVentas();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  const formatearFecha = (fecha) =>
    new Date(fecha).toLocaleDateString("es-CO", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

  const formatearPrecio = (precio) =>
    new Intl.NumberFormat("es-CO", {
      style: "currency",
      currency: "COP",
      minimumFractionDigits: 0,
    }).format(precio);

  const ventasFiltradas = ventas.filter(
    (v) =>
      (v.idVenta?.toString() || "")
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      (v.Total?.toString() || "")
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      (v.Persona
        ? `${v.Persona.Primer_Nombre} ${v.Persona.Primer_Apellido}`.toLowerCase()
        : ""
      ).includes(search.toLowerCase()),
  );

  const totalPaginas = Math.max(
    1,
    Math.ceil(ventasFiltradas.length / POR_PAGINA),
  );
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const ventasPagina = ventasFiltradas.slice(inicio, inicio + POR_PAGINA);
  const handleSearch = (val) => {
    setSearch(val);
    setPaginaActual(1);
  };

  if (loading) {
    return (
      <div
        className="d-flex flex-column align-items-center justify-content-center"
        style={{ minHeight: "60vh" }}
      >
        <div
          className="spinner-border mb-3"
          style={{ width: 48, height: 48, color: "#9b59b6" }}
          role="status"
        />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando ventas...</p>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .lv-wrapper { padding: 40px 32px; min-height: 100vh; }
        .lv-card { background: rgba(253,242,255,0.60); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); border: 1.5px solid rgba(196,140,230,0.22); border-radius: 20px; box-shadow: 0 8px 40px rgba(160,80,200,0.12); overflow: hidden; }
        .lv-header { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); padding: 26px 32px 20px; }
        .lv-header h2 { color: #fff; font-weight: 700; font-size: 1.45rem; margin: 0 0 4px; }
        .lv-header p { color: rgba(255,255,255,0.80); margin: 0; font-size: 0.88rem; }
        .lv-counter { background: rgba(255,255,255,0.22); color: #fff; border-radius: 20px; padding: 4px 16px; font-size: 0.82rem; font-weight: 700; white-space: nowrap; }

        /* ── Botón reporte rosado ── */
        .lv-btn-reporte {
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
        .lv-btn-reporte:hover:not(:disabled) { opacity: 0.92; transform: translateY(-1px); box-shadow: 0 5px 16px rgba(244,114,182,0.50); }
        .lv-btn-reporte:disabled { opacity: 0.65; cursor: not-allowed; }
        .lv-btn-reporte .lv-spinner-sm { width: 13px; height: 13px; border: 2px solid rgba(107,17,67,0.3); border-top-color: #6b1143; border-radius: 50%; animation: lv-spin 0.7s linear infinite; }
        @keyframes lv-spin { to { transform: rotate(360deg); } }

        /* ── Botón reporte rosado ── */
        .lv-btn-reporte {
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
        .lv-btn-reporte:hover:not(:disabled) { opacity: 0.92; transform: translateY(-1px); box-shadow: 0 5px 16px rgba(244,114,182,0.50); }
        .lv-btn-reporte:disabled { opacity: 0.65; cursor: not-allowed; }
        .lv-btn-reporte .lv-spinner-sm { width: 13px; height: 13px; border: 2px solid rgba(107,17,67,0.3); border-top-color: #6b1143; border-radius: 50%; animation: lv-spin 0.7s linear infinite; }
        @keyframes lv-spin { to { transform: rotate(360deg); } }

        .lv-filters { padding: 20px 24px 6px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
        .lv-search-wrap { position: relative; flex: 1; }
        .lv-search-icon { position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: #b06ac4; font-size: 1rem; pointer-events: none; }
        .lv-search { width: 100%; border: 1.8px solid #e8d0f8; border-radius: 10px; padding: 9px 14px 9px 40px; font-size: 0.93rem; background: rgba(255,255,255,0.75); color: #3d1a5c; outline: none; transition: border-color 0.2s, box-shadow 0.2s; }
        .lv-search:focus { border-color: #9b59b6; box-shadow: 0 0 0 3px rgba(155,89,182,0.14); background: #fff; }
        .lv-scroll { overflow-x: auto; padding: 16px 20px 8px; }
        .lv-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 0.855rem; }
        .lv-table thead th { background: rgba(210,160,240,0.18); color: #6a1b8a; font-weight: 700; font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.07em; padding: 11px 13px; border-bottom: 2px solid rgba(180,110,220,0.22); white-space: nowrap; }
        .lv-table tbody tr { transition: background 0.15s; }
        .lv-table tbody tr:nth-child(even) { background: rgba(245,220,255,0.20); }
        .lv-table tbody tr:hover { background: rgba(230,190,255,0.32); }
        .lv-table tbody td { padding: 10px 13px; border-bottom: 1px solid rgba(210,160,240,0.18); color: #2d1a40; vertical-align: middle; white-space: nowrap; }
        .lv-table tbody tr:last-child td { border-bottom: none; }
        .lv-chip-id { background: rgba(200,140,240,0.18); color: #6a1b8a; border-radius: 6px; padding: 2px 10px; font-weight: 700; font-size: 0.8rem; }
        .lv-total { background: #d1fae5; color: #065f46; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lv-total::before { content: "●"; font-size: 0.55rem; }
        .lv-btn-eye { background: #f0f9ff; border: 1.5px solid #bae6fd; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; align-items: center; color: #0369a1; font-size: 1rem; }
        .lv-btn-eye:hover { background: #e0f2fe; border-color: #0284c7; transform: scale(1.1); }
        .lv-btn-edit { background: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lv-btn-edit:hover { background: #dbeafe; border-color: #3b82f6; transform: scale(1.1); }
        .lv-btn-del { background: #fff5f5; border: 1.5px solid #fecaca; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lv-btn-del:hover { background: #fee2e2; border-color: #ef4444; transform: scale(1.1); }
        .lv-detalle-row td { background: rgba(243,232,255,0.40) !important; }
        .lv-detalle-inner { background: rgba(255,255,255,0.7); border-radius: 12px; border: 1px solid rgba(196,140,230,0.25); overflow: hidden; margin: 4px 0; }
        .lv-detalle-inner table { width: 100%; border-collapse: collapse; font-size: 0.82rem; }
        .lv-detalle-inner thead th { background: rgba(200,140,240,0.18); color: #6a1b8a; padding: 8px 12px; font-weight: 700; font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .lv-detalle-inner tbody td { padding: 8px 12px; border-top: 1px solid rgba(210,160,240,0.15); color: #2d1a40; }
        .lv-detalle-inner tfoot td { padding: 8px 12px; background: rgba(155,69,199,0.1); color: #5b2182; font-weight: 700; border-top: 2px solid rgba(180,110,220,0.3); }
        .lv-detalle-title { color: #6a1b8a; font-weight: 700; font-size: 0.9rem; margin-bottom: 10px; display: flex; align-items: center; gap: 6px; }
        .lv-empty { text-align: center; padding: 52px 20px; }
        .lv-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .lv-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .lv-empty small { color: #c8a0e0; }
        .lv-page-info { text-align: center; font-size: 0.8rem; color: #9b59b6; font-weight: 600; padding: 0 24px 10px; }
        .lv-pagination { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 0 24px 24px; flex-wrap: wrap; }
        .lv-pg-btn { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-weight: 700; font-size: 0.85rem; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lv-pg-btn:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lv-pg-btn:disabled { opacity: 0.35; cursor: not-allowed; }
        .lv-pg-btn.active { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); border-color: #9b45c7; color: #fff; box-shadow: 0 3px 10px rgba(155,69,199,0.3); }
        .lv-pg-arrow { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-size: 1.1rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lv-pg-arrow:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lv-pg-arrow:disabled { opacity: 0.35; cursor: not-allowed; }
      `}</style>

      <div className="lv-wrapper">
        <div
          className="container-fluid px-4"
          style={{ maxWidth: 1400, margin: "0 auto" }}
        >
          <div className="lv-card">
            {/* ── Header ── */}
            <div className="lv-header">
              <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                  <h2 className="merriweather-font">
                    <i className="bi bi-receipt me-2"></i>Lista de Ventas
                    Registradas
                  </h2>
                  <p>Gestiona, edita y elimina las ventas del sistema</p>
                </div>
                {/* CONTADOR + BOTÓN REPORTE */}
                <div className="d-flex align-items-center gap-2 flex-wrap">
                  <span className="lv-counter">
                    {ventasFiltradas.length} venta
                    {ventasFiltradas.length !== 1 ? "s" : ""}
                  </span>
                  <button
                    className="lv-btn-reporte"
                    onClick={handleGenerarReporte}
                    disabled={generandoPDF}
                  >
                    {generandoPDF ? (
                      <>
                        <div className="lv-spinner-sm" />
                        Generando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-file-earmark-pdf-fill"></i>
                        Reporte Ventas
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* ── Buscador ── */}
            <div className="lv-filters">
              <div className="lv-search-wrap">
                <i className="bi bi-search lv-search-icon"></i>
                <input
                  type="text"
                  className="lv-search"
                  placeholder="Buscar por ID, total, cliente..."
                  value={search}
                  onChange={(e) => handleSearch(e.target.value)}
                />
              </div>
            </div>

            {/* ── Tabla ── */}
            <div className="lv-scroll">
              <table className="lv-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Fecha</th>
                    <th>Total</th>
                    <th>Cliente</th>
                    <th>Ver Detalles</th>
                    <th>Editar</th>
                    <th>Eliminar</th>
                  </tr>
                </thead>
                <tbody>
                  {ventasPagina.length > 0 ? (
                    ventasPagina.map((v, index) => (
                      <>
                        <tr key={v.idVenta}>
                          <td>
                            <span className="lv-chip-id">
                              {inicio + index + 1}
                            </span>
                          </td>
                          <td>{formatearFecha(v.Fecha)}</td>
                          <td>
                            <span className="lv-total">
                              {formatearPrecio(v.Total)}
                            </span>
                          </td>
                          <td style={{ fontWeight: 600, color: "#3d1a5c" }}>
                            {v.Persona
                              ? `${v.Persona.Primer_Nombre} ${v.Persona.Primer_Apellido}`
                              : "Cliente no disponible"}
                          </td>
                          <td>
                            <button
                              className="lv-btn-eye"
                              onClick={() => cargarDetallesVenta(v.idVenta)}
                              title="Ver detalles"
                            >
                              <i
                                className={`bi ${ventaExpandida === v.idVenta ? "bi-eye-slash" : "bi-eye"}`}
                              ></i>
                            </button>
                          </td>
                          <td>
                            <button
                              className="lv-btn-edit"
                              onClick={() => abrirModalEditar(v)}
                              title="Editar"
                            >
                              <img
                                src="img/editar3.png"
                                width="22"
                                height="22"
                                alt="Editar"
                              />
                            </button>
                          </td>
                          <td>
                            <button
                              className="lv-btn-del"
                              onClick={() => abrirModalEliminar(v)}
                              title="Eliminar"
                            >
                              <img
                                src="img/eliminar2.png"
                                width="22"
                                height="22"
                                alt="Eliminar"
                              />
                            </button>
                          </td>
                        </tr>
                        {ventaExpandida === v.idVenta &&
                          detallesVenta[v.idVenta] && (
                            <tr className="lv-detalle-row">
                              <td
                                colSpan="7"
                                style={{ padding: "12px 20px 16px" }}
                              >
                                <div className="lv-detalle-title">
                                  <i className="bi bi-box-seam"></i>Detalles de
                                  la Venta #{v.idVenta}
                                </div>
                                <div className="lv-detalle-inner">
                                  <table>
                                    <thead>
                                      <tr>
                                        <th>ID Producto</th>
                                        <th>Nombre Producto</th>
                                        <th>Cantidad</th>
                                        <th>Precio Unitario</th>
                                        <th>Subtotal</th>
                                      </tr>
                                    </thead>
                                    <tbody>
                                      {detallesVenta[v.idVenta].map(
                                        (detalle) => (
                                          <tr key={detalle.idDetalleVenta}>
                                            <td>{detalle.Producto_FK}</td>
                                            <td>
                                              {detalle.Producto
                                                ?.NombreProducto ||
                                                "Producto no disponible"}
                                            </td>
                                            <td>{detalle.Cantidad}</td>
                                            <td
                                              style={{
                                                color: "#7c3aad",
                                                fontWeight: 600,
                                              }}
                                            >
                                              {formatearPrecio(
                                                detalle.PrecioUnitario,
                                              )}
                                            </td>
                                            <td
                                              style={{
                                                fontWeight: 700,
                                                color: "#5b2182",
                                              }}
                                            >
                                              {formatearPrecio(
                                                detalle.Cantidad *
                                                  detalle.PrecioUnitario,
                                              )}
                                            </td>
                                          </tr>
                                        ),
                                      )}
                                    </tbody>
                                    <tfoot>
                                      <tr>
                                        <td
                                          colSpan="4"
                                          style={{ textAlign: "right" }}
                                        >
                                          Total:
                                        </td>
                                        <td>{formatearPrecio(v.Total)}</td>
                                      </tr>
                                    </tfoot>
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
                        <div className="lv-empty">
                          <i className="bi bi-inbox"></i>
                          <p>
                            {search
                              ? "No se encontraron resultados"
                              : "No hay ventas registradas"}
                          </p>
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
                <p className="lv-page-info">
                  Mostrando {inicio + 1}–
                  {Math.min(inicio + POR_PAGINA, ventasFiltradas.length)} de{" "}
                  {ventasFiltradas.length} ventas
                </p>
                <div className="lv-pagination">
                  <button
                    className="lv-pg-arrow"
                    onClick={() => setPaginaActual(1)}
                    disabled={paginaSegura === 1}
                  >
                    «
                  </button>
                  <button
                    className="lv-pg-arrow"
                    onClick={() => setPaginaActual((p) => p - 1)}
                    disabled={paginaSegura === 1}
                  >
                    ‹
                  </button>
                  {Array.from({ length: totalPaginas }, (_, i) => i + 1)
                    .filter(
                      (n) =>
                        n === 1 ||
                        n === totalPaginas ||
                        Math.abs(n - paginaSegura) <= 2,
                    )
                    .reduce((acc, n, i, arr) => {
                      if (i > 0 && n - arr[i - 1] > 1) acc.push("...");
                      acc.push(n);
                      return acc;
                    }, [])
                    .map((item, i) =>
                      item === "..." ? (
                        <span
                          key={`d${i}`}
                          style={{
                            color: "#b895d4",
                            padding: "0 4px",
                            lineHeight: "36px",
                          }}
                        >
                          …
                        </span>
                      ) : (
                        <button
                          key={item}
                          className={`lv-pg-btn${paginaSegura === item ? " active" : ""}`}
                          onClick={() => setPaginaActual(item)}
                        >
                          {item}
                        </button>
                      ),
                    )}
                  <button
                    className="lv-pg-arrow"
                    onClick={() => setPaginaActual((p) => p + 1)}
                    disabled={paginaSegura === totalPaginas}
                  >
                    ›
                  </button>
                  <button
                    className="lv-pg-arrow"
                    onClick={() => setPaginaActual(totalPaginas)}
                    disabled={paginaSegura === totalPaginas}
                  >
                    »
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {mostrarModalEditar && (
        <ModalEditarVenta
          venta={ventaSeleccionada}
          onClose={cerrarModalEditar}
          onGuardar={handleGuardarEdicion}
        />
      )}
      {mostrarModalEliminar && (
        <ModalEliminarVenta
          venta={ventaSeleccionada}
          onClose={cerrarModalEliminar}
          onConfirmar={handleConfirmarEliminacion}
        />
      )}
    </>
  );
}
