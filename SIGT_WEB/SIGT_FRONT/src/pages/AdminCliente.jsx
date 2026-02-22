import AdminClientsPage from "../components/componentsAdmin/AdminClientsPage";
import FooterLine from "../components/FooterLine";
import HeaderLine from "../components/HeaderLine";
import "../styles/styleAdminEmpleados.css";

export default function AdminCliente() {
    return (
        <>
            <HeaderLine />
            <AdminClientsPage />
            <FooterLine />
        </>
    );
}