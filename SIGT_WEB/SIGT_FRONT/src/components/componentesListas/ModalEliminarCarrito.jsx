import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

import Swal from "sweetalert2";

export default function ModalEliminarCarrito({ carrito, onClose, onConfirmar }) {
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [debugMsg, setDebugMsg] = useState(""); // mostramos feedback en UI

  const handleEliminar = async () => {
    setDebugMsg("handleEliminar() invocado");
    console.log("⛔ handleEliminar llamado. carrito:", carrito);

    if (!carrito) {
      console.warn("No hay 'carrito' disponible al intentar eliminar.");
      setErrorMsg("No hay carrito seleccionado.");
      Swal.fire({
        icon: "warning",
        title: "Carrito no encontrado",
        text: "No hay carrito seleccionado para eliminar ⚠️",
        confirmButtonColor: "#f39c12",
      });
      return;
    }

    setErrorMsg("");
    setLoading(true);

    try {
      const token = localStorage.getItem("token") || "";
      console.log("🔐 token:", !!token);

      const response = await fetch(
        `http://localhost:3001/api/carrito/${carrito.idCarrito}`,
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

      console.log("📥 DELETE status:", response.status, response.statusText, "body:", result);

      if (response.ok) {
        setDebugMsg("Eliminación exitosa (servidor respondió OK).");

        Swal.fire({
          icon: "success",
          title: "¡Eliminado!",
          text: "Carrito eliminado correctamente ✅",
          confirmButtonColor: "#3085d6",
        });

        // Llamamos onConfirmar de forma segura
        if (typeof onConfirmar === "function") {
          try {
            onConfirmar(carrito);
          } catch (err) {
            console.warn("onConfirmar falló pasando objeto, intentando con id", err);
            try {
              onConfirmar(carrito.idCarrito);
            } catch (e) {
              console.error(e);
            }
          }
        } else {
          console.warn("onConfirmar no es función.");
        }

        try {
          onClose();
        } catch (e) {
          console.warn("onClose lanzó error:", e);
        }

        setLoading(false);
        return;
      }

      const message =
        (result && (result.message || result.error)) ||
        `Error ${response.status}: ${response.statusText}`;
      setErrorMsg(message);
      setDebugMsg("Servidor devolvió error.");
      console.error("❌ Error al eliminar carrito:", message);

      Swal.fire({
        icon: "error",
        title: "Error",
        text: message,
        confirmButtonColor: "#d33",
      });
    } catch (error) {
      console.error("💥 Error de red al eliminar carrito:", error);
      setErrorMsg("Error de conexión. Por favor, inténtalo de nuevo.");
      setDebugMsg("Excepción en fetch.");

      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "No se pudo conectar con el servidor ❌",
        confirmButtonColor: "#d33",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!carrito) return null;

  return (
    <div
      className="modal fade show"
      style={{
        display: "block",
        backgroundColor: "rgba(0,0,0,0.5)",
        zIndex: 9999,
        pointerEvents: "auto",
      }}
      tabIndex="-1"
      role="dialog"
      aria-modal="true"
    >
      <div className="modal-dialog modal-dialog-centered">
        <div
          className="modal-content shadow"
          onClick={(e) => e.stopPropagation()}
          style={{ pointerEvents: "auto" }}
        >
          <div className="modal-header bg-danger text-white">
            <h5 className="modal-title">
              <i className="bi bi-exclamation-triangle-fill me-2" />
              Confirmar Eliminación
            </h5>
            <button
              type="button"
              className="btn-close btn-close-white"
              onClick={onClose}
              aria-label="Cerrar"
              disabled={loading}
            />
          </div>

          <div className="modal-body">
            <div className="alert alert-warning" role="alert">
              <strong>⚠️ Advertencia:</strong> Esta acción no se puede deshacer.
            </div>

            <p>
              ¿Está seguro que desea eliminar el carrito{" "}
              <strong>#{carrito.idCarrito}</strong> del cliente{" "}
              <strong>
                {carrito.Persona
                  ? `${carrito.Persona.Primer_Nombre} ${carrito.Persona.Primer_Apellido}`
                  : "No disponible"}
              </strong>
              ?
            </p>

            {errorMsg && (
              <div className="alert alert-danger mt-3" role="alert">
                <strong>Error:</strong> {errorMsg}
              </div>
            )}

            {/* DEBUG VISIBLE */}
            {debugMsg && (
              <div className="alert alert-secondary mt-2">
                <small><strong>Debug:</strong> {debugMsg}</small>
              </div>
            )}
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={(e) => {
                e.stopPropagation();
                try { onClose(); } catch (err) { console.error(err); }
              }}
              disabled={loading}
            >
              <i className="bi bi-x-circle me-1" />
              Cancelar
            </button>

            {/* BOTÓN con ID único para pruebas */}
            <button
              id={`btn-eliminar-${carrito.idCarrito}`}
              type="button"
              className="btn btn-danger"
              onClick={(e) => {
                e.stopPropagation();
                console.log("onclick del botón ejecutado (antes de handleEliminar)");
                setDebugMsg("onclick (botón) ejecutado");
                handleEliminar();
              }}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="spinner-border spinner-border-sm me-2" role="status" />
                  Eliminando...
                </>
              ) : (
                <>
                  <i className="bi bi-trash-fill me-1" />
                  Eliminar Carrito
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
