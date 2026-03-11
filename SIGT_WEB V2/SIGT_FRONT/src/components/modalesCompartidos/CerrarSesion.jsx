import React, { useState } from "react";
import Swal from "sweetalert2";

const CerrarSesion = ({ className = "nav-link custom-link" }) => {
  const [loading, setLoading] = useState(false);

  const handleLogout = async () => {
    // Confirmación antes de cerrar sesión con SweetAlert2
    const { isConfirmed } = await Swal.fire({
      title: "¿Cerrar sesión?",
      text: "Tu sesión actual se cerrará.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#d33",
      confirmButtonText: "Sí, cerrar sesión",
      cancelButtonText: "Cancelar",
    });

    if (!isConfirmed) return;

    setLoading(true);

    try {
      // Llamada al endpoint de logout
      const response = await fetch("${import.meta.env.VITE_API_URL}/api/persona/logout", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      if (response.ok) {
        Swal.fire({
          icon: "success",
          title: "Sesión cerrada",
          text: "Has cerrado sesión correctamente.",
          confirmButtonColor: "#3085d6",
        });
      } else {
        Swal.fire({
          icon: "error",
          title: "Error en el servidor",
          text: "No se pudo cerrar la sesión, pero se limpiará el localStorage.",
          confirmButtonColor: "#d33",
        });
      }
    } catch (error) {
      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: "No fue posible conectar con el servidor.",
        confirmButtonColor: "#d33",
      });
    } finally {
      limpiarSesionLocal();
    }
  };

  const limpiarSesionLocal = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("idPersona");
    localStorage.removeItem("rol");
    window.location.href = "/";
  };

  return (
    <button
      type="button"
      className={`btn btn-link p-0 ${className}`}
      onClick={handleLogout}
      disabled={loading}
      style={{
        textAlign: "left",
        textDecoration: "none",
        border: "none",
        background: "none",
        width: "100%",
      }}
    >
      {loading ? (
        <>
          <span
            className="spinner-border spinner-border-sm me-2"
            role="status"
          ></span>
          Cerrando sesión...
        </>
      ) : (
        <>
          Cerrar Sesión
          <i className="bi bi-box-arrow-right ms-2"></i>
        </>
      )}
    </button>
  );
};

export default CerrarSesion;
