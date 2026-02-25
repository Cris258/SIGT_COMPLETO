import React from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import Swal from "sweetalert2";

export default function ModalEliminarTarea({ tarea, onClose, onConfirmar }) {
  const handleEliminar = async () => {
    try {
      const token = localStorage.getItem("token");
      const response = await fetch(
        `http://localhost:3001/api/tarea/${tarea.idTarea}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.ok) {
        Swal.fire({
          icon: "success",
          title: "¡Eliminada!",
          text: "La tarea fue eliminada exitosamente ✅",
          confirmButtonColor: "#3085d6",
        });
        onConfirmar(tarea);
        onClose();
      } else {
        const error = await response.json();
        Swal.fire({
          icon: "error",
          title: "Error al eliminar",
          text: error.Message || "Error desconocido",
          confirmButtonColor: "#d33",
        });
      }
    } catch (error) {
      console.error("Error:", error);
      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "No se pudo conectar con el servidor ❌",
        confirmButtonColor: "#d33",
      });
    }
  };

  const getPrioridadBadgeClass = (prioridad) => {
  if (prioridad === "Alta") return "bg-danger";
  if (prioridad === "Media") return "bg-warning";
  return "bg-success";
};

const getEstadoBadgeClass = (estado) => {
  if (estado === "Completada") return "bg-success";
  if (estado === "En Progreso") return "bg-warning";
  return "bg-danger";
};
  return (
    <div
      className="modal fade show d-block"
      tabIndex="-1"
      style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
    >
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content">
          <div className="modal-header bg-danger text-white">
            <h5 className="modal-title">Eliminar Tarea</h5>
            <button
              type="button"
              className="btn-close btn-close-white"
              onClick={onClose}
            ></button>
          </div>
          <div className="modal-body">
            <div className="text-center mb-3">
              <i
                className="bi bi-exclamation-triangle-fill text-warning"
                style={{ fontSize: "4rem" }}
              ></i>
            </div>
            <p className="text-center fs-5">
              ¿Estás seguro de que deseas eliminar esta tarea?
            </p>
            <div className="alert alert-warning" role="alert">
              <strong>Advertencia:</strong> Esta acción no se puede deshacer.
            </div>
            <div className="card">
              <div className="card-body">
                <h6 className="card-subtitle mb-2 text-muted">
                  Detalles de la tarea:
                </h6>
                <p className="card-text">
                  <strong>Descripción:</strong> {tarea.Descripcion}
                </p>
                <p className="card-text">
                  <strong>Fecha Límite:</strong>{" "}
                  {tarea.FechaLimite
                    ? new Date(tarea.FechaLimite).toLocaleDateString("es-CO")
                    : "N/A"}
                </p>
                <p className="card-text">
                  <strong>Prioridad:</strong>{" "}
                  <span
                    className={`badge ${getPrioridadBadgeClass(tarea.Prioridad)}`}
                  >
                    {tarea.Prioridad}
                  </span>
                </p>
                <p className="card-text">
                  <strong>Estado:</strong>{" "}
                  <span
                    className={`badge ${getEstadoBadgeClass(tarea.EstadoTarea)}`}
                  >
                    {tarea.EstadoTarea}
                  </span>
                </p>
              </div>
            </div>
          </div>
          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onClose}
            >
              Cancelar
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={handleEliminar}
            >
              Eliminar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}