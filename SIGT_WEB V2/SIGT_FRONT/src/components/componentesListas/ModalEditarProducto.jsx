import { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

import Swal from "sweetalert2";

export default function ModalEditarProducto({ producto, onClose, onGuardar }) {
  const [formData, setFormData] = useState({
    NombreProducto: "",
    Color: "",
    Talla: "",
    Stock: "",
    Precio: "",
  });

  const colores = [
    "Rojo", "Azul", "Verde", "Amarillo", "Negro", "Blanco", 
    "Gris", "Rosa", "Morado", "Naranja", "Café", "Beige",
    "Celeste", "Turquesa", "Violeta", "Fucsia", "Marino", "Vino", "Crema"
  ];

  const tallas = ["XS", "S", "M", "L", "XL", "XXL"];

  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (producto) {
      console.log("📦 Producto seleccionado:", producto);

      setFormData({
        NombreProducto: producto.NombreProducto || "",
        Color: producto.Color || "",
        Talla: producto.Talla || "",
        Stock: producto.Stock || "",
        Precio: producto.Precio || "",
      });
    }
  }, [producto]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));

    if (errors[name]) {
      setErrors((prev) => ({
        ...prev,
        [name]: "",
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.NombreProducto.trim()) {
      newErrors.NombreProducto = "El nombre del producto es requerido";
    }

    if (!formData.Color) {
      newErrors.Color = "El color es requerido";
    }

    if (!formData.Talla) {
      newErrors.Talla = "La talla es requerida";
    }

    if (!formData.Stock || formData.Stock < 0) {
      newErrors.Stock = "El stock debe ser un número válido (mayor o igual a 0)";
    }

    if (!formData.Precio || formData.Precio <= 0) {
      newErrors.Precio = "El precio debe ser un número mayor a 0";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    console.log("🔄 Iniciando actualización de producto...");

    if (!validateForm()) {
      console.log("❌ Validación fallida");
      return;
    }

    setLoading(true);

    try {
      const datosParaActualizar = {
        NombreProducto: formData.NombreProducto.trim(),
        Color: formData.Color,
        Talla: formData.Talla,
        Stock: parseInt(formData.Stock),
        Precio: parseFloat(formData.Precio),
      };

      const token = localStorage.getItem("token");

      console.log(
        "📤 Enviando actualización a:",
        `${import.meta.env.VITE_API_URL}/api/producto/${producto.idProducto}`
      );
      console.log("📦 Datos:", datosParaActualizar);

      const response = await fetch(
        `${import.meta.env.VITE_API_URL}/api/producto/${producto.idProducto}`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(datosParaActualizar),
        }
      );

      const result = await response.json();
      console.log("📥 Respuesta del servidor:", result);

      if (response.ok) {
        Swal.fire({
          icon: "success",
          title: "¡Actualizado!",
          text: "Producto actualizado correctamente ✅",
          confirmButtonColor: "#3085d6",
        });

        const productoActualizado = {
          ...producto,
          ...datosParaActualizar,
        };

        onGuardar(productoActualizado);
        onClose();
      } else {
        if (result.errors) {
          setErrors(result.errors);
        } else {
          Swal.fire({
            icon: "error",
            title: "Error",
            text: result.message || "Error al actualizar el producto",
            confirmButtonColor: "#d33",
          });
        }
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


  return (
    <div
      className="modal fade show"
      style={{ display: "block", backgroundColor: "rgba(0,0,0,0.5)" }}
      tabIndex="-1"
    >
      <div className="modal-dialog modal-dialog-centered modal-lg">
        <div className="modal-content rounded-3 shadow">
          <div className="modal-header">
            <h5 className="modal-title">Editar Producto</h5>
            <button
              type="button"
              className="btn-close"
              onClick={onClose}
              aria-label="Cerrar"
            ></button>
          </div>

          <div className="modal-body bg-light">
            {loading && (
              <div className="text-center mb-3">
                <div className="spinner-border text-primary" role="status">
                  <span className="visually-hidden">Cargando...</span>
                </div>
              </div>
            )}

            <div className="row g-3">
              <div className="col-12">
                <label className="form-label">
                  Nombre del Producto <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className={`form-control ${
                    errors.NombreProducto ? "is-invalid" : ""
                  }`}
                  name="NombreProducto"
                  value={formData.NombreProducto}
                  onChange={handleInputChange}
                  disabled={loading}
                />
                {errors.NombreProducto && (
                  <div className="invalid-feedback">{errors.NombreProducto}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Color <span className="text-danger">*</span>
                </label>
                <select
                  className={`form-select ${errors.Color ? "is-invalid" : ""}`}
                  name="Color"
                  value={formData.Color}
                  onChange={handleInputChange}
                  disabled={loading}
                >
                  <option value="">Seleccione un color</option>
                  {colores.map((color) => (
                    <option key={color} value={color}>
                      {color}
                    </option>
                  ))}
                </select>
                {errors.Color && (
                  <div className="invalid-feedback">{errors.Color}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Talla <span className="text-danger">*</span>
                </label>
                <select
                  className={`form-select ${errors.Talla ? "is-invalid" : ""}`}
                  name="Talla"
                  value={formData.Talla}
                  onChange={handleInputChange}
                  disabled={loading}
                >
                  <option value="">Seleccione una talla</option>
                  {tallas.map((talla) => (
                    <option key={talla} value={talla}>
                      {talla}
                    </option>
                  ))}
                </select>
                {errors.Talla && (
                  <div className="invalid-feedback">{errors.Talla}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Stock <span className="text-danger">*</span>
                </label>
                <input
                  type="number"
                  className={`form-control ${errors.Stock ? "is-invalid" : ""}`}
                  name="Stock"
                  value={formData.Stock}
                  onChange={handleInputChange}
                  min="0"
                  disabled={loading}
                />
                {errors.Stock && (
                  <div className="invalid-feedback">{errors.Stock}</div>
                )}
              </div>

              <div className="col-md-6">
                <label className="form-label">
                  Precio <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <span className="input-group-text">$</span>
                  <input
                    type="number"
                    className={`form-control ${
                      errors.Precio ? "is-invalid" : ""
                    }`}
                    name="Precio"
                    value={formData.Precio}
                    onChange={handleInputChange}
                    min="0"
                    step="0.01"
                    disabled={loading}
                  />
                  {errors.Precio && (
                    <div className="invalid-feedback">{errors.Precio}</div>
                  )}
                </div>
              </div>
            </div>
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onClose}
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleSubmit}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                  ></span>
                  Actualizando...
                </>
              ) : (
                "Guardar Cambios"
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}