import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

import Swal from "sweetalert2";

export default function ModalEliminarVenta({ venta, onClose, onConfirmar }) {
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  const handleEliminar = async () => {
    if (!venta) return;
    setErrorMsg("");
    setLoading(true);

    console.log("⛔ Intentando eliminar venta:", venta.idVenta);

    try {
      const token = localStorage.getItem("token");

      const response = await fetch(
        `http://localhost:3001/api/ventas/${venta.idVenta}`,
        {
          method: "DELETE",
          headers: {
            Authorization: token ? `Bearer ${token}` : "",
            "Content-Type": "application/json",
          },
        }
      );

      let result = null;
      try {
        result = await response.json();
      } catch {
        try {
          const txt = await response.text();
          result = { message: txt };
        } catch {
          result = null;
        }
      }

      console.log("📥 Respuesta del servidor:", result);

      if (response.ok) {
        if (typeof onConfirmar === "function") {
          try {
            onConfirmar(venta); // pasamos objeto venta
          } catch {
            onConfirmar(venta.idVenta); // fallback: solo ID
          }
        }
        onClose();

        Swal.fire({
          icon: "success",
          title: "Eliminado",
          text: "✅ Venta eliminada correctamente",
          confirmButtonColor: "#3085d6",
        });

        return;
      }

      const message =
        (result && (result.message || result.error)) ||
        `Error ${response.status}: ${response.statusText}`;
      setErrorMsg(message);

      Swal.fire({
        icon: "error",
        title: "Error",
        text: message,
        confirmButtonColor: "#d33",
      });

      console.error("❌ Error al eliminar venta:", message);
    } catch (error) {
      console.error("💥 Error de red al eliminar venta:", error);
      setErrorMsg("Error de conexión. Intenta nuevamente.");

      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "No se pudo conectar con el servidor. Intenta de nuevo.",
        confirmButtonColor: "#d33",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!venta) return null;

  return (
    <div
      className="modal fade show"
      style={{ display: "block", backgroundColor: "rgba(0,0,0,0.5)", zIndex: 1050 }}
      tabIndex="-1"
      role="dialog"
      aria-modal="true"
    >
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content shadow">
          <div className="modal-header bg-danger text-white">
            <h5 className="modal-title">
              <i className="bi bi-exclamation-triangle-fill me-2"></i>
              Confirmar Eliminación
            </h5>
            <button
              type="button"
              className="btn-close btn-close-white"
              onClick={onClose}
              disabled={loading}
            />
          </div>

          <div className="modal-body">
            <div className="alert alert-warning" role="alert">
              <strong>⚠️ Advertencia:</strong> Esta acción no se puede deshacer.
            </div>

            <p>
              ¿Está seguro que desea eliminar la venta con ID{" "}
              <strong>#{venta.idVenta}</strong>?
            </p>

            {errorMsg && (
              <div className="alert alert-danger mt-3" role="alert">
                <strong>Error:</strong> {errorMsg}
              </div>
            )}
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onClose}
              disabled={loading}
            >
              <i className="bi bi-x-circle me-1"></i>
              Cancelar
            </button>

            <button
              type="button"
              className="btn btn-danger"
              onClick={(e) => {
                e.stopPropagation();
                handleEliminar();
              }}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                  />
                  Eliminando...
                </>
              ) : (
                <>
                  <i className="bi bi-trash-fill me-1" />
                  Eliminar Venta
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
