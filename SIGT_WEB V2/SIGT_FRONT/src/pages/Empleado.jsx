import "../styles/styleEmpleado.css";
import EmpleadoPage from "../components/componentsEmpleado/EmpleadoPage";
import HeaderLine from "../components/HeaderLine";
import FooterLine from "../components/FooterLine";

export default function Empleado() {
  return (
    <>
      <HeaderLine />
      <EmpleadoPage />
      <FooterLine />
    </>
  );
}
