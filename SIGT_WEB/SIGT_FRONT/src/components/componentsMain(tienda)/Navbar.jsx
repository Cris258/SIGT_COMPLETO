export default function NavBar() {
  return (
    <nav className="navbar bg-morado navbar-expand-lg">
        <div className="container-fluid justify-content-center">
          <button
            className="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navbarNav"
          >
            <span className="navbar-toggler-icon"></span>
          </button>
          <div
            className="collapse navbar-collapse justify-content-center"
            id="navbarNav"
          >
            <ul className="navbar-nav merriweather-font fw-bold">
              <li className="nav-item">
                <a className="nav-link" href="/#inicio">
                  Inicio
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="/#nuestrosproductos">
                  Nuestros Productos
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="tienda">
                  Tienda
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="/#quienes-somos">
                  Quienes Somos
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="/#ubicacion">
                  Ubicación
                </a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
  );
}
