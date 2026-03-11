import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import TiendaMain from "./pages/TiendaMain";
import Admin from "./pages/Admin";
import AdminInventario from "./pages/AdminInventario";
import AdminEmpleados from "./pages/AdminEmpleados";
import ListaUsuarios from "./pages/ListarUsuarios";
import Inventario from "./pages/Inventario";
import AdminCliente from "./pages/AdminCliente";
import Empleado from "./pages/Empleado";
import Login from "./pages/Login";
import RecuperarContraseña from "./pages/RecuperarContraseña";
import Carrito from "./pages/Carrito";
import Registro from "./pages/Registro";
import RegistroUsuarios from "./pages/RegistroUsuarios";
import ListarEmpleados from "./pages/ListarEmpleados";
import RegistroProductos from "./pages/RegistroProductos";
import ListarProductos from "./pages/ListarProductos";
import ListarClientes from "./pages/ListarClientes";
import Cliente from "./pages/Cliente";
import PageHistorialCompras from "./pages/PageHistorialCompras";
import Historial from "./pages/Historial";
import TiendaLine from "./pages/TiendaLine";
import AsignarTareaAdmin from "./pages/AsignarTareaAdmin";
import ListarTareas from "./pages/ListarTareas";
import ListarCarritos from "./pages/ListarCarritos";
import ListarVentas from "./pages/ListarVentas";
import Detalleproduccion from "./pages/DetalleProduccion";
import ListaMovimientos from "./pages/ListaMovimientos";
import ForgotPasswordPage from "./pages/ForgotPasswordPage";
import ResetPasswordPage from "./pages/ResetPasswordPage";
import HistorialProduccion from "./pages/HistorialProduccion";

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/tienda" element={<TiendaMain />} />
        <Route path="/login" element={<Login />} />
        <Route path="/Registro" element={<Registro />} />
        <Route path="/RecuperarContraseña" element={<RecuperarContraseña />} />
        <Route path="/Carrito" element={<Carrito />} />
        <Route path="/admin" element={<Admin />} />
        <Route path="/RegistroUsuarios" element={<RegistroUsuarios />} />
        <Route path="/adminInventario" element={<AdminInventario />} />
        <Route path="/adminEmpleado" element={<AdminEmpleados />} />
        <Route path="/listaUsuarios" element={<ListaUsuarios />} />
        <Route path="/Inventario" element={<Inventario />} />
        <Route path="/adminCliente" element={<AdminCliente />} />
        <Route path="/empleado" element={<Empleado />} />
        <Route path="/ListarEmpleados" element={<ListarEmpleados />} />
        <Route path="/RegistroProductos" element={<RegistroProductos />} />
        <Route path="/ListarProductos" element={<ListarProductos />} />
        <Route path="/ListarClientes" element={<ListarClientes />} />
        <Route path="/Cliente" element={<Cliente />} />
        <Route path="/AsignarTareaAdmin" element={<AsignarTareaAdmin />} />
        <Route path="/TiendaLine" element={<TiendaLine />} />
        <Route
          path="/PageHistorialCompras"
          element={<PageHistorialCompras />}
        />
        <Route path="/Historial" element={<Historial />} />
        <Route path="/ListarTareas" element={<ListarTareas />} />
        <Route path="/ListarCarritos" element={<ListarCarritos />} />
        <Route path="/ListarVentas" element={<ListarVentas />} />
        <Route path="/detalleproduccion" element={<Detalleproduccion />} />
        <Route path="/HistorialProduccion" element={<HistorialProduccion />} />
        <Route path="/listaMovimientos" element={<ListaMovimientos />} />
        <Route path="/ForgotPasswordPage" element={<ForgotPasswordPage />} />
        <Route path="/ResetPasswordPage" element={<ResetPasswordPage />} />
      </Routes>
    </Router>
  );
}

export default App;
