export default function Footer() {
  return (
    <footer className="text-black pt-5 pb-3">
      <div className="container text-center">
        <div className="row justify-content-center">
          {/* Contacto */}
          <div className="col-md-3 mb-4">
            <h5 className="footertitulos fw-bold">Contacto</h5>
            <p>📍 <strong>Dirección: </strong>Calle 2 Sur #10 - 39, Bogotá, Colombia</p>
            <p>📞 <strong>Teléfono: </strong>+57 305 930 9024</p>
            <p>📧 <strong>Email: </strong>vibrapositiva1720@gmail.com</p>
          </div>

          {/* Enlaces Rápidos */}
          <div className="col-md-3 mb-4">
            <h5 className="footertitulos fw-bold">Enlaces Rápidos</h5>
            <ul className="list-unstyled">
              <li><a href="/" className="text-black text-decoration-none">Inicio</a></li>
              <li><a href="#nuestrosproductos" className="text-black text-decoration-none">Nuestros Productos</a></li>
              <li><a href="#quienes-somos" className="text-black text-decoration-none">Quiénes Somos</a></li>
              <li><a href="#ubicacion" className="text-black text-decoration-none">Ubicación</a></li>
            </ul>
          </div>

          {/* Redes Sociales */}
          <div className="col-md-3 mb-4 text-center">
            <h5 className="footertitulos fw-bold">Síguenos</h5>
            <div className="d-flex justify-content-center gap-4 fs-4">
              <a href="https://wa.me/573059309024?text=Hola%20quiero%20más%20información" className="text-black"><i className="bi bi-whatsapp"></i></a>
              <a href="https://www.facebook.com/share/19rxvzvkqo/" className="text-black"><i className="bi bi-facebook"></i></a>
              <a href="https://www.instagram.com/vibrapositivapijamas?igsh=Ym9zaTVnMmxrc29i" className="text-black"><i className="bi bi-instagram"></i></a>
            </div>
          </div>
        </div>

        <div className="text-center mt-4 fw-bold">
          <small>© 2025 Tienda de Pijamas Vibra Positiva - Todos los derechos reservados</small>
        </div>
      </div>
    </footer>
  );
}
