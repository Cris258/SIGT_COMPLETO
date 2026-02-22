import Header from "../components/componentsMain(tienda)/Header";
import NavBar from "../components/componentsMain(tienda)/Navbar";
import FooterProductos from "../components/componentsMain(tienda)/FooterProductos";
import Tienda from "../components/componentsMain(tienda)/Tienda";
import"../styles/styleTienda.css";



export default function TiendaMain() {
  return (
    <>
      <Header />
      <NavBar />
      <Tienda/>
      <FooterProductos />
    </>
  );
}
