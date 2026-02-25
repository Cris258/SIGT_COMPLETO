import "../styles/styleAdmin.css";
import AdminInventarioPage from "../components/componentsAdmin/AdminInventarioPage";
import HeaderLine from "../components/HeaderLine";
import FooterLine from "../components/FooterLine";



export default function AdminInventario() {
  return (
    <>
      <HeaderLine />
      <AdminInventarioPage />
      <FooterLine />
    </>
  );
}
