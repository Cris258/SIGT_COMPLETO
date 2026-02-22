import AdminEmpleadosPage from "../components/componentsAdmin/AdminEmpleadosPage";
import HeaderLine from "../components/HeaderLine";
import FooterLine from "../components/FooterLine";
import "../styles/styleAdminEmpleados.css";

export default function AdminEmpleados() {
    return (
        <>
            <HeaderLine />
            <AdminEmpleadosPage />
            <FooterLine />
        </>
    );
}