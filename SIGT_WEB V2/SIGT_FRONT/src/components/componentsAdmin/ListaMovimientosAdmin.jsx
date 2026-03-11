import { useEffect, useState } from "react";
import reporteService from "../../services/reporteService";

export default function ListaMovimientosAdmin() {
  const [movimientos, setMovimientos] = useState([]);
  const [personas, setPersonas] = useState({});
  const [productos, setProductos] = useState({});
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filtroTipo, setFiltroTipo] = useState("Todos");
  const [movimientoSeleccionado, setMovimientoSeleccionado] = useState(null);
  const [produccion, setProduccion] = useState(null);
  const [detallesProduccion, setDetallesProduccion] = useState([]);
  const [mostrarModal, setMostrarModal] = useState(false);
  const [loadingDetalles, setLoadingDetalles] = useState(false);
  const [generandoPDF, setGenerandoPDF] = useState(false);

  const API_URL = `${import.meta.env.VITE_API_URL}/api`;

  useEffect(() => { cargarTodosDatos(); }, []);

  const cargarTodosDatos = async () => {
    setLoading(true);
    const token = localStorage.getItem("token");
    try {
      const [resMovimientos, resPersonas, resProductos] = await Promise.all([
        fetch(`${API_URL}/movimiento`, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } }),
        fetch(`${API_URL}/persona`, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } }),
        fetch(`${API_URL}/producto`, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } }),
      ]);
      const dataMovimientos = await resMovimientos.json();
      const dataPersonas = await resPersonas.json();
      const dataProductos = await resProductos.json();
      const personasMap = {};
      (dataPersonas.body || []).forEach((p) => { if (p.idPersona) personasMap[p.idPersona] = p; });
      const productosMap = {};
      (dataProductos.body || []).forEach((p) => { if (p.idProducto) productosMap[p.idProducto] = p; });
      setMovimientos(dataMovimientos.body || []);
      setPersonas(personasMap);
      setProductos(productosMap);
    } catch (err) { console.error("Error al cargar datos:", err); }
    finally { setLoading(false); }
  };

  const verDetalles = async (movimiento, numeroSecuencial) => {
    const token = localStorage.getItem("token");
    setMovimientoSeleccionado({ ...movimiento, numeroSecuencial });
    setLoadingDetalles(true);
    setMostrarModal(true);
    try {
      if (movimiento.Tipo === "Entrada") {
        const resProduccion = await fetch(`${API_URL}/produccion`, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } });
        if (resProduccion.ok) {
          const dataProduccion = await resProduccion.json();
          const produccionEncontrada = (dataProduccion.body || []).find(
            (p) => p.Persona_FK === movimiento.Persona_FK && new Date(p.FechaProduccion).toDateString() === new Date(movimiento.Fecha).toDateString()
          );
          if (produccionEncontrada) {
            setProduccion(produccionEncontrada);
            const resDetalles = await fetch(`${API_URL}/detalleproduccion`, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } });
            if (resDetalles.ok) {
              const dataDetalles = await resDetalles.json();
              setDetallesProduccion((dataDetalles.body || []).filter((d) => d.Produccion_FK === produccionEncontrada.idProduccion));
            }
          }
        }
      }
    } catch (err) { console.error(err); }
    finally { setLoadingDetalles(false); }
  };

  const cerrarModal = () => {
    setMostrarModal(false);
    setMovimientoSeleccionado(null);
    setProduccion(null);
    setDetallesProduccion([]);
  };

  const handleGenerarReporte = async () => {
    setGenerandoPDF(true);
    try {
      await reporteService.descargarMovimientos();
    } catch (err) {
      alert(err.message);
    } finally {
      setGenerandoPDF(false);
    }
  };

  const getNombrePersona = (idPersona) => {
    const persona = personas[idPersona];
    if (!persona) return `ID: ${idPersona}`;
    return [persona.Primer_Nombre, persona.Segundo_Nombre, persona.Primer_Apellido, persona.Segundo_Apellido].filter(Boolean).join(" ");
  };

  const getDescripcionProducto = (idProducto) => {
    const producto = productos[idProducto];
    if (!producto) return `ID: ${idProducto}`;
    return `${producto.NombreProducto} · ${producto.Color} / ${producto.Talla}`;
  };

  const movimientosFiltrados = movimientos.filter((m) => {
    const persona = personas[m.Persona_FK];
    const producto = productos[m.Producto_FK];
    const nombrePersona = persona ? `${persona.Primer_Nombre} ${persona.Primer_Apellido}`.toLowerCase() : "";
    const nombreProducto = producto ? producto.NombreProducto.toLowerCase() : "";
    const coincideBusqueda =
      (m.idMovimiento?.toString() || "").includes(search) ||
      (m.Motivo || "").toLowerCase().includes(search.toLowerCase()) ||
      (m.Tipo || "").toLowerCase().includes(search.toLowerCase()) ||
      (m.Fecha || "").includes(search) ||
      nombrePersona.includes(search.toLowerCase()) ||
      nombreProducto.includes(search.toLowerCase());
    const coincideTipo = filtroTipo === "Todos" || m.Tipo === filtroTipo;
    return coincideBusqueda && coincideTipo;
  });

  const formatearFecha = (fecha) => {
    const meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
    const date = new Date(fecha);
    return `${date.getDate()} ${meses[date.getMonth()]} ${date.getFullYear()}`;
  };

  const tipoConfig = {
    Entrada:    { color: "#10b981", bg: "#d1fae5", icon: "↓", label: "Entrada" },
    Salida:     { color: "#f59e0b", bg: "#fef3c7", icon: "↑", label: "Salida" },
    Ajuste:     { color: "#3b82f6", bg: "#dbeafe", icon: "⇄", label: "Ajuste" },
    Devolucion: { color: "#8b5cf6", bg: "#ede9fe", icon: "↩", label: "Devolución" },
  };
  const getTipo = (tipo) => tipoConfig[tipo] || { color: "#6b7280", bg: "#f3f4f6", icon: "?", label: tipo };

  const totalEntradas = movimientos.filter((m) => m.Tipo === "Entrada").length;
  const totalSalidas = movimientos.filter((m) => m.Tipo === "Salida").length;

  if (loading) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#faf8ff" }}>
        <style>{`
          @keyframes spin { to { transform: rotate(360deg); } }
          @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.5} }
        `}</style>
        <div style={{ textAlign: "center" }}>
          <div style={{ width: 48, height: 48, border: "3px solid #e9d5ff", borderTop: "3px solid #7c3aed", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto 16px" }} />
          <p style={{ color: "#7c3aed", fontWeight: 600, fontFamily: "Georgia, serif", letterSpacing: "0.05em" }}>Cargando movimientos…</p>
        </div>
      </div>
    );
  }

  const renderContenidoProduccion = () => {
  if (loadingDetalles) {
    return (
      <div className="mov-spinner">
        <div className="mov-spinner-ring" />
        <span style={{ color: "#a78bfa", fontSize: "0.85rem" }}>Cargando producción…</span>
      </div>
    );
  }

  if (produccion) {
    return (
      <>
        <div className="mov-section-card">
          <div className="mov-section-card-header">📋 Información de Producción</div>
          <div className="mov-prod-grid">
            <div className="mov-prod-block">
              <div className="mov-info-label">ID Producción</div>
              <div className="mov-info-value">#{produccion.idProduccion}</div>
            </div>
            <div className="mov-prod-block">
              <div className="mov-info-label">Cantidad Producida</div>
              <div className="mov-info-value">{produccion.CantidadProducida} uds.</div>
            </div>
            <div className="mov-prod-block">
              <div className="mov-info-label">Tarea ID</div>
              <div className="mov-info-value">#{produccion.DetalleTarea_FK}</div>
            </div>
          </div>
        </div>

        {detallesProduccion.length > 0 && (
          <div className="mov-section-card">
            <div className="mov-section-card-header">🔧 Materiales utilizados</div>
            <table className="mov-table">
              <thead>
                <tr>
                  <th>ID Detalle</th>
                  <th>ID Material</th>
                  <th>Cantidad</th>
                </tr>
              </thead>
              <tbody>
                {detallesProduccion.map((d) => (
                  <tr key={d.idDetalleProduccion}>
                    <td style={{ fontWeight: 600 }}>#{d.idDetalleProduccion}</td>
                    <td>
                      <span style={{ background: "#ede9fe", color: "#5b21b6", borderRadius: 6, padding: "3px 10px", fontWeight: 600, fontSize: "0.82rem" }}>
                        {d.Producto_FK}
                      </span>
                    </td>
                    <td style={{ fontWeight: 600 }}>{d.Cantidad}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div style={{ padding: "12px 20px", background: "#f5f3ff", borderTop: "1px solid #ede9fe", fontSize: "0.82rem", color: "#7c3aed", fontWeight: 500 }}>
              {detallesProduccion.length} material(es) utilizado(s)
            </div>
          </div>
        )}
      </>
    );
  }

  return (
    <div className="mov-warn">⚠️ No se encontró información de producción asociada a este movimiento.</div>
  );
};
  return (
    <>
      <style>{`
        @import url("https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:wght@300;400;500;600&display=swap');

        * { box-sizing: border-box; }

        .mov-root {
          font-family: 'DM Sans', sans-serif;
          background: #faf8ff;
          min-height: 100vh;
          padding: 40px 24px 80px;
        }

        .mov-inner { max-width: 1100px; margin: 0 auto; }

        .mov-hero {
          position: relative;
          background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 60%, #a78bfa 100%);
          border-radius: 24px;
          padding: 44px 48px;
          margin-bottom: 36px;
          overflow: hidden;
        }
        .mov-hero::before {
          content: "";
          position: absolute; inset: 0;
          background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
        }
        .mov-hero-title {
          font-family: 'DM Serif Display', Georgia, serif;
          font-size: 2rem;
          color: #fff;
          margin: 0 0 6px;
          position: relative;
        }
        .mov-hero-sub {
          color: rgba(255,255,255,0.65);
          margin: 0;
          font-size: 0.9rem;
          font-weight: 300;
          position: relative;
        }
        .mov-hero-deco {
          position: absolute;
          right: 48px; top: 50%;
          transform: translateY(-50%);
          font-size: 7rem;
          opacity: 0.07;
          font-family: 'DM Serif Display', serif;
          color: #fff;
          user-select: none;
          pointer-events: none;
        }

        .mov-stats {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 16px;
          margin-bottom: 28px;
        }
        .mov-stat {
          background: #fff;
          border: 1px solid #ede9fe;
          border-radius: 16px;
          padding: 20px 24px;
          display: flex;
          align-items: center;
          gap: 16px;
          box-shadow: 0 1px 4px rgba(124,58,237,.06);
          transition: transform .18s, box-shadow .18s;
        }
        .mov-stat:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(124,58,237,.12); }
        .mov-stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.4rem; flex-shrink: 0; }
        .mov-stat-label { font-size: 0.75rem; color: #9ca3af; font-weight: 500; text-transform: uppercase; letter-spacing: .06em; }
        .mov-stat-value { font-family: 'DM Serif Display', serif; font-size: 1.8rem; color: #1e1b4b; line-height: 1; }

        .mov-toolbar { display: flex; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
        .mov-search-wrap { position: relative; flex: 1; min-width: 220px; }
        .mov-search-wrap svg { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); color: #a78bfa; }
        .mov-search { width: 100%; background: #fff; border: 1.5px solid #ede9fe; border-radius: 12px; padding: 11px 14px 11px 42px; font-size: 0.9rem; font-family: 'DM Sans', sans-serif; color: #1e1b4b; outline: none; transition: border-color .2s, box-shadow .2s; }
        .mov-search:focus { border-color: #7c3aed; box-shadow: 0 0 0 3px rgba(124,58,237,.12); }
        .mov-search::placeholder { color: #c4b5fd; }
        .mov-filter { background: #fff; border: 1.5px solid #ede9fe; border-radius: 12px; padding: 11px 16px; font-size: 0.9rem; font-family: 'DM Sans', sans-serif; color: #1e1b4b; outline: none; cursor: pointer; min-width: 180px; transition: border-color .2s; }
        .mov-filter:focus { border-color: #7c3aed; }

        /* ── Section header con botón reporte ── */
        .mov-section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
        .mov-section-title { font-family: 'DM Serif Display', serif; font-size: 1.15rem; color: #1e1b4b; margin: 0; }
        .mov-section-right { display: flex; align-items: center; gap: 10px; }
        .mov-count-badge { background: #ede9fe; color: #5b21b6; border-radius: 20px; padding: 4px 14px; font-size: 0.78rem; font-weight: 600; }

        /* ── Botón reporte rosado ── */
        .mov-btn-reporte {
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
          font-family: 'DM Sans', sans-serif;
        }
        .mov-btn-reporte:hover:not(:disabled) {
          opacity: 0.92;
          transform: translateY(-1px);
          box-shadow: 0 5px 16px rgba(244, 114, 182, 0.50);
        }
        .mov-btn-reporte:disabled { opacity: 0.65; cursor: not-allowed; }
        .mov-btn-reporte .mov-spinner-sm {
          width: 13px; height: 13px;
          border: 2px solid rgba(107,17,67,0.3);
          border-top-color: #6b1143;
          border-radius: 50%;
          animation: spin 0.7s linear infinite;
        }

        .mov-card { background: #fff; border: 1px solid #ede9fe; border-radius: 18px; margin-bottom: 12px; overflow: hidden; cursor: pointer; transition: transform .18s, box-shadow .18s, border-color .18s; box-shadow: 0 1px 4px rgba(124,58,237,.05); }
        .mov-card:hover { transform: translateY(-2px); box-shadow: 0 8px 28px rgba(124,58,237,.13); border-color: #c4b5fd; }
        .mov-card-inner { display: flex; align-items: stretch; }
        .mov-card-accent { width: 5px; flex-shrink: 0; border-radius: 18px 0 0 18px; }
        .mov-card-body { padding: 18px 22px; flex: 1; }
        .mov-card-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
        .mov-card-left { display: flex; align-items: center; gap: 12px; }
        .mov-num { font-family: 'DM Serif Display', serif; font-size: 0.95rem; color: #c4b5fd; min-width: 36px; }
        .mov-badge { display: inline-flex; align-items: center; gap: 6px; border-radius: 8px; padding: 5px 12px; font-size: 0.78rem; font-weight: 600; letter-spacing: .02em; }
        .mov-badge-dot { width: 7px; height: 7px; border-radius: 50%; }
        .mov-card-arrow { color: #d8b4fe; font-size: 1.1rem; }
        .mov-chips { display: flex; flex-wrap: wrap; gap: 10px; }
        .mov-chip { display: flex; align-items: center; gap: 6px; background: #faf8ff; border: 1px solid #ede9fe; border-radius: 8px; padding: 5px 12px; font-size: 0.8rem; color: #5b21b6; }
        .mov-chip-icon { color: #a78bfa; font-size: 0.85rem; }
        .mov-motivo { margin-top: 12px; background: #faf8ff; border-left: 3px solid #c4b5fd; border-radius: 0 8px 8px 0; padding: 10px 14px; font-size: 0.82rem; color: #6d28d9; font-style: italic; }

        .mov-empty { text-align: center; padding: 72px 20px; background: #fff; border: 1px solid #ede9fe; border-radius: 18px; }
        .mov-empty-icon { font-size: 3.5rem; margin-bottom: 12px; }
        .mov-empty-text { font-family: 'DM Serif Display', serif; font-size: 1.1rem; color: #4c1d95; margin-bottom: 6px; }
        .mov-empty-sub { color: #a78bfa; font-size: 0.85rem; }

        .mov-overlay { position: fixed; inset: 0; background: rgba(15, 10, 40, 0.6); backdrop-filter: blur(6px); z-index: 1000; display: flex; align-items: center; justify-content: center; padding: 24px; animation: fadeIn .2s ease; }
        @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
        @keyframes slideUp { from { opacity: 0; transform: translateY(24px) } to { opacity: 1; transform: translateY(0) } }

        .mov-modal { background: #fff; border-radius: 24px; width: 100%; max-width: 740px; max-height: 88vh; overflow-y: auto; box-shadow: 0 32px 80px rgba(76,29,149,.25); animation: slideUp .25s ease; }
        .mov-modal-header { background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%); padding: 28px 32px; border-radius: 24px 24px 0 0; display: flex; align-items: flex-start; justify-content: space-between; }
        .mov-modal-title { font-family: 'DM Serif Display', serif; font-size: 1.3rem; color: #fff; margin: 0 0 4px; }
        .mov-modal-sub { color: rgba(255,255,255,0.55); font-size: 0.83rem; }
        .mov-modal-close { background: rgba(255,255,255,0.15); border: none; border-radius: 10px; width: 36px; height: 36px; color: #fff; font-size: 1.1rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: background .15s; flex-shrink: 0; }
        .mov-modal-close:hover { background: rgba(255,255,255,0.25); }
        .mov-modal-body { padding: 28px 32px; }
        .mov-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 24px; }
        .mov-info-block { background: #faf8ff; border: 1px solid #ede9fe; border-radius: 14px; padding: 16px 18px; }
        .mov-info-block.full { grid-column: 1 / -1; }
        .mov-info-label { font-size: 0.72rem; color: #a78bfa; text-transform: uppercase; letter-spacing: .08em; font-weight: 600; margin-bottom: 6px; }
        .mov-info-value { font-size: 0.95rem; color: #1e1b4b; font-weight: 500; }
        .mov-section-card { border: 1px solid #ede9fe; border-radius: 16px; overflow: hidden; margin-bottom: 20px; }
        .mov-section-card-header { padding: 14px 20px; background: #f5f3ff; display: flex; align-items: center; gap: 8px; font-weight: 600; font-size: 0.88rem; color: #5b21b6; border-bottom: 1px solid #ede9fe; }
        .mov-table { width: 100%; border-collapse: collapse; font-size: 0.84rem; }
        .mov-table thead th { background: #f5f3ff; color: #7c3aed; font-weight: 600; font-size: 0.73rem; text-transform: uppercase; letter-spacing: .06em; padding: 12px 16px; text-align: center; }
        .mov-table tbody td { padding: 12px 16px; border-top: 1px solid #f3f0ff; color: #1e1b4b; text-align: center; }
        .mov-table tbody tr:hover td { background: #faf8ff; }
        .mov-modal-footer { padding: 20px 32px 28px; display: flex; justify-content: flex-end; }
        .mov-btn-close { background: linear-gradient(135deg, #7c3aed, #5b21b6); color: #fff; border: none; border-radius: 12px; padding: 12px 28px; font-size: 0.9rem; font-family: 'DM Sans', sans-serif; font-weight: 600; cursor: pointer; letter-spacing: .03em; transition: opacity .2s, transform .15s; }
        .mov-btn-close:hover { opacity: 0.88; transform: translateY(-1px); }
        .mov-prod-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 16px 20px; }
        .mov-prod-block { background: #faf8ff; border: 1px solid #ede9fe; border-radius: 10px; padding: 12px 14px; text-align: center; }
        .mov-spinner { display: flex; align-items: center; justify-content: center; flex-direction: column; padding: 40px; gap: 12px; }
        .mov-spinner-ring { width: 36px; height: 36px; border: 3px solid #ede9fe; border-top-color: #7c3aed; border-radius: 50%; animation: spin .7s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
        .mov-warn { margin: 16px 20px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 12px; padding: 14px 18px; color: #92400e; font-size: 0.85rem; display: flex; align-items: center; gap: 8px; }

        @media (max-width: 640px) {
          .mov-stats { grid-template-columns: 1fr; }
          .mov-info-grid { grid-template-columns: 1fr; }
          .mov-prod-grid { grid-template-columns: 1fr; }
          .mov-hero { padding: 28px 24px; }
          .mov-hero-title { font-size: 1.4rem; }
          .mov-hero-deco { display: none; }
        }
      `}</style>

      <div className="mov-root">
        <div className="mov-inner">

          {/* Hero */}
          <div className="mov-hero">
            <h1 className="mov-hero-title">Movimientos de Inventario</h1>
            <p className="mov-hero-sub">Gestiona y visualiza todas las entradas, salidas y ajustes del sistema</p>
            <div className="mov-hero-deco">▲</div>
          </div>

          {/* Stats */}
          <div className="mov-stats">
            <div className="mov-stat">
              <div className="mov-stat-icon" style={{ background: "#ede9fe" }}><span style={{ fontSize: "1.4rem" }}>⇄</span></div>
              <div>
                <div className="mov-stat-label">Total</div>
                <div className="mov-stat-value">{movimientos.length}</div>
              </div>
            </div>
            <div className="mov-stat">
              <div className="mov-stat-icon" style={{ background: "#d1fae5" }}><span style={{ fontSize: "1.4rem" }}>↓</span></div>
              <div>
                <div className="mov-stat-label">Entradas</div>
                <div className="mov-stat-value" style={{ color: "#065f46" }}>{totalEntradas}</div>
              </div>
            </div>
            <div className="mov-stat">
              <div className="mov-stat-icon" style={{ background: "#fef3c7" }}><span style={{ fontSize: "1.4rem" }}>↑</span></div>
              <div>
                <div className="mov-stat-label">Salidas</div>
                <div className="mov-stat-value" style={{ color: "#92400e" }}>{totalSalidas}</div>
              </div>
            </div>
          </div>

          {/* Toolbar */}
          <div className="mov-toolbar">
            <div className="mov-search-wrap">
              <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
              </svg>
              <input
                className="mov-search"
                type="text"
                placeholder="Buscar por persona, producto, motivo…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <select className="mov-filter" value={filtroTipo} onChange={(e) => setFiltroTipo(e.target.value)}>
              <option value="Todos">Todos los tipos</option>
              <option value="Entrada">Entrada (Producción)</option>
              <option value="Salida">Salida (Venta)</option>
              <option value="Ajuste">Ajuste</option>
              <option value="Devolucion">Devolución</option>
            </select>
          </div>

          {/* Section header con botón reporte */}
          <div className="mov-section-header">
            <h2 className="mov-section-title">Registro de movimientos</h2>
            <div className="mov-section-right">
              <span className="mov-count-badge">{movimientosFiltrados.length} resultado{movimientosFiltrados.length !== 1 ? "s" : ""}</span>
              <button
                className="mov-btn-reporte"
                onClick={handleGenerarReporte}
                disabled={generandoPDF}
              >
                {generandoPDF ? (
                  <>
                    <div className="mov-spinner-sm" />
                    Generando...
                  </>
                ) : (
                  <>
                    <i className="bi bi-file-earmark-pdf-fill"></i>
                    Reporte Movimientos
                  </>
                )}
              </button>
            </div>
          </div>

          {/* List */}
          {movimientosFiltrados.length === 0 ? (
            <div className="mov-empty">
              <div className="mov-empty-icon">📭</div>
              <p className="mov-empty-text">{search || filtroTipo !== "Todos" ? "Sin resultados para esa búsqueda" : "No hay movimientos registrados"}</p>
              <p className="mov-empty-sub">{search ? "Intenta con otro término o cambia el filtro" : ""}</p>
            </div>
          ) : (
            movimientosFiltrados.map((mov, index) => {
              const tipo = getTipo(mov.Tipo);
              return (
                <div key={mov.idMovimiento} className="mov-card" onClick={() => verDetalles(mov, index + 1)}>
                  <div className="mov-card-inner">
                    <div className="mov-card-accent" style={{ background: tipo.color }} />
                    <div className="mov-card-body">
                      <div className="mov-card-top">
                        <div className="mov-card-left">
                          <span className="mov-num">#{String(index + 1).padStart(3, "0")}</span>
                          <span className="mov-badge" style={{ background: tipo.bg, color: tipo.color }}>
                            <span className="mov-badge-dot" style={{ background: tipo.color }} />
                            {tipo.label}
                          </span>
                        </div>
                        <span className="mov-card-arrow">→</span>
                      </div>
                      <div className="mov-chips">
                        <span className="mov-chip"><span className="mov-chip-icon">📅</span>{formatearFecha(mov.Fecha)}</span>
                        <span className="mov-chip"><span className="mov-chip-icon">📦</span>{getDescripcionProducto(mov.Producto_FK)}</span>
                        <span className="mov-chip"><span className="mov-chip-icon">#</span>{mov.Cantidad} uds.</span>
                        <span className="mov-chip"><span className="mov-chip-icon">👤</span>{getNombrePersona(mov.Persona_FK)}</span>
                      </div>
                      {mov.Motivo && <div className="mov-motivo">"{mov.Motivo}"</div>}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Modal */}
      {mostrarModal && movimientoSeleccionado && (
        <div className="mov-overlay" onClick={cerrarModal}>
          <div className="mov-modal" onClick={(e) => e.stopPropagation()}>
            <div className="mov-modal-header">
              <div>
                <h2 className="mov-modal-title">Detalle del Movimiento</h2>
                <p className="mov-modal-sub">#{String(movimientoSeleccionado.numeroSecuencial).padStart(3, "0")}</p>
              </div>
              <button className="mov-modal-close" onClick={cerrarModal}>✕</button>
            </div>

            <div className="mov-modal-body">
              <div className="mov-info-grid">
                <div className="mov-info-block">
                  <div className="mov-info-label">Tipo</div>
                  <div className="mov-info-value">
                    {(() => { const t = getTipo(movimientoSeleccionado.Tipo); return (
                      <span className="mov-badge" style={{ background: t.bg, color: t.color }}>
                        <span className="mov-badge-dot" style={{ background: t.color }} />{t.label}
                      </span>
                    ); })()}
                  </div>
                </div>
                <div className="mov-info-block">
                  <div className="mov-info-label">Fecha</div>
                  <div className="mov-info-value">📅 {formatearFecha(movimientoSeleccionado.Fecha)}</div>
                </div>
                <div className="mov-info-block">
                  <div className="mov-info-label">Cantidad</div>
                  <div className="mov-info-value">📦 {movimientoSeleccionado.Cantidad} unidades</div>
                </div>
                <div className="mov-info-block">
                  <div className="mov-info-label">Responsable</div>
                  <div className="mov-info-value">👤 {getNombrePersona(movimientoSeleccionado.Persona_FK)}</div>
                </div>
                <div className="mov-info-block full">
                  <div className="mov-info-label">Producto</div>
                  <div className="mov-info-value">🏷️ {getDescripcionProducto(movimientoSeleccionado.Producto_FK)}</div>
                </div>
                {movimientoSeleccionado.Motivo && (
                  <div className="mov-info-block full">
                    <div className="mov-info-label">Motivo</div>
                    <div className="mov-info-value" style={{ fontStyle: "italic", color: "#5b21b6" }}>"{movimientoSeleccionado.Motivo}"</div>
                  </div>
                )}
              </div>

             {movimientoSeleccionado.Tipo === "Entrada" && renderContenidoProduccion()}
            </div>

            <div className="mov-modal-footer">
              <button className="mov-btn-close" onClick={cerrarModal}>Cerrar</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}