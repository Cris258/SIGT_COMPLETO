import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import ModalEditarUsuario from "../componentesListas/ModalEditarUsuario";
import ModalEliminar from "../componentesListas/ModalEliminarUsuario";

const POR_PAGINA = 4;

export default function ListaEmpleados() {
  const [empleados, setEmpleados] = useState([]);
  const [loading, setLoading] = useState(true);
  const [empleadoSeleccionado, setEmpleadoSeleccionado] = useState(null);
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
        if (!res.ok) throw new Error("Error al obtener Empleados");
        return res.json();
      })
      .then((data) => {
        // Filtrar solo empleados
        const soloEmpleados = data.body.filter(
          (persona) => persona.Rol?.NombreRol?.toLowerCase() === "empleado"
        );
        setEmpleados(soloEmpleados);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const abrirModalEditar = (empleado) => {
    setEmpleadoSeleccionado(empleado);
    setMostrarModalEditar(true);
  };

  const cerrarModalEditar = () => {
    setMostrarModalEditar(false);
    setEmpleadoSeleccionado(null);
  };

  const handleGuardarEdicion = (empleadoActualizado) => {
    setEmpleados((prev) =>
      prev.map((e) =>
        e.idPersona === empleadoActualizado.idPersona ? empleadoActualizado : e
      )
    );
  };

  const abrirModalEliminar = (empleado) => {
    setEmpleadoSeleccionado(empleado);
    setMostrarModalEliminar(true);
  };

  const cerrarModalEliminar = () => {
    setMostrarModalEliminar(false);
    setEmpleadoSeleccionado(null);
  };

  const handleConfirmarEliminacion = (empleadoEliminado) => {
    setEmpleados((prev) =>
      prev.filter((e) => e.idPersona !== empleadoEliminado.idPersona)
    );
  };

  const empleadosFiltrados = empleados.filter(
    (e) =>
      (e.NumeroDocumento?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.TipoDocumento || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Primer_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Segundo_Nombre || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Primer_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Segundo_Apellido || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Telefono || "").toLowerCase().includes(search.toLowerCase()) ||
      (e.Correo || "").toLowerCase().includes(search.toLowerCase())
  );

  // ── Paginación ──
  const totalPaginas = Math.max(1, Math.ceil(empleadosFiltrados.length / POR_PAGINA));
  const paginaSegura = Math.min(paginaActual, totalPaginas);
  const inicio = (paginaSegura - 1) * POR_PAGINA;
  const empleadosPagina = empleadosFiltrados.slice(inicio, inicio + POR_PAGINA);

  const handleSearch = (val) => { setSearch(val); setPaginaActual(1); };

  if (loading) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: "60vh" }}>
        <div className="spinner-border mb-3" style={{ width: 48, height: 48, color: "#9b59b6" }} role="status" />
        <p style={{ color: "#9b59b6", fontWeight: 600 }}>Cargando empleados...</p>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .le-wrapper {
          padding: 40px 32px;
          min-height: 100vh;
        }

        /* ── Tarjeta ── */
        .le-card {
          background: rgba(253, 242, 255, 0.60);
          backdrop-filter: blur(14px);
          -webkit-backdrop-filter: blur(14px);
          border: 1.5px solid rgba(196, 140, 230, 0.22);
          border-radius: 20px;
          box-shadow: 0 8px 40px rgba(160, 80, 200, 0.12);
          overflow: hidden;
        }

        /* ── Header ── */
        .le-header {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          padding: 26px 32px 20px;
        }
        .le-header h2 {
          color: #fff;
          font-weight: 700;
          font-size: 1.45rem;
          margin: 0 0 4px;
        }
        .le-header p {
          color: rgba(255,255,255,0.80);
          margin: 0;
          font-size: 0.88rem;
        }
        .le-counter {
          background: rgba(255,255,255,0.22);
          color: #fff;
          border-radius: 20px;
          padding: 4px 16px;
          font-size: 0.82rem;
          font-weight: 700;
          white-space: nowrap;
        }

        /* ── Filtros ── */
        .le-filters {
          padding: 20px 24px 6px;
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          align-items: center;
        }
        .le-search-wrap {
          position: relative;
          flex: 1;
        }
        .le-search-icon {
          position: absolute;
          left: 13px;
          top: 50%;
          transform: translateY(-50%);
          color: #b06ac4;
          font-size: 1rem;
          pointer-events: none;
        }
        .le-search {
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
        .le-search:focus {
          border-color: #9b59b6;
          box-shadow: 0 0 0 3px rgba(155,89,182,0.14);
          background: #fff;
        }

        /* ── Tabla ── */
        .le-scroll {
          overflow-x: auto;
          padding: 16px 20px 28px;
        }
        .le-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          font-size: 0.855rem;
        }
        .le-table thead th {
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
        .le-table tbody tr {
          transition: background 0.15s;
        }
        .le-table tbody tr:nth-child(even) {
          background: rgba(245, 220, 255, 0.20);
        }
        .le-table tbody tr:hover {
          background: rgba(230, 190, 255, 0.32);
        }
        .le-table tbody td {
          padding: 10px 13px;
          border-bottom: 1px solid rgba(210, 160, 240, 0.18);
          color: #2d1a40;
          vertical-align: middle;
          white-space: nowrap;
        }
        .le-table tbody tr:last-child td {
          border-bottom: none;
        }

        /* ── Chips ── */
        .le-chip-id {
          background: rgba(200, 140, 240, 0.18);
          color: #6a1b8a;
          border-radius: 6px;
          padding: 2px 10px;
          font-weight: 700;
          font-size: 0.8rem;
        }
        .le-chip-rol {
          background: rgba(200, 140, 240, 0.18);
          color: #5b2182;
          border-radius: 6px;
          padding: 3px 10px;
          font-size: 0.78rem;
          font-weight: 600;
        }
        .le-badge-activo {
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
        .le-badge-inactivo {
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
        .le-badge-activo::before   { content: "●"; font-size: 0.55rem; }
        .le-badge-inactivo::before { content: "●"; font-size: 0.55rem; }

        /* ── Botones acción ── */
        .le-btn-edit {
          background: #eff6ff;
          border: 1.5px solid #bfdbfe;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .le-btn-edit:hover {
          background: #dbeafe;
          border-color: #3b82f6;
          transform: scale(1.1);
        }
        .le-btn-del {
          background: #fff5f5;
          border: 1.5px solid #fecaca;
          border-radius: 9px;
          padding: 5px 9px;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
          display: inline-flex;
        }
        .le-btn-del:hover {
          background: #fee2e2;
          border-color: #ef4444;
          transform: scale(1.1);
        }

        /* ── Empty ── */
        .le-empty {
          text-align: center;
          padding: 52px 20px;
        }
        .le-empty i { font-size: 2.8rem; display: block; margin-bottom: 10px; color: #c8a0e0; }
        .le-empty p { margin: 0; font-weight: 600; color: #7c3aad; }
        .le-empty small { color: #c8a0e0; }

        /* ── Paginador ── */
        .le-pagination {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          padding: 0 24px 24px;
          flex-wrap: wrap;
        }
        .le-page-info {
          text-align: center;
          font-size: 0.8rem;
          color: #9b59b6;
          font-weight: 600;
          padding: 0 24px 10px;
        }
        .le-pg-btn {
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
        .le-pg-btn:hover:not(:disabled) {
          background: rgba(200,140,240,0.22);
          border-color: #9b59b6;
          transform: scale(1.07);
        }
        .le-pg-btn:disabled { opacity: 0.35; cursor: not-allowed; }
        .le-pg-btn.active {
          background: linear-gradient(135deg, #c084e0 0%, #9b45c7 100%);
          border-color: #9b45c7;
          color: #fff;
          box-shadow: 0 3px 10px rgba(155,69,199,0.3);
        }
        .le-pg-arrow {
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
        .le-pg-arrow:hover:not(:disabled) {
          background: rgba(200,140,240,0.22);
          border-color: #9b59b6;
          transform: scale(1.07);
        }
        .le-pg-arrow:disabled { opacity: 0.35; cursor: not-allowed; }
      `}</style>

      <div className="le-wrapper">
        <div className="container-fluid px-4" style={{ maxWidth: 1400, margin: "0 auto" }}>
        <div className="le-card">

          {/* ── Header ── */}
          <div className="le-header">
            <div className="d-flex justify-content-between align-items-start flex-wrap gap-2">
              <div>
                <h2 className="merriweather-font">
                  <i className="bi bi-person-badge-fill me-2"></i>
                  Lista de Empleados Registrados
                </h2>
                <p>Gestiona, edita y elimina los empleados del sistema</p>
              </div>
              <span className="le-counter">
                {empleadosFiltrados.length} empleado{empleadosFiltrados.length !== 1 ? "s" : ""}
              </span>
            </div>
          </div>

          {/* ── Buscador ── */}
          <div className="le-filters">
            <div className="le-search-wrap">
              <i className="bi bi-search le-search-icon"></i>
              <input
                type="text"
                className="le-search"
                placeholder="Buscar por nombre, correo, documento..."
                value={search}
                onChange={(e) => handleSearch(e.target.value)}
              />
            </div>
          </div>

          {/* ── Tabla ── */}
          <div className="le-scroll">
            <table className="le-table">
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
                {empleadosPagina.length > 0 ? (
                  empleadosPagina.map((e, index) => (
                    <tr key={e.idPersona}>
                      <td><span className="le-chip-id">{inicio + index + 1}</span></td>
                      <td>{e.NumeroDocumento}</td>
                      <td>{e.TipoDocumento}</td>
                      <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{e.Primer_Nombre}</td>
                      <td>{e.Segundo_Nombre}</td>
                      <td style={{ fontWeight: 600, color: "#3d1a5c" }}>{e.Primer_Apellido}</td>
                      <td>{e.Segundo_Apellido}</td>
                      <td><span className="le-chip-rol">{e.Rol?.NombreRol || "Sin rol"}</span></td>
                      <td>{e.Telefono}</td>
                      <td style={{ color: "#7c3aad" }}>{e.Correo}</td>
                      <td>
                        {e.EstadoPersona_FK === 1
                          ? <span className="le-badge-activo">Activo</span>
                          : <span className="le-badge-inactivo">Inactivo</span>
                        }
                      </td>
                      <td>
                        <button className="le-btn-edit" onClick={() => abrirModalEditar(e)} title="Editar">
                          <img src="img/editar3.png" width="22" height="22" alt="Editar" />
                        </button>
                      </td>
                      <td>
                        <button className="le-btn-del" onClick={() => abrirModalEliminar(e)} title="Eliminar">
                          <img src="img/eliminar2.png" width="22" height="22" alt="Eliminar" />
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="13">
                      <div className="le-empty">
                        <i className="bi bi-inbox"></i>
                        <p>{search ? "No se encontraron resultados" : "No hay empleados registrados"}</p>
                        {search && <small>Intenta con otro término de búsqueda</small>}
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>{/* fin le-scroll */}

          {/* ── Paginador ── */}
          {totalPaginas > 1 && (
            <>
              <p className="le-page-info">
                Mostrando {inicio + 1}–{Math.min(inicio + POR_PAGINA, empleadosFiltrados.length)} de {empleadosFiltrados.length} empleados
              </p>
              <div className="le-pagination">
                <button className="le-pg-arrow" onClick={() => setPaginaActual(1)} disabled={paginaSegura === 1} title="Primera">«</button>
                <button className="le-pg-arrow" onClick={() => setPaginaActual(p => p - 1)} disabled={paginaSegura === 1} title="Anterior">‹</button>

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
</span>                    ) : (
                      <button
                        key={item}
                        className={`le-pg-btn${paginaSegura === item ? " active" : ""}`}
                        onClick={() => setPaginaActual(item)}
                      >{item}</button>
                    )
                  )
                }

                <button className="le-pg-arrow" onClick={() => setPaginaActual(p => p + 1)} disabled={paginaSegura === totalPaginas} title="Siguiente">›</button>
                <button className="le-pg-arrow" onClick={() => setPaginaActual(totalPaginas)} disabled={paginaSegura === totalPaginas} title="Última">»</button>
              </div>
            </>
          )}

        </div>{/* fin le-card */}
        </div>
      </div>

      {/* Modal Editar */}
      {mostrarModalEditar && (
        <ModalEditarUsuario
          usuario={empleadoSeleccionado}
          onClose={cerrarModalEditar}
          onGuardar={handleGuardarEdicion}
        />
      )}

      {/* Modal Eliminar */}
      {mostrarModalEliminar && (
        <ModalEliminar
          usuario={empleadoSeleccionado}
          onClose={cerrarModalEliminar}
          onConfirmar={handleConfirmarEliminacion}
          tipoUsuario="empleado"
        />
      )}
    </>
  );
}