import React from "react";
import CerrarSesion from "../components/modalesCompartidos/CerrarSesion"; 

const HeaderLine = () => {
  return (
    <header className="py-3 shadow-sm merriweather-font">
      <div className="container">
        <div className="row g-0 justify-content-between align-items-center">
          {/* Logo + Título */}
          <div className="col-auto d-flex align-items-center ps-2">
            <img
              src="img/Logo Vibra Positiva.jpg"
              alt="Logo"
              className="minilogo me-2"
            />
            <h1 className="titulo fw-bold text-uppercase mb-0 fs-7 ms-2">
              Vibra Positiva Pijamas
            </h1>
          </div>

          {/* Menú con componente de cerrar sesión */}
          <nav className="menu col-auto d-flex flex-column flex-md-row align-items-center gap-1 gap-md-2">
            <div className="co1 d-flex align-items-center text-center text-black text-decoration-none">
              <div className="login d-flex align-items-center gap-1">
                <CerrarSesion 
                  className="btn btn-link text-black text-decoration-none p-0"
                  showIcon={false}
                />
              </div>
            </div>
          </nav>
        </div>
      </div>
    </header>
  );
};

export default HeaderLine;