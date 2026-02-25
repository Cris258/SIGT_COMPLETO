export default function Header() {
  return (
    <header className="shadow-sm merriweather-font fw-bold bg-header">
      <div className="container px-5">
        <div className="row g-0 justify-content-between align-items-center">
          {/* Logo + Título */}
          <div className="col-auto d-flex align-items-center ps-2">
            <img
              src="/img/Logo Vibra Positiva.jpg"
              alt="Logo"
              className="minilogo me-2"
            />
            <h1 className="titulo fw-bold text-uppercase mt-0 mb-0 fs-7 ms-2">
              Vibra Positiva Pijamas
            </h1>
          </div>

          {/* Botones Registrarse e Iniciar Sesión */}
          <nav className="menu col-auto d-flex flex-column flex-md-row align-items-center gap-1 gap-md-2">
            {/* Registrarse */}
            <a
              href="Registro"
              className="co1 d-flex align-items-center text-center text-black text-decoration-none"
            >
              <div className="login btn d-flex align-items-center gap-1">
                <span>Registrarse</span>
                <div className="icono">
                  <i className="bi bi-person-add"></i>
                </div>
              </div>
            </a>

            {/* Iniciar Sesion */}
            <a
              href="Login"
              className="co1 d-flex align-items-center text-center text-black text-decoration-none"
            >
              <div className="login btn d-flex align-items-center gap-1">
                <span>Iniciar Sesión</span>
                <div className="icono">
                  <i className="bi bi-door-open-fill"></i>
                </div>
              </div>
            </a>
          </nav>
        </div>
      </div>
    </header>
  );
}