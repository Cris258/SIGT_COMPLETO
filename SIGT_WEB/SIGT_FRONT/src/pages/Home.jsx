import React, { useEffect } from "react";
import "../styles/custom.css";

import Header from "../components/componentsMain(tienda)/Header";

import Footer from "../components/componentsMain(tienda)/Footer";

import HomePage from "../components/componentsMain(tienda)/HomePage";

export default function Home() {
  useEffect(() => {
    const imagenes = document.querySelectorAll('[data-bs-toggle="modal"]');

    const mostrarImagenModal = function () {
      const ruta = this.getAttribute("data-bs-image");
      const modalImg = document.getElementById("imagenModal");
      if (modalImg) {
        modalImg.src = ruta;
      }
    };

    imagenes.forEach((img) => {
      img.addEventListener("click", mostrarImagenModal);
    });

    return () => {
      imagenes.forEach((img) => {
        img.removeEventListener("click", mostrarImagenModal);
      });
    };
  }, []);

  return (
    <>
      <Header />
      <HomePage />
      <Footer />
    </>
  );
}
