import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarProducto from "../componentesListas/ModalEditarProducto";
import ModalEliminarProducto from "../componentesListas/ModalEliminarProducto";

const POR_PAGINA = 4;

export default function ListaProductos() {
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [productoSeleccionado, setProductoSeleccionado] = useState(null);
  const [search, setSearch] = useState("");
  const [mostrarModalEditar, setMostrarModalEditar] = useState(false);
  const [mostrarModalEliminar, setMostrarModalEliminar] = useState(false);
  const [paginaActual, setPaginaActual] = useState(1);

  // Mapa de colores
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
    const token = localStorage.getItem("token");

    fetch("http://localhost:3001/api/producto", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    })
      .then((res) => {
        if (!res.ok) throw new Error("Error al obtener productos");
        return res.json();
      })
      .then((data) => {
        setProductos(data.body);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const abrirModalEditar = (producto) => {
    setProductoSeleccionado(producto);
    setMostrarModalEditar(true);
  };

  const cerrarModalEditar = () => {
    setMostrarModalEditar(false);
    setProductoSeleccionado(null);
  };

  const handleGuardarEdicion = (productoActualizado) => {
    setProductos((prev) =>
      prev.map((p) =>
        p.idProducto === productoActualizado.idProducto ? productoActualizado : p
      )
    );
  };

  const abrirModalEliminar = (producto) => {
    setProductoSeleccionado(producto);
    setMostrarModalEliminar(true);
  };

  const cerrarModalEliminar = () => {
    setMostrarModalEliminar(false);
    setProductoSeleccionado(null);
  };

  const handleConfirmarEliminacion = (productoEliminado) => {
    setProductos((prev) =>
      prev.filter((p) => p.idProducto !== productoEliminado.idProducto)
    );
  };

  const productosFiltrados = productos.filter(
    (p) =>
      (p.idProducto?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.NombreProducto || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.Color || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.Talla || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.Stock?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.Precio?.toString() || "").toLowerCase().includes(search.toLowerCase())
  );

  const formatearPrecio = (precio) => {
    return new Intl.NumberFormat("es-CO", {
      style: "currency",
      currency: "COP",
      minimumFractionDigits: 0,
    }).format(precio);
  };

  const renderStockBadge = (stock) => {
    if (stock > 10) return <span className="lp-stock-alto">{stock}</span>;
    if (stock > 5) return <span className="lp-stock-medio">{stock}</span>;
    return <span className="lp-stock-bajo">{stock}</span>;
  };

  // ── Paginación ──
  const totalPaginas = Math.max(1, Math.ceil(productosFiltrados.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const productosPagina = productosFiltrados.slice(inicio, inicio + POR_PAGINA);

  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando productos...</p>
      </div>
    );
  }


  return (
    <>
      <style>{`
        .lp-wrapper {
          padding: 40px 32px;
          min-height: 100vh;
        }

        /* ── Tarjeta ── */
        .lp-card {
          background: rgba(253, 242, 255, 0.60);
          backdrop-filter: blur(14px);
          -webkit-backdrop-filter: blur(14px);
          border: 1.5px solid rgba(196, 140, 230, 0.22);
          border-radius: 20px;
          box-shadow: 0 8px 40px rgba(160, 80, 200, 0.12);
          overflow: hidden;
        }

        /* ── Header ── */
        .lp-header {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          padding: 26px 32px 20px;
        }
        .lp-header h2 {
          color: #fff;
          font-weight: 700;
          font-size: 1.45rem;
          margin: 0 0 4px;
        }
        .lp-header p {
          color: rgba(255,255,255,0.80);
          margin: 0;
          font-size: 0.88rem;
        }
        .lp-counter {
          background: rgba(255,255,255,0.22);
          color: #fff;
          border-radius: 20px;
          padding: 4px 16px;
          font-size: 0.82rem;
          font-weight: 700;
          white-space: nowrap;
        }

        /* ── Filtros ── */
        .lp-filters {
          padding: 20px 24px 6px;
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          align-items: center;
        }
        .lp-search-wrap {
          position: relative;
          flex: 1;
        }
        .lp-search-icon {
          position: absolute;
          left: 13px;
          top: 50%;
          transform: translateY(-50%);
          color: #b06ac4;
          font-size: 1rem;
          pointer-events: none;
        }
        .lp-search {
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
        .lp-search:focus {
          border-color: #9b59b6;
          box-shadow: 0 0 0 3px rgba(155,89,182,0.14);
          background: #fff;
        }

        /* ── Tabla ── */
        .lp-scroll {
          overflow-x: auto;
          padding: 16px 20px 28px;
        }
        .lp-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          font-size: 0.855rem;
        }
        .lp-table thead th {
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
        .lp-table tbody tr {
          transition: background 0.15s;
        }
        .lp-table tbody tr:nth-child(even) {
          background: rgba(245, 220, 255, 0.20);
        }
        .lp-table tbody tr:hover {
          background: rgba(230, 190, 255, 0.32);
        }
        .lp-table tbody td {
          padding: 10px 13px;
          border-bottom: 1px solid rgba(210, 160, 240, 0.18);
          color: #2d1a40;
          vertical-align: middle;
          white-space: nowrap;
        }
        .lp-table tbody tr:last-child td {
          border-bottom: none;
        }

        /* ── Chips ── */
        .lp-chip-id {
          background: rgba(200, 140, 240, 0.18);
          color: #6a1b8a;
          border-radius: 6px;
          padding: 2px 10px;
          font-weight: 700;
          font-size: 0.8rem;
        }
        .lp-chip-talla {
          background: rgba(200, 140, 240, 0.18);
          color: #5b2182;
          border-radius: 6px;
          padding: 3px 10px;
          font-size: 0.78rem;
          font-weight: 600;
        }

        /* Stock */
        .lp-stock-alto   { background:#d1fae5; color:#065f46; border-radius:20px; padding:4px 12px; font-size:0.77rem; font-weight:700; display:inline-flex; align-items:center; gap:5px; }
        .lp-stock-medio  { background:#fef9c3; color:#854d0e; border-radius:20px; padding:4px 12px; font-size:0.77rem; font-weight:700; display:inline-flex; align-items:center; gap:5px; }
        .lp-stock-bajo   { background:#fee2e2; color:#991b1b; border-radius:20px; padding:4px 12px; font-size:0.77rem; font-weight:700; display:inline-flex; align-items:center; gap:5px; }
        .lp-stock-alto::before,
        .lp-stock-medio::before,
        .lp-stock-bajo::before { content:"●"; font-size:0.55rem; }

        /* Precio */
        .lp-precio {
          color: #6a1b8a;
          font-weight: 700;
          font-size: 0.88rem;
        }

        /* ── Botones acción ── */
        .lp-btn-edit {
          background: #eff6ff;
          border: 1.5px solid #bfdbfe;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .lp-btn-edit:hover { background:#dbeafe; border-color:#3b82f6; transform:scale(1.1); }
        .lp-btn-del {
          background: #fff5f5;
          border: 1.5px solid #fecaca;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .lp-btn-del:hover { background:#fee2e2; border-color:#ef4444; transform:scale(1.1); }

        /* ── Empty ── */
        .lp-empty { text-align:center; padding:52px 20px; }
        .lp-empty i { font-size:2.8rem; display:block; margin-bottom:10px; color:#c8a0e0; }
        .lp-empty p { margin:0; font-weight:600; color:#7c3aad; }
        .lp-empty small { color:#c8a0e0; }

        /* ── Paginador ── */
        .lp-pagination {
          display: flex; align-items: center; justify-content: center;
          gap: 6px; padding: 0 24px 24px; flex-wrap: wrap;
        }
        .lp-page-info {
          text-align: center; font-size: 0.8rem;
          color: #9b59b6; font-weight: 600; padding: 0 24px 10px;
        }
        .lp-pg-btn {
          width:36px; height:36px; border-radius:9px;
          border:1.8px solid #e8d0f8; background:rgba(255,255,255,0.75);
          color:#6a1b8a; font-weight:700; font-size:0.85rem; cursor:pointer;
          display:inline-flex; align-items:center; justify-content:center;
          transition:all 0.15s;
        }
        .lp-pg-btn:hover:not(:disabled) { background:rgba(200,140,240,0.22); border-color:#9b59b6; transform:scale(1.07); }
        .lp-pg-btn:disabled { opacity:0.35; cursor:not-allowed; }
        .lp-pg-btn.active {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          border-color:#9b45c7; color:#fff;
          box-shadow:0 3px 10px rgba(155,69,199,0.3);
        }
        .lp-pg-arrow {
          width:36px; height:36px; border-radius:9px;
          border:1.8px solid #e8d0f8; background:rgba(255,255,255,0.75);
          color:#6a1b8a; font-size:1.1rem; font-weight:700; cursor:pointer;
          display:inline-flex; align-items:center; justify-content:center;
          transition:all 0.15s;
        }
        .lp-pg-arrow:hover:not(:disabled) { background:rgba(200,140,240,0.22); border-color:#9b59b6; transform:scale(1.07); }
        .lp-pg-arrow:disabled { opacity:0.35; cursor:not-allowed; }
      `}</style>

      <div className="lp-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
          <div className="lp-card">

            {/* ── Header ── */}
            <div className="lp-header">
              <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                  <h2 className="merriweather-font">
                    <i className="bi bi-box-seam-fill me-2"></i>
                    Lista de Productos Registrados
                  </h2>
                  <p>Gestiona, edita y elimina los productos del sistema</p>
                </div>
                <span className="lp-counter">
                  {productosFiltrados.length} producto{productosFiltrados.length !== 1 ? "s" : ""}
                </span>
              </div>
            </div>

            {/* ── Buscador ── */}
            <div className="lp-filters">
              <div className="lp-search-wrap">
                <i className="bi bi-search lp-search-icon"></i>
                <input
                  type="text"
                  className="lp-search"
                  placeholder="Buscar por nombre, color, talla, precio..."
                  value={search}
                  onChange={(e) => handleSearch(e.target.value)}
                />
              </div>
            </div>

            {/* ── Tabla ── */}
            <div className="lp-scroll">
              <table className="lp-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Nombre Producto</th>
                    <th>Color</th>
                    <th>Talla</th>
                    <th>Stock</th>
                    <th>Precio</th>
                    <th>Editar</th>
                    <th>Eliminar</th>
                  </tr>
                </thead>
                <tbody>
                  {productosPagina.length > 0 ? (
                    productosPagina.map((p, index) => (
                      <tr key={p.idProducto}>
                        <td><span className="lp-chip-id">{inicio + index + 1}</span></td>
                        <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{p.NombreProducto}</td>
                        <td>
                          <div className="d-flex align-items-center justify-content-center gap-2">
                            <div style={{
                              width: 20, height: 20, borderRadius: "50%",
                              backgroundColor: getColorCode(p.Color),
                              border: p.Color?.toLowerCase() === "blanco" ? "1.5px solid #ccc" : "2px solid rgba(0,0,0,0.08)",
                              boxShadow: "0 1px 4px rgba(0,0,0,0.12)",
                              flexShrink: 0,
                            }} title={p.Color} />
                            <span style={{ color: "#5b2182", fontSize: "0.82rem" }}>{p.Color}</span>
                          </div>
                        </td>
                        <td><span className="lp-chip-talla">{p.Talla}</span></td>
                        <td>
                          {renderStockBadge(p.Stock)}
                        </td>
                        <td><span className="lp-precio">{formatearPrecio(p.Precio)}</span></td>
                        <td>
                          <button className="lp-btn-edit" onClick={() => abrirModalEditar(p)} title="Editar">
                            <img src="img/editar3.png" width="22" height="22" alt="Editar" />
                          </button>
                        </td>
                        <td>
                          <button className="lp-btn-del" onClick={() => abrirModalEliminar(p)} title="Eliminar">
                            <img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="8">
                        <div className="lp-empty">
                          <i className="bi bi-inbox"></i>
                          <p>{search ? "No se encontraron resultados" : "No hay productos registrados"}</p>
                          {search && <small>Intenta con otro término de búsqueda</small>}
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>{/* fin lp-scroll */}

            {/* ── Paginador ── */}
            {totalPaginas > 1 && (
              <>
                <p className="lp-page-info">
                  Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, productosFiltrados.length)} de {productosFiltrados.length} productos
                </p>
                <div className="lp-pagination">
                  <button className="lp-pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1} title="Primera">«</button>
                  <button className="lp-pg-arrow" onClick={() => setPaginaActual(p => p - 1)} disabled={paginaSegura === 1} title="Anterior">‹</button>

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
                        
                        </span>) : (
                        <button
                          key={item}
                          className={`lp-pg-btn${paginaSegura === item ? " active" : ""}`}
                          onClick={() => setPaginaActual(item)}
                        >{item}</button>
                      )
                    )
                  }

                  <button className="lp-pg-arrow" onClick={() => setPaginaActual(p => p + 1)} disabled={paginaSegura === totalPaginas} title="Siguiente">›</button>
                  <button className="lp-pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas} title="Última">»</button>
                </div>
              </>
            )}

          </div>{/* fin lp-card */}
        </div>
      </div>

      {/* Modal Editar */}
      {mostrarModalEditar && (
        <ModalEditarProducto
          producto={productoSeleccionado}
          onClose={cerrarModalEditar}
          onGuardar={handleGuardarEdicion}
        />
      )}

      {/* Modal Eliminar */}
      {mostrarModalEliminar && (
        <ModalEliminarProducto
          producto={productoSeleccionado}
          onClose={cerrarModalEliminar}
          onConfirmar={handleConfirmarEliminacion}
        />
      )}
    </>
  );
}