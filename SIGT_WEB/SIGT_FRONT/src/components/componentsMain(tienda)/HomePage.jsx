import React from "react";

export default function HomePage() {
  return (
    <>
      {/* NAVBAR */}
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
                <a className="nav-link" href="#inicio">
                  Inicio
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="#nuestrosproductos">
                  Nuestros Productos
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="#quienes-somos">
                  Quienes Somos
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="#ubicacion">
                  Ubicación
                </a>
              </li>
            </ul>
          </div>
        </div>
      </nav>

      {/* INICIO */}
      <section id="inicio" className="container">
        <div className="row align-items-center">
          {/* TEXTO */}
          <div className="col-12 col-md-6 text-center mb-4 mb-md-0">
            <h1 className="tex1 display-5 fw-bold merriweather-font">
              Descansar bien también es parte del éxito
            </h1>
            <p className="lead mt-3 fs-4 lato-font">
              Comienza tu día con energía positiva y alcanza cada meta que te
              propongas. La comodidad empieza contigo.
            </p>
            <a
              href="#nuestrosproductos"
              className="btn btn-dark mt-3 merriweather-font fw-bold"
            >
              Ver productos
            </a>
          </div>
          {/* SLIDER */}
          <div className="col-12 col-md-6 d-flex justify-content-center align-items-center">
            <div className="carousel slide" data-bs-ride="carousel" id="slider">
              <div className="carousel-inner">
                <div className="carousel-item active">
                  <img
                    className="sliderimg d-block w-100"
                    src="img/Slider 2.jpg"
                    alt=""
                  />
                </div>
                <div className="carousel-item">
                  <img
                    className="sliderimg d-block w-100"
                    src="img/Slider 3.png"
                    alt=""
                  />
                </div>
              </div>
              {/* botones */}
              <button
                className="carousel-control-prev"
                type="button"
                data-bs-target="#slider"
                data-bs-slide="prev"
              >
                <span
                  className="carousel-control-prev-icon"
                  aria-hidden="true"
                ></span>
                <span className="visually-hidden">Anterior</span>
              </button>
              <button
                className="carousel-control-next"
                type="button"
                data-bs-target="#slider"
                data-bs-slide="next"
              >
                <span
                  className="carousel-control-next-icon"
                  aria-hidden="true"
                ></span>
                <span className="visually-hidden">Siguiente</span>
              </button>
              {/* indicadores */}
              <div className="carousel-indicators">
                <button
                  type="button"
                  data-bs-target="#slider"
                  data-bs-slide-to="0"
                  className="active"
                  aria-current="true"
                  aria-label="Slide 1"
                ></button>
                <button
                  type="button"
                  data-bs-target="#slider"
                  data-bs-slide-to="1"
                  aria-label="Slide 2"
                ></button>
              </div>
            </div>
          </div>
        </div>
        <br />
        <hr />
      </section>

      {/* PRODUCTOS */}
      <main id="nuestrosproductos">
        <div className="container">
          <div className="row produccion g-0 px-0 mb-5">
            <div className="col">
              <h2 className="titulo text-center py-3 pt-0">
                Nuestros Productos
              </h2>
              <div className="row galeria">
                {/* img1 */}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Aguacate 2.jpg"
                  >
                    <img
                      src="img/Aguacate 2.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img2 */}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Mafalda.jpg"
                  >
                    <img
                      src="img/Mafalda.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img3 */}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Bob Esponja 2.jpg"
                  >
                    <img
                      src="img/Bob Esponja 2.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img4 */}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Coco.jpg"
                  >
                    <img
                      src="img/Coco.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img5 */}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Toy Story.jpg"
                  >
                    <img
                      src="img/Aguacate. Parejajpg.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 6 */}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Escandalosos Amigos.jpg"
                  >
                    <img
                      src="img/Escandalosos Amigos.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 7*/}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Barman.jpg"
                  >
                    <img
                      src="img/Barman.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 8*/}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Loonet Tunes.jpg"
                  >
                    <img
                      src="img/Cerdito.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 9*/}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Liga de la Justicia.jpg"
                  >
                    <img
                      src="img/Liga de la Justicia.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 10*/}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Micke Mouse.jpg"
                  >
                    <img
                      src="img/Micke Mouse.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 11*/}
                <div className="contenedor-imagen mb-4 col-md-3 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Minni Mouse.jpg"
                  >
                    <img
                      src="img/Minni Mouse.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 12*/}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Scoby Do.jpg"
                  >
                    <img
                      src="img/Scoby Do.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 13*/}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Bob Esponja.jpg"
                  >
                    <img
                      src="img/Bob Esponja.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
                {/* img 14*/}
                <div className="contenedor-imagen mb-4 col-md-4 col-12">
                  <a
                    href="#"
                    data-bs-toggle="modal"
                    data-bs-target="#modal-galeria"
                    data-bs-image="img/Spider Man.jpg"
                  >
                    <img
                      src="img/Spider Man.jpg"
                      className="gal d-block w-100"
                      alt=""
                    />
                  </a>
                </div>
              </div>
            </div>
          </div>
          <hr />
        </div>
        <br />
      </main>

      {/* MODAL */}
      <div
        className="modal fade"
        id="modal-galeria"
        tabIndex="-1"
        aria-hidden="true"
      >
        <div className="modal-dialog modal-dialog-centered modal-lg">
          <div className="modal-content">
            <div className="modal-body p-0">
              <img
                src=""
                className="img-fluid modal-img-custom"
                id="imagenModal"
                alt="Imagen ampliada"
              />
            </div>
          </div>
        </div>
      </div>

      {/* QUIÉNES SOMOS */}
      <section id="quienes-somos" className="container">
        <div className="feature-card text-center">
          <h2 className="text-center">Quiénes Somos</h2>
          <div className="container">
            <div className="row text-center">
              <div className="col-md-6 mb-4 d-flex flex-column align-items-center my-4">
                <p className="parrafo fs-5 text-black">
                  Vibra Positiva nació en 2020 como una iniciativa familiar que
                  combinó creatividad, pasión por el diseño y visión
                  emprendedora. Empezamos elaborando productos de bioseguridad,
                  y fue una tela con estampado de aguacates la que nos inspiró a
                  ir más allá. A partir de ese momento, descubrimos en las
                  pijamas una forma de expresar bienestar, color y personalidad.
                  Creamos nuestros primeros diseños digitales con dedicación y
                  comenzamos a compartirlos en redes sociales, donde muchas
                  personas conectaron con nuestra propuesta. Hoy, seguimos
                  creciendo con el mismo propósito: ofrecer comodidad, estilo y
                  buena energía en cada prenda, acompañando los momentos de
                  descanso con auténtica vibra positiva.
                </p>
              </div>
              <div className="col-md-6 mb-4 d-flex justify-content-center align-items-center my-4">
                <img
                  src="img/Logo Vibra Positiva.jpg"
                  className="logo mb-3 d-flex justify-content-center align-items-center"
                  alt="Diseño"
                />
              </div>
            </div>
          </div>
        </div>
        <br />
        <br />
        <hr />
      </section>

      {/* DISEÑO / COMODIDAD / CALIDAD */}
      <section>
        <div className="container">
          <div className="row g-1">
            {/* Diseño */}
            <div className="col-md-4 mb-5">
              <div className="feature-card text-center">
                <img
                  src="img/pijamas.jpg"
                  alt="Diseño"
                  style={{ maxWidth: "120px" }}
                  className="mb-3"
                />
                <h5 className="fw-bold">Diseño</h5>
                <p className="text-muted text-justify text-center">
                  Imaginamos juntos qué es lo que más te gustaría, todo nuestro
                  equipo de diseño está presto siempre a escucharte y a pensar
                  lo impensable para ti. Si algún día tienes una idea de Pijama
                  o babucha y la quieres compartir, estamos aquí en cualquier
                  canal para desarrollarla.
                </p>
              </div>
            </div>
            {/* Comodidad */}
            <div className="col-md-4 mb-5">
              <div className="feature-card text-center">
                <img
                  src="img/corazon morado.png"
                  alt="Comodidad"
                  style={{ maxWidth: "120px" }}
                  className="mb-3"
                />
                <h5 className="fw-bold">Comodidad</h5>
                <p className="text-muted text-justify text-center">
                  Investigamos los materiales más cómodos y con la mejor
                  sensación al tacto con la piel, de esta manera cuando tocas tu
                  lugar de descanso vas a experimentar una sensación
                  indescriptible.
                </p>
              </div>
            </div>
            {/* Calidad */}
            <div className="col-md-4 mb-5">
              <div className="feature-card text-center">
                <img
                  src="img/Maquina de Coser.jpg"
                  alt="Calidad"
                  style={{ maxWidth: "120px" }}
                  className="mb-3"
                />
                <h5 className="fw-bold">Calidad</h5>
                <p className="text-muted text-justify text-center">
                  Fabricamos tus hermosas pijamas, todo un equipo de madres
                  cabeza de hogar expertas en el proceso textil. Nosotros mismos
                  hacemos todo el proceso desde el corte, hasta la confección y
                  empaque, comprometidos en darte un diseño único de excelente
                  calidad.
                </p>
              </div>
            </div>
          </div>
          <br />
          <hr />
        </div>
      </section>

      {/* UBICACIÓN */}
      <section id="ubicacion" className="container mt-2 mb-5">
        <h2 className="text-center mb-4 poiret-one-font fw-bold">
          Dónde Estamos
        </h2>
        <div className="row justify-content-center">
          <div className="col-12 col-md-10 bg-white p-2 rounded shadow">
            <iframe
              className="mapa d-block mx-auto"
              src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d4093.575411821896!2d-74.08750489789102!3d4.586985249402693!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x8e3f99029e31d91b%3A0xec805fcdd24c029d!2zQ2wuIDIgU3VyICMgMTAtMzksIEFudG9uaW8gTmFyacOxbywgQm9nb3TDoSwgRC5DLiwgQm9nb3TDoSwgQm9nb3TDoSwgRC5DLg!5e0!3m2!1ses-419!2sco!4v1750648259328!5m2!1ses-419!2sco"
              width="100%"
              height="450"
              style={{ border: 0 }}
              allowFullScreen=""
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
              title="mapa"
            ></iframe>
          </div>
        </div>
      </section>
    </>
  );
}
