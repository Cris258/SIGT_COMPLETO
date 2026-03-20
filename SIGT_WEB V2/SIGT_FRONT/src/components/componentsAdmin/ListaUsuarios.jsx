import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarUsuario from "../componentesListas/ModalEditarUsuario";
import ModalEliminar from "../componentesListas/ModalEliminarUsuario";

const ROLES = ["Todos", "SuperAdmin", "Administrador", "Empleado", "Cliente"];
const POR_PAGINA = 15;

export default function ListaUsuarios() {
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [usuarioSeleccionado, setUsuarioSeleccionado] = useState(null);
  const [search, setSearch] = useState("");
  const [rolFiltro, setRolFiltro] = useState("Todos");
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
        if (!res.ok) throw new Error("Error al obtener usuarios");
        return res.json();
      })
      .then((data) => {
        setUsuarios(data.body);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const abrirModalEditar = (usuario) => {
    setUsuarioSeleccionado(usuario);
    setMostrarModalEditar(true);
  };

  const cerrarModalEditar = () => {
    setMostrarModalEditar(false);
    setUsuarioSeleccionado(null);
  };

  const handleGuardarEdicion = (usuarioActualizado) => {
    setUsuarios((prev) =>
      prev.map((u) =>
        u.idPersona === usuarioActualizado.idPersona ? usuarioActualizado : u
      )
    );
  };

  const abrirModalEliminar = (usuario) => {
    setUsuarioSeleccionado(usuario);
    setMostrarModalEliminar(true);
  };

  const cerrarModalEliminar = () => {
    setMostrarModalEliminar(false);
    setUsuarioSeleccionado(null);
  };

  const handleConfirmarEliminacion = (usuarioEliminado) => {
    setUsuarios((prev) =>
      prev.filter((u) => u.idPersona !== usuarioEliminado.idPersona)
    );
  };

  const usuariosFiltrados = usuarios.filter((u) => {
    const matchSearch =
      (u.NumeroDocumento?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.TipoDocumento || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Primer_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Segundo_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Primer_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Segundo_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Rol?.NombreRol || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Telefono || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.Correo || "").toLowerCase().includes(search.toLowerCase());

    const matchRol =
      rolFiltro === "Todos" ||
      (u.Rol?.NombreRol || "").toLowerCase() === rolFiltro.toLowerCase();

    return matchSearch && matchRol;
  });

  // ── Paginación ──
  const totalPaginas = Math.max(1, Math.ceil(usuariosFiltrados.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const usuariosPagina = usuariosFiltrados.slice(inicio, inicio + POR_PAGINA);

  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };
  const handleRol = (val) => { setRolFiltro(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando usuarios...</p>
      </div>
    );
  }

  // ── SVG arrow para el select (sin comillas mezcladas) ──
  const selectArrowSvg = `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%239b59b6' d='M6 8L1 3h10z'/%3E%3C/svg%3E")`;

  return (
    <>
      <style>{`
        .lu-wrapper {
          padding: 40px 32px;
          min-height: 100vh;
        }

        /* ── Tarjeta ── */
        .lu-card {
          background: rgba(253, 242, 255, 0.60);
          backdrop-filter: blur(14px);
          -webkit-backdrop-filter: blur(14px);
          border: 1.5px solid rgba(196, 140, 230, 0.22);
          border-radius: 20px;
          box-shadow: 0 8px 40px rgba(160, 80, 200, 0.12);
          overflow: hidden;
        }

        /* ── Header ── */
        .lu-header {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          padding: 26px 32px 20px;
        }
        .lu-header h2 {
          color: #fff;
          font-weight: 700;
          font-size: 1.45rem;
          margin: 0 0 4px;
        }
        .lu-header p {
          color: rgba(255,255,255,0.80);
          margin: 0;
          font-size: 0.88rem;
        }
        .lu-counter {
          background: rgba(255,255,255,0.22);
          color: #fff;
          border-radius: 20px;
          padding: 4px 16px;
          font-size: 0.82rem;
          font-weight: 700;
          white-space: nowrap;
        }

        /* ── Filtros ── */
        .lu-filters {
          padding: 20px 24px 6px;
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          align-items: center;
        }
        .lu-search-wrap {
          position: relative;
          flex: 1;
        }
        .lu-search-icon {
          position: absolute;
          left: 13px;
          top: 50%;
          transform: translateY(-50%);
          color: #b06ac4;
          font-size: 1rem;
          pointer-events: none;
        }
        .lu-search {
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
        .lu-search:focus {
          border-color: #9b59b6;
          box-shadow: 0 0 0 3px rgba(155,89,182,0.14);
          background: #fff;
        }
        .lu-select {
          border: 1.8px solid #e8d0f8;
          border-radius: 10px;
          padding: 9px 36px 9px 14px;
          font-size: 0.9rem;
          background-color: rgba(255,255,255,0.75);
          background-repeat: no-repeat;
          background-position: right 12px center;
          color: #3d1a5c;
          font-weight: 600;
          outline: none;
          cursor: pointer;
          appearance: none;
          -webkit-appearance: none;
          min-width: 175px;
          transition: border-color 0.2s, box-shadow 0.2s;
        }
        .lu-select:focus {
          border-color: #9b59b6;
          box-shadow: 0 0 0 3px rgba(155,89,182,0.14);
          background-color: #fff;
        }

        /* ── Tabla ── */
        .lu-scroll {
          overflow-x: auto;
          padding: 16px 20px 28px;
        }
        .lu-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          font-size: 0.855rem;
        }
        .lu-table thead th {
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
        .lu-table tbody tr {
          transition: background 0.15s;
        }
        .lu-table tbody tr:nth-child(even) {
          background: rgba(245, 220, 255, 0.20);
        }
        .lu-table tbody tr:hover {
          background: rgba(230, 190, 255, 0.32);
        }
        .lu-table tbody td {
          padding: 10px 13px;
          border-bottom: 1px solid rgba(210, 160, 240, 0.18);
          color: #2d1a40;
          vertical-align: middle;
          white-space: nowrap;
        }
        .lu-table tbody tr:last-child td {
          border-bottom: none;
        }

        /* ── Chips ── */
        .chip-id {
          background: rgba(200, 140, 240, 0.18);
          color: #6a1b8a;
          border-radius: 6px;
          padding: 2px 10px;
          font-weight: 700;
          font-size: 0.8rem;
        }
        .chip-rol {
          background: rgba(200, 140, 240, 0.18);
          color: #5b2182;
          border-radius: 6px;
          padding: 3px 10px;
          font-size: 0.78rem;
          font-weight: 600;
        }
        .badge-activo {
          background: #d1fae5;
          color: #065f46;
          border-radius: 20px;
          padding: 4px 12px;
          font-size: 0.77rem;
          font-weight: 700;
          display: inline-flex;
          align-items: center;
          gap: 5px;
        }
        .badge-inactivo {
          background: #fee2e2;
          color: #991b1b;
          border-radius: 20px;
          padding: 4px 12px;
          font-size: 0.77rem;
          font-weight: 700;
          display: inline-flex;
          align-items: center;
          gap: 5px;
        }
        .badge-activo::before   { content: "●"; font-size: 0.55rem; }
        .badge-inactivo::before { content: "●"; font-size: 0.55rem; }

        /* ── Botones acción ── */
        .btn-edit {
          background: #eff6ff;
          border: 1.5px solid #bfdbfe;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .btn-edit:hover {
          background: #dbeafe;
          border-color: #3b82f6;
          transform: scale(1.1);
        }
        .btn-del {
          background: #fff5f5;
          border: 1.5px solid #fecaca;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .btn-del:hover {
          background: #fee2e2;
          border-color: #ef4444;
          transform: scale(1.1);
        }

        /* ── Empty ── */
        .lu-empty {
          text-align: center;
          padding: 52px 20px;
        }
        .lu-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .lu-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .lu-empty small { color: #c8a0e0; }

        /* ── Paginador ── */
        .lu-pagination {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          padding: 0 24px 24px;
          flex-wrap: wrap;
        }
        .lu-page-info {
          text-align: center;
          font-size: 0.8rem;
          color: #9b59b6;
          font-weight: 600;
          padding: 0 24px 10px;
        }
        .pg-btn {
          width: 36px;
          height: 36px;
          border-radius: 9px;
          border: 1.8px solid #e8d0f8;
          background: rgba(255,255,255,0.75);
          color: #6a1b8a;
          font-weight: 700;
          font-size: 0.85rem;
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
        }
        .pg-btn:hover:not(:disabled) {
          background: rgba(200,140,240,0.22);
          border-color: #9b59b6;
          transform: scale(1.07);
        }
        .pg-btn:disabled {
          opacity: 0.35;
          cursor: not-allowed;
        }
        .pg-btn.active {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          border-color: #9b45c7;
          color: #fff;
          box-shadow: 0 3px 10px rgba(155,69,199,0.3);
        }
        .pg-arrow {
          width: 36px;
          height: 36px;
          border-radius: 9px;
          border: 1.8px solid #e8d0f8;
          background: rgba(255,255,255,0.75);
          color: #6a1b8a;
          font-size: 1.1rem;
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
          font-weight: 700;
        }
        .pg-arrow:hover:not(:disabled) {
          background: rgba(200,140,240,0.22);
          border-color: #9b59b6;
          transform: scale(1.07);
        }
        .pg-arrow:disabled {
          opacity: 0.35;
          cursor: not-allowed;
        }
      `}</style>

      <div className="lu-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
          <div className="lu-card">

            {/* ── Header ── */}
            <div className="lu-header">
              <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                  <h2 className="merriweather-font">
                    <i className="bi bi-people-fill me-2"></i>
                    Lista de Usuarios Registrados
                  </h2>
                  <p>Gestiona, edita y elimina los usuarios del sistema</p>
                </div>
                <span className="lu-counter">
                  {usuariosFiltrados.length} usuario{usuariosFiltrados.length !== 1 ? "s" : ""}
                </span>
              </div>
            </div>

            {/* ── Filtros ── */}
            <div className="lu-filters">
              <div className="lu-search-wrap">
                <i className="bi bi-search lu-search-icon"></i>
                <input
                  type="text"
                  className="lu-search"
                  placeholder="Buscar por nombre, correo, documento..."
                  value={search}
                  onChange={(e) => handleSearch(e.target.value)}
                />
              </div>

              {/* ── El backgroundImage del select se pasa como prop de estilo para evitar conflictos de escape ── */}
              <select
                className="lu-select"
                value={rolFiltro}
                onChange={(e) => handleRol(e.target.value)}
                style={{ backgroundImage: selectArrowSvg }}
              >
                {ROLES.map((r) => (
                  <option key={r} value={r}>
                    {r === "Todos" ? "Todos los roles" : r}
                  </option>
                ))}
              </select>
            </div>

            {/* ── Tabla ── */}
            <div className="lu-scroll">
              <table className="lu-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>N° Documento</th>
                    <th>Tipo Doc.</th>
                    <th>Primer Nombre</th>
                    <th>Segundo Nombre</th>
                    <th>Primer Apellido</th>
                    <th>Segundo Apellido</th>
                    <th>Rol</th>
                    <th>Teléfono</th>
                    <th>Correo</th>
                    <th>Estado</th>
                    <th>Editar</th>
                    <th>Eliminar</th>
                  </tr>
                </thead>
                <tbody>
                  {usuariosPagina.length > 0 ? (
                    usuariosPagina.map((u, index) => (
                      <tr key={u.idPersona}>
                        <td><span className="chip-id">{inicio + index + 1}</span></td>
                        <td>{u.NumeroDocumento}</td>
                        <td>{u.TipoDocumento}</td>
                        <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{u.Primer_Nombre}</td>
                        <td>{u.Segundo_Nombre}</td>
                        <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{u.Primer_Apellido}</td>
                        <td>{u.Segundo_Apellido}</td>
                        <td><span className="chip-rol">{u.Rol?.NombreRol || "Sin rol"}</span></td>
                        <td>{u.Telefono}</td>
                        <td style={{ color: "#7c3aad" }}>{u.Correo}</td>
                        <td>
                          {u.EstadoPersona_FK === 1
                            ? <span className="badge-activo">Activo</span>
                            : <span className="badge-inactivo">Inactivo</span>
                          }
                        </td>
                        <td>
                          <button className="btn-edit" onClick={() => abrirModalEditar(u)} title="Editar">
                            <img src="img/editar3.png" width="22" height="22" alt="Editar" />
                          </button>
                        </td>
                        <td>
                          <button className="btn-del" onClick={() => abrirModalEliminar(u)} title="Eliminar">
                            <img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="13">
                        <div className="lu-empty">
                          <i className="bi bi-inbox"></i>
                          <p>
                            {search || rolFiltro !== "Todos"
                              ? "No se encontraron resultados"
                              : "No hay usuarios registrados"}
                          </p>
                          {(search || rolFiltro !== "Todos") && (
                            <small>Intenta con otro término o cambia el filtro de rol</small>
                          )}
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
                <p className="lu-page-info">
                  Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, usuariosFiltrados.length)} de {usuariosFiltrados.length} usuarios
                </p>
                <div className="lu-pagination">
                  <button className="pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1} title="Primera">«</button>
                  <button className="pg-arrow" onClick={() => setPaginaActual(p => p - 1)} disabled={paginaSegura === 1} title="Anterior">‹</button>

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
                          className={`pg-btn${paginaSegura === item ? " active" : ""}`}
                          onClick={() => setPaginaActual(item)}
                        >{item}</button>
                      )
                    )
                  }

                  <button className="pg-arrow" onClick={() => setPaginaActual(p => p + 1)} disabled={paginaSegura === totalPaginas} title="Siguiente">›</button>
                  <button className="pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas} title="Última">»</button>
                </div>
              </>
            )}

          </div>
        </div>
      </div>

      {/* Modal Editar */}
      {mostrarModalEditar && (
        <ModalEditarUsuario
          usuario={usuarioSeleccionado}
          onClose={cerrarModalEditar}
          onGuardar={handleGuardarEdicion}
        />
      )}

      {/* Modal Eliminar */}
      {mostrarModalEliminar && (
        <ModalEliminar
          usuario={usuarioSeleccionado}
          onClose={cerrarModalEliminar}
          onConfirmar={handleConfirmarEliminacion}
          tipoUsuario="usuario"
        />
      )}
    </>
  );
}