import HeaderLine from "../components/HeaderLine";
import FooterLine from "../components/FooterLine";
import SidebarCliente from "../components/componentsCliente/SidebarCliente";
import HistorialCompras from "../components/componentsCliente/HistorialCompras";

export default function Cliente() {
  return (
    <>
      <HeaderLine />
      <div className="container-fluid">
        <div className="row">
          {/* Sidebar a la izquierda */}
          <div className="col-md-2 p-0">
            <SidebarCliente />
          </div>

          {/* Historial más ancho */}
          <div className="col-md-10 p-0">
            <HistorialCompras />
          </div>
        </div>
      </div>
      <FooterLine />
    </>
  );
}
