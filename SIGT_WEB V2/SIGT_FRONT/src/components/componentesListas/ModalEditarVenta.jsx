import React, { useState, useEffect } from "react";

import Swal from "sweetalert2";

export default function ModalEditarVenta({ venta, onClose, onGuardar }) {
  const [formData, setFormData] = useState({
    idVenta: "",
    Fecha: "",
    Total: "",
    Persona_FK: "",
  });

  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (venta) {
      setFormData({
        idVenta: venta.idVenta,
        Fecha: venta.Fecha
          ? new Date(venta.Fecha).toISOString().slice(0, 16)
          : "",
        Total: venta.Total,
        Persona_FK: venta.Persona_FK,
      });
    }
  }, [venta]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleGuardar = async () => {
    const token = localStorage.getItem("token");
    setLoading(true);

    // 🔹 Normalizamos los datos antes de enviarlos al backend
    const payload = {
      Fecha: new Date(formData.Fecha).toISOString(),
      Total: parseFloat(formData.Total.toString().replace(",", ".")),
      Persona_FK: parseInt(formData.Persona_FK),
    };

    try {
      const response = await fetch(
        `${import.meta.env.VITE_API_URL}/api/venta/${formData.idVenta}`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        }
      );

      const data = await response.json();

      if (!response.ok) throw new Error(data.message || "Error al actualizar");

      // 🔹 Actualizamos en el front
      onGuardar(data.body || { ...formData, ...payload });
      onClose();

      Swal.fire({
        icon: "success",
        title: "¡Actualizado!",
        text: "✅ Venta actualizada correctamente",
        confirmButtonColor: "#3085d6",
      });
    } catch (error) {
      console.error("💥 Error al guardar cambios:", error);

      Swal.fire({
        icon: "error",
        title: "Error",
        text: "❌ Hubo un error al actualizar la venta.",
        confirmButtonColor: "#d33",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal show d-block" tabIndex="-1">
      <div className="modal-dialog modal-lg">
        <div className="modal-content shadow">
          <div className="modal-header" style={{ backgroundColor: "#f3e5f5" }}>
            <h5 className="modal-title">Editar Venta #{formData.idVenta}</h5>
            <button
              type="button"
              className="btn-close"
              onClick={onClose}
            ></button>
          </div>

          <div className="modal-body">
            <div className="mb-3">
              <label className="form-label">Fecha</label>
              <input
                type="datetime-local"
                name="Fecha"
                value={formData.Fecha}
                onChange={handleChange}
                className="form-control"
              />
            </div>

            <div className="mb-3">
              <label className="form-label">Total</label>
              <input
                type="number"
                name="Total"
                value={formData.Total}
                onChange={handleChange}
                className="form-control"
              />
            </div>

            <div className="mb-3">
              <label className="form-label">ID Cliente</label>
              <input
                type="number"
                name="Persona_FK"
                value={formData.Persona_FK}
                onChange={handleChange}
                className="form-control"
              />
            </div>
          </div>

          <div className="modal-footer">
            <button className="btn btn-secondary" onClick={onClose}>
              Cancelar
            </button>
            <button
              className="btn btn-primary"
              onClick={handleGuardar}
              disabled={loading}
            >
              {loading ? "Guardando..." : "Guardar Cambios"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
