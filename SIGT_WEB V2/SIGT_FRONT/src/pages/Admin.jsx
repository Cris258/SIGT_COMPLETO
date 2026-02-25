import "../styles/styleAdmin.css";
import AdminPage from "../components/componentsAdmin/AdminPage";
import FooterLine from "../components/FooterLine";
import HeaderLine from "../components/HeaderLine";

export default function Admin() {
  return (
    <>
      <HeaderLine />
      <AdminPage />
      <FooterLine />
    </>
  );
}
