import React, { useState } from "react";
import ActualizarDatosModal from "../modalesCompartidos/ModalActualizarDatos";
import CambiarPasswordModal from "../modalesCompartidos/ModalCambiarPassword";

export default function Sidebar() {
  const [open, setOpen] = useState(false);

  return (
    <>
      {/* Botón hamburguesa */}
      <button
        className="btn m-3"
        style={{
          backgroundColor: "#f4c2f0 ",
          color: "white",
          border: "none",
          borderRadius: "8px",
          padding: "8px 12px",
        }}
        onClick={() => setOpen(true)}
      >
        <i className="bi bi-list" style={{ fontSize: "1.5rem" }}></i>
      </button>

      {/* Overlay */}
      {open && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100 bg-dark bg-opacity-50"
          onClick={() => setOpen(false)}
          style={{ zIndex: 1040 }}
        ></div>
      )}

      {/* Sidebar */}
      <div
        className={`position-fixed top-0 start-0 h-100 shadow p-4`}
        style={{
          width: "250px",
          background: "white",
          transform: open ? "translateX(0)" : "translateX(-100%)",
          transition: "transform 0.3s ease-in-out",
          zIndex: 1045,
          borderTopRightRadius: "16px",
          borderBottomRightRadius: "16px",
        }}
      >
        {/* Botón cerrar */}
        <button
          className="btn mb-4"
          style={{
            backgroundColor: "#f4c2f0",
            color: "white",
            border: "none",
            borderRadius: "8px",
            padding: "6px 10px",
          }}
          onClick={() => setOpen(false)}
        >
          ✖
        </button>

        {/* Menú del sidebar */}
        <ul className="list-unstyled">
          <li className="mb-3">
            <a
              href="TiendaLine"
              className="text-decoration-none d-flex align-items-center"
              style={{ color: "#000000ff", fontWeight: "bold" }}
            >
              <i className="bi bi-house-door me-2"></i> Tienda
            </a>
          </li>
          <li className="mb-3">
            <a
              href="PageHistorialCompras"
              className="text-decoration-none d-flex align-items-center"
              style={{ color: "#000000ff", fontWeight: "bold" }}
            >
              <i className="bi bi-cart me-2"></i> Historial de Compras
            </a>
          </li>
        </ul>

        <hr />

        {/* Botones para abrir modales */}
        <button
          className="btn w-100 mb-2"
          style={{
            backgroundColor: "#f4c2f0",
            color: "black",
            border: "none",
            borderRadius: "8px",
            padding: "8px",
            fontWeight: "bold",
          }}
          data-bs-toggle="modal"
          data-bs-target="#modalActualizarDatos"
        >
          <i className="bi bi-pencil-square me-2"></i> Actualizar Datos
        </button>

        <button
          className="btn w-100"
          style={{
            backgroundColor: "#f4c2f0",
            color: "black",
            border: "none",
            borderRadius: "8px",
            padding: "8px",
            fontWeight: "bold",
          }}
          data-bs-toggle="modal"
          data-bs-target="#modalCambiarPassword"
        >
          <i className="bi bi-lock-fill me-2"></i> Actualizar Contraseña
        </button>
      </div>
      {/* Modales */}
      <ActualizarDatosModal />
      <CambiarPasswordModal />
    </>
  );
}
