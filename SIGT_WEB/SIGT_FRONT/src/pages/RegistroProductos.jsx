import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import FooterLine from "../components/FooterLine";
import Swal from "sweetalert2";

function RegistroProductos() {
  const [formData, setFormData] = useState({
    NombreProducto: "",
    Color: "",
    Talla: "",
    Estampado: "",
    Precio: "",
  });

  const [imagenesSeleccionadas, setImagenesSeleccionadas] = useState([]);
  const [previewImagenes, setPreviewImagenes] = useState([]);
  const [imagenActual, setImagenActual] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const colores = [
    "Rojo",
    "Azul",
    "Verde",
    "Amarillo",
    "Negro",
    "Blanco",
    "Gris",
    "Rosa",
    "Morado",
    "Naranja",
    "Café",
    "Beige",
    "Celeste",
    "Turquesa",
    "Violeta",
    "Fucsia",
    "Marino",
    "Vino",
    "Crema",
  ];

  const tallas = [
    "2",
    "4",
    "6",
    "8",
    "10",
    "12",
    "14",
    "16",
    "XS",
    "S",
    "M",
    "L",
    "XL",
  ];

  const colorMap = {
    rojo: "#ff0000",
    azul: "#0000ff",
    verde: "#00ff00",
    amarillo: "#ffff00",
    negro: "#000000",
    blanco: "#ffffff",
    gris: "#808080",
    rosa: "#ffc0cb",
    morado: "#800080",
    naranja: "#ffa500",
    café: "#8b4513",
    beige: "#f5f5dc",
    celeste: "#87ceeb",
    turquesa: "#40e0d0",
    violeta: "#ee82ee",
    fucsia: "#ff00ff",
    marino: "#000080",
    vino: "#722f37",
    crema: "#fffdd0",
  };

  const getColorCode = (colorName) => {
    if (!colorName) return "transparent";
    return colorMap[colorName.toLowerCase().trim()] || "#cccccc";
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleImagenChange = (e) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;

    const archivosInvalidos = files.filter((f) => !f.type.startsWith("image/"));
    if (archivosInvalidos.length > 0) {
      mostrarError("Por favor selecciona solo archivos de imagen válidos");
      return;
    }

    const archivosGrandes = files.filter((f) => f.size > 5 * 1024 * 1024);
    if (archivosGrandes.length > 0) {
      mostrarError("Algunas imágenes superan los 5MB");
      return;
    }

    if (files.length > 10) {
      mostrarError("Máximo 10 imágenes por producto");
      return;
    }

    setImagenesSeleccionadas(files);

    const previews = [];
    let loadedCount = 0;

    files.forEach((file, index) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        previews[index] = reader.result;
        loadedCount++;
        if (loadedCount === files.length) {
          setPreviewImagenes(previews);
          setImagenActual(0);
        }
      };
      reader.readAsDataURL(file);
    });

    mostrarMensaje(`${files.length} imagen(es) seleccionada(s) ✓`, "success");
  };

  const agregarMasImagenes = (e) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;

    const archivosInvalidos = files.filter((f) => !f.type.startsWith("image/"));
    if (archivosInvalidos.length > 0) {
      mostrarError("Por favor selecciona solo archivos de imagen válidos");
      e.target.value = "";
      return;
    }

    const archivosGrandes = files.filter((f) => f.size > 5 * 1024 * 1024);
    if (archivosGrandes.length > 0) {
      mostrarError("Algunas imágenes superan los 5MB");
      e.target.value = "";
      return;
    }

    const totalImagenes = imagenesSeleccionadas.length + files.length;
    if (totalImagenes > 10) {
      mostrarError(
        `Máximo 10 imágenes. Tienes ${imagenesSeleccionadas.length}, intentas agregar ${files.length}`,
      );
      e.target.value = "";
      return;
    }

    const nuevasImagenes = [...imagenesSeleccionadas, ...files];
    setImagenesSeleccionadas(nuevasImagenes);

    const nuevosPreviews = [...previewImagenes];
    let loadedCount = 0;

    files.forEach((file) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        nuevosPreviews.push(reader.result);
        loadedCount++;
        if (loadedCount === files.length) {
          setPreviewImagenes(nuevosPreviews);
          setImagenActual(nuevosPreviews.length - 1);
        }
      };
      reader.readAsDataURL(file);
    });

    mostrarMensaje(
      `${files.length} imagen(es) agregada(s). Total: ${totalImagenes} ✓`,
      "success",
    );
    e.target.value = "";
  };

  const eliminarImagen = (index) => {
    const nuevasImagenes = imagenesSeleccionadas.filter((_, i) => i !== index);
    const nuevosPreviews = previewImagenes.filter((_, i) => i !== index);

    setImagenesSeleccionadas(nuevasImagenes);
    setPreviewImagenes(nuevosPreviews);

    if (imagenActual >= nuevosPreviews.length && nuevosPreviews.length > 0) {
      setImagenActual(nuevosPreviews.length - 1);
    }

    if (nuevasImagenes.length === 0) {
      document.getElementById("inputImagen").value = "";
      setImagenActual(0);
    }
  };

  const siguienteImagen = () => {
    setImagenActual((prev) => (prev + 1) % previewImagenes.length);
  };

  const anteriorImagen = () => {
    setImagenActual(
      (prev) => (prev - 1 + previewImagenes.length) % previewImagenes.length,
    );
  };

  const mostrarMensaje = (texto, tipo = "success") => {
    const iconMap = {
      success: "success",
      danger: "error",
      error: "error",
      warning: "warning",
      info: "info",
    };

    Swal.fire({
      toast: true,
      position: "top-center",
      icon: iconMap[tipo] || "success",
      title: texto,
      showConfirmButton: false,
      timer: 2500,
      timerProgressBar: true,
    });
  };

  const mostrarError = (mensaje) => {
    mostrarMensaje(mensaje, "danger");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);

    // Validación básica (sin imágenes obligatorias)
    if (
      !formData.NombreProducto ||
      !formData.Color ||
      !formData.Talla ||
      !formData.Precio
    ) {
      mostrarError("Completa todos los campos obligatorios");
      setIsSubmitting(false);
      return;
    }

    try {
      const token = localStorage.getItem("token");

      if (!token) {
        mostrarError("⚠️ No estás autenticado. Por favor inicia sesión.");
        setIsSubmitting(false);
        return;
      }

      const formDataToSend = new FormData();
      formDataToSend.append("NombreProducto", formData.NombreProducto);
      formDataToSend.append("Color", formData.Color);
      formDataToSend.append("Talla", formData.Talla);
      formDataToSend.append("Estampado", formData.Estampado || "Sin estampado");
      formDataToSend.append("Stock", "0");
      formDataToSend.append("Precio", formData.Precio);

      // 👇 Solo agrega imágenes si existen (NO obligatorias)
      if (imagenesSeleccionadas && imagenesSeleccionadas.length > 0) {
        imagenesSeleccionadas.forEach((imagen) => {
          formDataToSend.append("imagenes", imagen);
        });
      }

      const response = await fetch("http://localhost:3001/api/producto", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
        },
        body: formDataToSend,
      });

      const data = await response.json();

      if (response.ok) {
        mostrarMensaje(
          `¡Producto "${formData.NombreProducto}" registrado correctamente!`,
          "success",
        );

        setTimeout(() => {
          limpiarFormulario();
        }, 1000);
      } else {
        const errorMessage =
          data.message ||
          data.Message ||
          data.error ||
          "Error al registrar el producto";

        mostrarError(errorMessage);
      }
    } catch (error) {
      mostrarError("Error de conexión con el servidor");
    } finally {
      setIsSubmitting(false);
    }
  };

  const limpiarFormulario = () => {
    setFormData({
      NombreProducto: "",
      Color: "",
      Talla: "",
      Estampado: "",
      Precio: "",
    });

    setImagenesSeleccionadas([]);
    setPreviewImagenes([]);
    setImagenActual(0);

    // ✅ Limpiar AMBOS inputs
    const inputImagen = document.getElementById("inputImagen");
    const inputAgregarMas = document.getElementById("inputAgregarMas");

    if (inputImagen) inputImagen.value = "";
    if (inputAgregarMas) inputAgregarMas.value = "";

    console.log("✅ Formulario limpiado");
  };

  return (
    <>
      <div style={{ backgroundColor: "#f8f9fa", minHeight: "100vh" }}>
        <header className="py-3 shadow-sm merriweather-font">
          <div className="container">
            <div className="row g-0 justify-content-between align-items-center">
              <div className="col-auto d-flex align-items-center ps-2">
                <img
                  src="/img/Logo Vibra Positiva.jpg"
                  alt="Logo"
                  className="minilogo me-2"
                />
                <h1 className="titulo fw-bold text-uppercase mb-0 fs-7 ms-2">
                  Vibra Positiva Pijamas
                </h1>
              </div>
              <nav className="menu col-auto d-flex flex-column flex-md-row align-items-center gap-1 gap-md-2">
                <a
                  href="/adminInventario"
                  className="co1 d-flex align-items-center text-center text-black text-decoration-none"
                >
                  <div className="login d-flex align-items-center gap-1">
                    <span>Volver</span>
                    <div className="icono">
                      <i className="bi bi-box-arrow-left"></i>
                    </div>
                  </div>
                </a>
              </nav>
            </div>
          </div>
        </header>

        <div
          className="py-4 px-3"
          style={{ maxWidth: "800px", margin: "0 auto" }}
        >
          <div className="card shadow-sm border-0">
            <div className="card-body p-4">
              <form onSubmit={handleSubmit}>
                <div className="text-center mb-4">
                  <h3 className="fw-bold" style={{ color: "#4a4a4a" }}>
                    ¡Vibra Positiva Pijamas!
                  </h3>
                  <p className="text-muted">
                    Registra un nuevo producto en el inventario.
                  </p>
                </div>

                <div className="mb-4">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Imágenes del Producto{" "}
                    <span className="text-danger ms-1">* (máx. 10)</span>
                  </label>

                  <input
                    type="file"
                    id="inputImagen"
                    className="d-none"
                    accept="image/*"
                    multiple
                    onChange={handleImagenChange}
                  />
                  <input
                    type="file"
                    id="inputAgregarMas"
                    className="d-none"
                    accept="image/*"
                    multiple
                    onChange={agregarMasImagenes}
                  />

                  <div
                    onClick={() =>
                      previewImagenes.length === 0 &&
                      document.getElementById("inputImagen").click()
                    }
                    style={{
                      height: "250px",
                      backgroundColor: "#f8f9fa",
                      borderRadius: "10px",
                      border: `2px solid ${previewImagenes.length > 0 ? "#54e075" : "#dc3545"}`,
                      cursor:
                        previewImagenes.length === 0 ? "pointer" : "default",
                      position: "relative",
                      overflow: "hidden",
                    }}
                  >
                    {previewImagenes.length > 0 ? (
                      <>
                        <img
                          src={previewImagenes[imagenActual]}
                          alt={`Preview ${imagenActual + 1}`}
                          style={{
                            width: "100%",
                            height: "100%",
                            objectFit: "contain",
                            backgroundColor: "#f8f9fa",
                          }}
                        />

                        <div
                          className="position-absolute top-0 start-0 m-2 badge bg-success"
                          style={{ fontSize: "0.85rem", padding: "8px 12px" }}
                        >
                          <i className="bi bi-check-circle me-1"></i>
                          {previewImagenes.length} imagen(es)
                        </div>

                        <div className="position-absolute top-0 end-0 m-2">
                          <span
                            className="badge"
                            style={{
                              backgroundColor: "rgba(0,0,0,0.6)",
                              fontSize: "0.85rem",
                              padding: "8px 12px",
                            }}
                          >
                            {imagenActual + 1} / {previewImagenes.length}
                          </span>
                        </div>

                        {previewImagenes.length > 1 && (
                          <>
                            <button
                              type="button"
                              className="btn btn-sm position-absolute top-50 start-0 translate-middle-y ms-2"
                              style={{
                                backgroundColor: "rgba(0,0,0,0.6)",
                                color: "white",
                                border: "none",
                                width: "35px",
                                height: "35px",
                                borderRadius: "50%",
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                anteriorImagen();
                              }}
                            >
                              <i className="bi bi-chevron-left"></i>
                            </button>

                            <button
                              type="button"
                              className="btn btn-sm position-absolute top-50 end-0 translate-middle-y me-2"
                              style={{
                                backgroundColor: "rgba(0,0,0,0.6)",
                                color: "white",
                                border: "none",
                                width: "35px",
                                height: "35px",
                                borderRadius: "50%",
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                siguienteImagen();
                              }}
                            >
                              <i className="bi bi-chevron-right"></i>
                            </button>
                          </>
                        )}

                        {previewImagenes.length > 1 && (
                          <div className="position-absolute bottom-0 start-50 translate-middle-x mb-3 d-flex gap-2">
                            {previewImagenes.map((_, index) => (
                              <span
                                key={index}
                                className="rounded-circle"
                                style={{
                                  width: "10px",
                                  height: "10px",
                                  backgroundColor:
                                    index === imagenActual
                                      ? "white"
                                      : "rgba(255,255,255,0.5)",
                                  cursor: "pointer",
                                  transition: "all 0.3s",
                                }}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setImagenActual(index);
                                }}
                              />
                            ))}
                          </div>
                        )}

                        <div className="position-absolute bottom-0 end-0 m-2 d-flex gap-2">
                          {previewImagenes.length < 10 && (
                            <button
                              type="button"
                              className="btn btn-sm btn-success"
                              style={{ borderRadius: "20px", opacity: "0.9" }}
                              onClick={(e) => {
                                e.stopPropagation();
                                document
                                  .getElementById("inputAgregarMas")
                                  .click();
                              }}
                              title="Agregar más"
                            >
                              <i className="bi bi-plus-circle me-1"></i>
                              Agregar
                            </button>
                          )}

                          <button
                            type="button"
                            className="btn btn-sm btn-dark"
                            style={{ borderRadius: "20px", opacity: "0.9" }}
                            onClick={(e) => {
                              e.stopPropagation();
                              document.getElementById("inputImagen").click();
                            }}
                            title="Reemplazar todas"
                          >
                            <i className="bi bi-arrow-repeat me-1"></i>
                            Reemplazar
                          </button>

                          <button
                            type="button"
                            className="btn btn-sm btn-danger"
                            style={{ borderRadius: "20px", opacity: "0.9" }}
                            onClick={(e) => {
                              e.stopPropagation();
                              eliminarImagen(imagenActual);
                            }}
                            title="Eliminar"
                          >
                            <i className="bi bi-trash"></i>
                          </button>
                        </div>
                      </>
                    ) : (
                      <div className="d-flex flex-column justify-content-center align-items-center h-100">
                        <i
                          className="bi bi-images"
                          style={{ fontSize: "4rem", color: "#dc3545" }}
                        ></i>
                        <p className="mt-2 text-muted fw-semibold">
                          Toca para agregar imágenes
                        </p>
                        <small className="text-danger fw-bold">
                          (Requerido - máx. 10)
                        </small>
                      </div>
                    )}
                  </div>
                </div>

                <div className="mb-3">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Nombre del Producto
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    name="NombreProducto"
                    placeholder="Ej: Pijama Unicornio"
                    required
                    value={formData.NombreProducto}
                    onChange={handleChange}
                  />
                </div>

                <div className="mb-3">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Color
                  </label>
                  <div className="d-flex align-items-center gap-2">
                    <select
                      className="form-select"
                      name="Color"
                      required
                      value={formData.Color}
                      onChange={handleChange}
                    >
                      <option value="" disabled>
                        Seleccione un color
                      </option>
                      {colores.map((color) => (
                        <option key={color} value={color}>
                          {color}
                        </option>
                      ))}
                    </select>
                    {formData.Color && (
                      <div
                        style={{
                          width: "40px",
                          height: "40px",
                          minWidth: "40px",
                          borderRadius: "50%",
                          backgroundColor: getColorCode(formData.Color),
                          border: "2px solid #ddd",
                          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                        }}
                        title={formData.Color}
                      ></div>
                    )}
                  </div>
                </div>

                <div className="mb-3">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Talla
                  </label>
                  <select
                    className="form-select"
                    name="Talla"
                    required
                    value={formData.Talla}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione una talla
                    </option>
                    {tallas.map((talla) => (
                      <option key={talla} value={talla}>
                        {talla}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="mb-3">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Estampado (Opcional)
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    name="Estampado"
                    placeholder="Ej: Unicornios, Estrellas"
                    value={formData.Estampado}
                    onChange={handleChange}
                  />
                </div>

                <div className="mb-4">
                  <label
                    className="form-label fw-bold"
                    style={{ color: "#4a4a4a" }}
                  >
                    Precio (COP)
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    name="Precio"
                    placeholder="Ej: 50000"
                    required
                    min="0"
                    step="100"
                    value={formData.Precio}
                    onChange={handleChange}
                  />
                </div>

                <div className="d-grid">
                  <button
                    type="submit"
                    className="btn btn-lg fw-bold"
                    disabled={isSubmitting}
                    style={{
                      backgroundColor: "#e5bafc",
                      borderColor: "#e5bafc",
                      color: "#4a4a4a",
                      padding: "14px",
                    }}
                  >
                    {isSubmitting ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2"></span>
                        Registrando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-check-circle me-2"></i>
                        REGISTRAR PRODUCTO
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
      <FooterLine />
    </>
  );
}

export default RegistroProductos;
