import { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

import Swal from "sweetalert2";

export default function ModalEliminarProducto({ producto, onClose, onConfirmar }) {
  const [loading, setLoading] = useState(false);

  // Mapa de colores
  const colorMap = {
    rojo: "#ff0000",
    azul: "#0000ff",
    verde: "#00ff00",
    amarillo: "#ffff00",
    negro: "#000000",
    blanco: "#ffffff",
    gris: "#808080",
    rosa: "#ffc0cb",
    morado: "#800080",
    naranja: "#ffa500",
    cafe: "#8b4513",
    café: "#8b4513",
    beige: "#f5f5dc",
    celeste: "#87ceeb",
    turquesa: "#40e0d0",
    violeta: "#ee82ee",
    fucsia: "#ff00ff",
    marino: "#000080",
    vino: "#722f37",
    crema: "#fffdd0",
  };

  const getColorCode = (colorName) => {
    if (!colorName) return "#cccccc";
    const color = colorName.toLowerCase().trim();
    return colorMap[color] || colorName;
  };

  const formatearPrecio = (precio) => {
    return new Intl.NumberFormat("es-CO", {
      style: "currency",
      currency: "COP",
      minimumFractionDigits: 0,
    }).format(precio);
  };

  const handleEliminar = async () => {
    if (!producto) return;

    setLoading(true);

    try {
      const token = localStorage.getItem("token");

      console.log(`🗑️ Eliminando producto:`, producto.idProducto);

      const response = await fetch(
        `http://localhost:3001/api/producto/${producto.idProducto}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      const result = await response.json();
      console.log("📥 Respuesta del servidor:", result);

      if (response.ok) {
        Swal.fire({
          icon: "success",
          title: "¡Eliminado!",
          text: "Producto eliminado correctamente ✅",
          confirmButtonColor: "#3085d6",
        });
        onConfirmar(producto);
        onClose();
      } else {
        Swal.fire({
          icon: "error",
          title: "Error",
          text: result.message || "Error al eliminar el producto",
          confirmButtonColor: "#d33",
        });
      }
    } catch (error) {
      console.error("💥 Error:", error);
      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "Por favor, intente nuevamente ❌",
        confirmButtonColor: "#d33",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!producto) return null;

  // Función auxiliar fuera del componente (o dentro, según prefieras)
const getStockBadgeClass = (stock) => {
  if (stock > 10) return "bg-success";
  if (stock > 5) return "bg-warning";
  return "bg-danger";
};

  return (
    <div
      className="modal fade show"
      style={{ display: "block", backgroundColor: "rgba(0,0,0,0.5)" }}
      tabIndex="-1"
    >
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content">
          <div className="modal-header bg-danger text-white">
            <h5 className="modal-title">
              <i className="bi bi-exclamation-triangle-fill me-2"></i>
              Confirmar Eliminación
            </h5>
            <button
              type="button"
              className="btn-close btn-close-white"
              onClick={onClose}
              aria-label="Cerrar"
              disabled={loading}
            ></button>
          </div>

          <div className="modal-body">
            <div className="alert alert-warning" role="alert">
              <strong>⚠️ Advertencia:</strong> Esta acción no se puede deshacer.
            </div>

            <p className="mb-3">
              ¿Está seguro que desea eliminar el producto{" "}
              <strong>{producto.NombreProducto}</strong>?
            </p>

            <div className="card bg-light">
              <div className="card-body">
                <h6 className="card-subtitle mb-3 text-muted">
                  Información del producto:
                </h6>
                <div className="row g-2">
                  <div className="col-12">
                    <strong>ID:</strong> {producto.idProducto}
                  </div>
                  <div className="col-12">
                    <strong>Nombre:</strong> {producto.NombreProducto}
                  </div>
                  <div className="col-12 d-flex align-items-center gap-2">
                    <strong>Color:</strong>
                    <div
                      style={{
                        width: "20px",
                        height: "20px",
                        borderRadius: "50%",
                        backgroundColor: getColorCode(producto.Color),
                        border: "2px solid #ddd",
                        boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                      }}
                      title={producto.Color}
                    ></div>
                    <span>{producto.Color}</span>
                  </div>
                  <div className="col-12">
                    <strong>Talla:</strong>{" "}
                    <span className="badge bg-secondary">{producto.Talla}</span>
                  </div>
                  <div className="col-12">
                    <strong>Stock:</strong>{" "}
                    <span
                      className={`badge ${getStockBadgeClass(producto.Stock)}`}
                    >
                      {producto.Stock} unidades
                    </span>
                  </div>
                  <div className="col-12">
                    <strong>Precio:</strong> {formatearPrecio(producto.Precio)}
                  </div>
                </div>
              </div>
            </div>

            {producto.Stock > 0 && (
              <div className="alert alert-info mt-3 mb-0">
                <i className="bi bi-info-circle me-2"></i>
                <strong>Nota:</strong> Este producto tiene stock disponible. Al eliminarlo, 
                se perderá el inventario registrado.
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
              onClick={handleEliminar}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                  ></span>
                  Eliminando...
                </>
              ) : (
                <>
                  <i className="bi bi-trash-fill me-1"></i>
                  Eliminar Producto
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}