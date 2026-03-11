import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";

export default function ListaDiseños() {
  const [disenos, setDisenos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [disenoSeleccionado, setDisenoSeleccionado] = useState(null);
  const [accion, setAccion] = useState("");
  const [search, setSearch] = useState("");

  useEffect(() => {
    const token = localStorage.getItem("token");

    fetch(`${import.meta.env.VITE_API_URL}/api/diseno`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    })
      .then((res) => {
        if (!res.ok) throw new Error("Error al obtener diseños");
        return res.json();
      })
      .then((data) => {
        setDisenos(data.body);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const abrirModal = (diseno, tipoAccion) => {
    setDisenoSeleccionado(diseno);
    setAccion(tipoAccion);
    const modal = new window.bootstrap.Modal(
      document.getElementById("modalAccion")
    );
    modal.show();
  };

  const confirmarAccion = () => {
    if (accion === "eliminar") {
      setDisenos((prev) =>
        prev.filter((d) => d.idDiseño !== disenoSeleccionado.idDiseño)
      );
    } else if (accion === "editar") {
      alert("Aquí podrías implementar el formulario de edición.");
    }
    setDisenoSeleccionado(null);
  };

  const disenosFiltrados = disenos.filter(
    (d) =>
      (d.idDiseño?.toString() || "").toLowerCase().includes(search.toLowerCase()) ||
      (d.NombreDiseño || "").toLowerCase().includes(search.toLowerCase()) ||
      (d.Descripcion || "").toLowerCase().includes(search.toLowerCase()) ||
      (d.Precio?.toString() || "").toLowerCase().includes(search.toLowerCase())
  );

  const formatearPrecio = (precio) => {
    return new Intl.NumberFormat("es-CO", {
      style: "currency",
      currency: "COP",
      minimumFractionDigits: 0,
    }).format(precio);
  };

  if (loading) {
    return <p className="text-center mt-5">Cargando diseños...</p>;
  }

  return (
    <div className="container mt-5 d-flex flex-column align-items-center">
      <h2 className="text-center mb-4 merriweather-font">
        Lista de Diseños Registrados
      </h2>

      {/* Buscador */}
      <div className="row mb-3 w-100">
        <div className="col-12 col-md-6 mx-auto">
          <input
            type="text"
            className="form-control"
            placeholder="Buscar por nombre, descripción, precio..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <table className="table table-striped table-hover table-bordered table-responsive mt-3 w-auto text-center">
        <thead className="table-dark">
          <tr>
            <th>ID</th>
            <th>Nombre del Diseño</th>
            <th>Descripción</th>
            <th>Precio</th>
            <th>Modificar</th>
            <th>Eliminar</th>
          </tr>
        </thead>
        <tbody>
          {disenosFiltrados.length > 0 ? (
            disenosFiltrados.map((d) => (
              <tr key={d.idDiseño}>
                <td>{d.idDiseño}</td>
                <td>{d.NombreDiseño}</td>
                <td>{d.Descripcion}</td>
                <td>{formatearPrecio(d.Precio)}</td>
                <td>
                  <button
                    className="btn btn-outline-primary"
                    onClick={() => abrirModal(d, "editar")}
                  >
                    <img
                      src="img/editar3.png"
                      width="30"
                      height="30"
                      alt="Editar"
                    />
                  </button>
                </td>
                <td>
                  <button
                    className="btn btn-outline-danger"
                    onClick={() => abrirModal(d, "eliminar")}
                  >
                    <img
                      src="img/eliminar2.png"
                      width="30"
                      height="30"
                      alt="Eliminar"
                    />
                  </button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan="6" className="text-center">
                {search ? "No se encontraron resultados" : "No hay diseños registrados"}
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {/* Modal */}
      <div
        className="modal fade"
        id="modalAccion"
        tabIndex="-1"
        aria-labelledby="modalAccionLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title" id="modalAccionLabel">
                {accion === "eliminar"
                  ? "Confirmar Eliminación"
                  : "Editar Diseño"}
              </h5>
              <button
                type="button"
                className="btn-close"
                data-bs-dismiss="modal"
                aria-label="Cerrar"
              ></button>
            </div>
            <div className="modal-body">
              {accion === "eliminar" ? (
                <p>
                  ¿Seguro que deseas eliminar el diseño{" "}
                  <strong>{disenoSeleccionado?.NombreDiseño}</strong>?
                </p>
              ) : (
                <p>
                  Aquí podrías cargar un formulario para editar los datos de{" "}
                  <strong>{disenoSeleccionado?.NombreDiseño}</strong>.
                </p>
              )}
            </div>
            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                data-bs-dismiss="modal"
              >
                Cancelar
              </button>
              <button
                type="button"
                className={`btn ${
                  accion === "eliminar" ? "btn-danger" : "btn-primary"
                }`}
                data-bs-dismiss="modal"
                onClick={confirmarAccion}
              >
                {accion === "eliminar" ? "Eliminar" : "Guardar"}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}