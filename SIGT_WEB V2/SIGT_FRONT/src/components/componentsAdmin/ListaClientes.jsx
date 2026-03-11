import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarUsuario from "../componentesListas/ModalEditarUsuario";
import ModalEliminar from "../componentesListas/ModalEliminarUsuario";

const POR_PAGINA = 4;

export default function ListarClientes() {
  const [clientes, setClientes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [clienteSeleccionado, setClienteSeleccionado] = useState(null);
  const [search, setSearch] = useState("");
  const [mostrarModalEditar, setMostrarModalEditar] = useState(false);
  const [mostrarModalEliminar, setMostrarModalEliminar] = useState(false);
  const [paginaActual, setPaginaActual] = useState(1);

  useEffect(() => {
    const token = localStorage.getItem("token");

    fetch(`${import.meta.env.VITE_API_URL}/api/persona`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    })
      .then((res) => {
        if (!res.ok) throw new Error("Error al obtener Clientes");
        return res.json();
      })
      .then((data) => {
        const soloClientes = data.body.filter(
          (persona) => persona.Rol?.NombreRol?.toLowerCase() === "cliente"
        );
        setClientes(soloClientes);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const abrirModalEditar = (cliente) => { setClienteSeleccionado(cliente); setMostrarModalEditar(true); };
  const cerrarModalEditar = () => { setMostrarModalEditar(false); setClienteSeleccionado(null); };
  const handleGuardarEdicion = (clienteActualizado) => {
    setClientes((prev) => prev.map((c) => c.idPersona === clienteActualizado.idPersona ? clienteActualizado : c));
  };
  const abrirModalEliminar = (cliente) => { setClienteSeleccionado(cliente); setMostrarModalEliminar(true); };
  const cerrarModalEliminar = () => { setMostrarModalEliminar(false); setClienteSeleccionado(null); };
  const handleConfirmarEliminacion = (clienteEliminado) => {
    setClientes((prev) => prev.filter((c) => c.idPersona !== clienteEliminado.idPersona));
  };

  const clientesFiltrados = clientes.filter(
    (c) =>
      (c.NumeroDocumento?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.TipoDocumento || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Primer_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Segundo_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Primer_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Segundo_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Telefono || "").toLowerCase().includes(search.toLowerCase()) ||
      (c.Correo || "").toLowerCase().includes(search.toLowerCase())
  );

  const totalPaginas = Math.max(1, Math.ceil(clientesFiltrados.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const clientesPagina = clientesFiltrados.slice(inicio, inicio + POR_PAGINA);
  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando clientes...</p>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .lc-wrapper { padding: 40px 32px; min-height: 100vh; }
        .lc-card { background: rgba(253,242,255,0.60); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); border: 1.5px solid rgba(196,140,230,0.22); border-radius: 20px; box-shadow: 0 8px 40px rgba(160,80,200,0.12); overflow: hidden; }
        .lc-header { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); padding: 26px 32px 20px; }
        .lc-header h2 { color: #fff; font-weight: 700; font-size: 1.45rem; margin: 0 0 4px; }
        .lc-header p { color: rgba(255,255,255,0.80); margin: 0; font-size: 0.88rem; }
        .lc-counter { background: rgba(255,255,255,0.22); color: #fff; border-radius: 20px; padding: 4px 16px; font-size: 0.82rem; font-weight: 700; white-space: nowrap; }
        .lc-filters { padding: 20px 24px 6px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
        .lc-search-wrap { position: relative; flex: 1; }
        .lc-search-icon { position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: #b06ac4; font-size: 1rem; pointer-events: none; }
        .lc-search { width: 100%; border: 1.8px solid #e8d0f8; border-radius: 10px; padding: 9px 14px 9px 40px; font-size: 0.93rem; background: rgba(255,255,255,0.75); color: #3d1a5c; outline: none; transition: border-color 0.2s, box-shadow 0.2s; }
        .lc-search:focus { border-color: #9b59b6; box-shadow: 0 0 0 3px rgba(155,89,182,0.14); background: #fff; }
        .lc-scroll { overflow-x: auto; padding: 16px 20px 28px; }
        .lc-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 0.855rem; }
        .lc-table thead th { background: rgba(210,160,240,0.18); color: #6a1b8a; font-weight: 700; font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.07em; padding: 11px 13px; border-bottom: 2px solid rgba(180,110,220,0.22); white-space: nowrap; }
        .lc-table tbody tr { transition: background 0.15s; }
        .lc-table tbody tr:nth-child(even) { background: rgba(245,220,255,0.20); }
        .lc-table tbody tr:hover { background: rgba(230,190,255,0.32); }
        .lc-table tbody td { padding: 10px 13px; border-bottom: 1px solid rgba(210,160,240,0.18); color: #2d1a40; vertical-align: middle; white-space: nowrap; }
        .lc-table tbody tr:last-child td { border-bottom: none; }
        .lc-chip-id { background: rgba(200,140,240,0.18); color: #6a1b8a; border-radius: 6px; padding: 2px 10px; font-weight: 700; font-size: 0.8rem; }
        .lc-chip-rol { background: rgba(200,140,240,0.18); color: #5b2182; border-radius: 6px; padding: 3px 10px; font-size: 0.78rem; font-weight: 600; }
        .lc-badge-activo { background: #d1fae5; color: #065f46; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lc-badge-inactivo { background: #fee2e2; color: #991b1b; border-radius: 20px; padding: 4px 12px; font-size: 0.77rem; font-weight: 700; display: inline-flex; align-items: center; gap: 5px; }
        .lc-badge-activo::before, .lc-badge-inactivo::before { content: "●"; font-size: 0.55rem; }
        .lc-btn-edit { background: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lc-btn-edit:hover { background: #dbeafe; border-color: #3b82f6; transform: scale(1.1); }
        .lc-btn-del { background: #fff5f5; border: 1.5px solid #fecaca; border-radius: 9px; padding: 5px 9px; cursor: pointer; transition: background 0.15s, transform 0.1s; display: inline-flex; }
        .lc-btn-del:hover { background: #fee2e2; border-color: #ef4444; transform: scale(1.1); }
        .lc-empty { text-align: center; padding: 52px 20px; }
        .lc-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .lc-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .lc-empty small { color: #c8a0e0; }
        .lc-page-info { text-align: center; font-size: 0.8rem; color: #9b59b6; font-weight: 600; padding: 0 24px 10px; }
        .lc-pagination { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 0 24px 24px; flex-wrap: wrap; }
        .lc-pg-btn { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-weight: 700; font-size: 0.85rem; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lc-pg-btn:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lc-pg-btn:disabled { opacity: 0.35; cursor: not-allowed; }
        .lc-pg-btn.active { background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%); border-color: #9b45c7; color: #fff; box-shadow: 0 3px 10px rgba(155,69,199,0.3); }
        .lc-pg-arrow { width: 36px; height: 36px; border-radius: 9px; border: 1.8px solid #e8d0f8; background: rgba(255,255,255,0.75); color: #6a1b8a; font-size: 1.1rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 0.15s; }
        .lc-pg-arrow:hover:not(:disabled) { background: rgba(200,140,240,0.22); border-color: #9b59b6; transform: scale(1.07); }
        .lc-pg-arrow:disabled { opacity: 0.35; cursor: not-allowed; }
      `}</style>

      <div className="lc-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
        <div className="lc-card">

          <div className="lc-header">
            <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
              <div>
                <h2 className="merriweather-font"><i className="bi bi-person-heart me-2"></i>Lista de Clientes Registrados</h2>
                <p>Gestiona, edita y elimina los clientes del sistema</p>
              </div>
              <span className="lc-counter">{clientesFiltrados.length} cliente{clientesFiltrados.length !== 1 ? "s" : ""}</span>
            </div>
          </div>

          <div className="lc-filters">
            <div className="lc-search-wrap">
              <i className="bi bi-search lc-search-icon"></i>
              <input type="text" className="lc-search" placeholder="Buscar por nombre, correo, documento..." value={search} onChange={(e) => handleSearch(e.target.value)} />
            </div>
          </div>

          <div className="lc-scroll">
            <table className="lc-table">
              <thead>
                <tr>
                  <th>#</th><th>N° Documento</th><th>Tipo Doc.</th><th>Primer Nombre</th>
                  <th>Segundo Nombre</th><th>Primer Apellido</th><th>Segundo Apellido</th>
                  <th>Rol</th><th>Teléfono</th><th>Correo</th><th>Estado</th><th>Editar</th><th>Eliminar</th>
                </tr>
              </thead>
              <tbody>
                {clientesPagina.length > 0 ? (
                  clientesPagina.map((c, index) => (
                    <tr key={c.idPersona}>
                      <td><span className="lc-chip-id">{inicio + index + 1}</span></td>
                      <td>{c.NumeroDocumento}</td>
                      <td>{c.TipoDocumento}</td>
                      <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{c.Primer_Nombre}</td>
                      <td>{c.Segundo_Nombre}</td>
                      <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{c.Primer_Apellido}</td>
                      <td>{c.Segundo_Apellido}</td>
                      <td><span className="lc-chip-rol">{c.Rol?.NombreRol || "Sin rol"}</span></td>
                      <td>{c.Telefono}</td>
                      <td style={{ color: "#7c3aad" }}>{c.Correo}</td>
                      <td>
                        {c.EstadoPersona_FK === 1
                          ? <span className="lc-badge-activo">Activo</span>
                          : <span className="lc-badge-inactivo">Inactivo</span>}
                      </td>
                      <td><button className="lc-btn-edit" onClick={() => abrirModalEditar(c)} title="Editar"><img src="img/editar3.png" width="22" height="22" alt="Editar" /></button></td>
                      <td><button className="lc-btn-del" onClick={() => abrirModalEliminar(c)} title="Eliminar"><img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" /></button></td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan="13"><div className="lc-empty"><i className="bi bi-inbox"></i><p>{search ? "No se encontraron resultados" : "No hay clientes registrados"}</p>{search && <small>Intenta con otro término</small>}</div></td></tr>
                )}
              </tbody>
            </table>
          </div>

         {totalPaginas > 1 && (
  <>
    <p className="lc-page-info">
      Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, clientesFiltrados.length)} de {clientesFiltrados.length} clientes
    </p>
    <div className="lc-pagination">
      <button className="lc-pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1}>«</button>
      <button className="lc-pg-arrow" onClick={() => setPaginaActual(p => p - 1)} disabled={paginaSegura === 1}>‹</button>

      {Array.from({ length: totalPaginas }, (_, i) => i + 1)
        .filter(n => n === 1 || n === totalPaginas || Math.abs(n - paginaSegura) <= 2)
        .reduce((acc, n, i, arr) => {
          if (i > 0 && n - arr[i - 1] > 1) {
            acc.push("...");
          }
          acc.push(n);
          return acc;
        }, [])
        .map((item, i) => {
          if (item === "...") {
            return (
              <span
                key={`ellipsis-${i === 1 ? "start" : "end"}`}
                style={{ color: "#b895d4", padding: "0 4px", lineHeight: "36px" }}
              >
                …
              </span>
            );
          }
          return (
            <button
              key={item}
              className={`lc-pg-btn${paginaSegura === item ? " active" : ""}`}
              onClick={() => setPaginaActual(item)}
            >
              {item}
            </button>
          );
        })}

      <button className="lc-pg-arrow" onClick={() => setPaginaActual(p => p + 1)} disabled={paginaSegura === totalPaginas}>›</button>
      <button className="lc-pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas}>»</button>
    </div>
  </>
)}

        </div>
        </div>
      </div>

      {mostrarModalEditar && <ModalEditarUsuario usuario={clienteSeleccionado} onClose={cerrarModalEditar} onGuardar={handleGuardarEdicion} />}
      {mostrarModalEliminar && <ModalEliminar usuario={clienteSeleccionado} onClose={cerrarModalEliminar} onConfirmar={handleConfirmarEliminacion} tipoUsuario="cliente" />}
    </>
  );
}