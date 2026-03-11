import React, { useState, useEffect } from "react";
import Swal from "sweetalert2";
import { Link } from "react-router-dom";

// ─── Helpers ─────────────────────────────────────────────────────────────────
const COLOR_MAP = {
  rojo:"#e53e3e", azul:"#3182ce", verde:"#38a169", amarillo:"#ecc94b",
  negro:"#1a202c", blanco:"#f7fafc", gris:"#718096", rosa:"#f687b3",
  morado:"#805ad5", naranja:"#ed8936", cafe:"#8b4513", café:"#8b4513",
  beige:"#f5f5dc", celeste:"#87ceeb", turquesa:"#40e0d0", violeta:"#9f7aea",
  fucsia:"#d53f8c", marino:"#2c5282", vino:"#702459", crema:"#fffdd0",
};
const getColor = (name) => COLOR_MAP[(name||"").toLowerCase().trim()] || "#a0aec0";

// ─── Modal ────────────────────────────────────────────────────────────────────
function ProductoModal({ producto, onClose, onAgregarAlCarrito }) {
  const [imgIdx, setImgIdx]     = useState(0);
  const [colorSel, setColorSel] = useState(null);
  const [tallaSel, setTallaSel] = useState(null);
  const [cantidad, setCantidad] = useState(1);

  // Inicializar color con el primero disponible
  useEffect(() => {
    if (producto.colores && producto.colores.length > 0) {
      setColorSel(producto.colores[0].color);
    }
  }, [producto]);

  // Imágenes del color seleccionado
  const imagenes = (() => {
    if (!colorSel) return producto.imagen_principal ? [producto.imagen_principal] : [];
    const colorObj = (producto.colores || []).find(c => c.color === colorSel);
    if (colorObj?.imagenes?.length > 0) return colorObj.imagenes;
    const variante = (producto.variantes || []).find(v => v.color === colorSel);
    if (variante?.imagenes?.length > 0) return variante.imagenes;
    return producto.imagen_principal ? [producto.imagen_principal] : [];
  })();

  // Variantes del color seleccionado
  const varsFiltradas = (producto.variantes || []).filter(v => v.color === colorSel);
  const tieneStock    = varsFiltradas.some(v => v.stock > 0);
  const varSel        = varsFiltradas.find(v => v.talla === tallaSel);
  const stockActual   = varSel?.stock || 0;
  const precioMostrar = varSel?.precio || varsFiltradas[0]?.precio || producto.precio_base || 0;

  const handleColor = (color) => {
    setColorSel(color);
    setTallaSel(null);
    setCantidad(1);
    setImgIdx(0);
  };

  // Cerrar con Escape
  useEffect(() => {
    const fn = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", fn);
    return () => window.removeEventListener("keydown", fn);
  }, [onClose]);

  const imgSrc = imagenes[imgIdx] || "/img/no-image.png";

  return (
    <div
      onClick={(e) => e.target === e.currentTarget && onClose()}
      style={{
        position:"fixed", inset:0, zIndex:1055,
        background:"rgba(0,0,0,0.55)", backdropFilter:"blur(4px)",
        display:"flex", alignItems:"center", justifyContent:"center", padding:16,
      }}
    >
      <div style={{
        background:"#fff", borderRadius:18,
        width:"100%", maxWidth:860, maxHeight:"90vh",
        display:"flex", overflow:"hidden",
        boxShadow:"0 24px 64px rgba(0,0,0,0.3)",
      }}>

        {/* ── IZQ: Slider ── */}
        <div style={{ width:"55%", display:"flex", flexDirection:"column", background:"#f0f0f0", flexShrink:0 }}>
          <div style={{ flex:1, position:"relative", minHeight:0, overflow:"hidden" }}>
            <img
              key={imgSrc}
              src={imgSrc}
              alt={producto.nombre}
              onError={(e) => { e.target.onerror=null; e.target.src="/img/no-image.png"; }}
              style={{ width:"100%", height:"100%", objectFit:"cover", display:"block" }}
            />
            {imagenes.length > 1 && (
              <>
                <button
                  onClick={() => setImgIdx(p => Math.max(0, p-1))}
                  style={arrowStyle("left", imgIdx === 0)}
                >‹</button>
                <button
                  onClick={() => setImgIdx(p => Math.min(imagenes.length-1, p+1))}
                  style={arrowStyle("right", imgIdx === imagenes.length-1)}
                >›</button>
                <div style={{ position:"absolute", bottom:10, left:0, right:0, display:"flex", justifyContent:"center", gap:6 }}>
                  {imagenes.map((_, i) => (
                    <button
                      key={i}
                      onClick={() => setImgIdx(i)}
                      style={{
                        width:8, height:8, borderRadius:"50%", border:"none", padding:0,
                        background: i===imgIdx ? "#fff" : "rgba(255,255,255,0.45)",
                        cursor:"pointer",
                      }}
                    />
                  ))}
                </div>
              </>
            )}
          </div>

          {imagenes.length > 1 && (
            <div style={{ display:"flex", gap:8, padding:"10px 12px", overflowX:"auto", background:"#e0e0e0", flexShrink:0 }}>
              {imagenes.map((img, i) => (
                <img
                  key={i}
                  src={img}
                  alt=""
                  onError={(e) => { e.target.onerror=null; e.target.src="/img/no-image.png"; }}
                  onClick={() => setImgIdx(i)}
                  style={{
                    width:60, height:60, objectFit:"cover", borderRadius:8,
                    cursor:"pointer", flexShrink:0,
                    border: i===imgIdx ? "2.5px solid #4299e1" : "2.5px solid transparent",
                    opacity: i===imgIdx ? 1 : 0.5,
                    transition:"all 0.15s",
                  }}
                />
              ))}
            </div>
          )}
        </div>

        {/* ── DER: Controles ── */}
        <div style={{ flex:1, padding:"24px 20px", display:"flex", flexDirection:"column", gap:16, overflowY:"auto" }}>
          {/* Header */}
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
            <div>
              <h5 style={{ margin:0, fontWeight:700, fontSize:17 }}>{producto.nombre}</h5>
              {producto.estampado && (
                <p style={{ margin:"3px 0 0", color:"#888", fontSize:13, fontStyle:"italic" }}>
                  {producto.estampado}
                </p>
              )}
            </div>
            <button onClick={onClose} style={{ background:"none", border:"none", fontSize:20, cursor:"pointer", color:"#aaa", paddingTop:2 }}>✕</button>
          </div>

          {/* Precio */}
          <p style={{ margin:0, fontSize:21, fontWeight:700, color:"#2b6cb0" }}>
            ${Number(precioMostrar).toLocaleString("es-CO")} COP
          </p>

          {/* Colores */}
          {(producto.colores||[]).length > 0 && (
            <div>
              <p style={{ margin:"0 0 8px", fontWeight:600, fontSize:13, color:"#555" }}>
                Color: <span style={{ fontWeight:400 }}>{colorSel}</span>
              </p>
              <div style={{ display:"flex", flexWrap:"wrap", gap:8 }}>
                {producto.colores.map(c => (
                  <button
                    key={c.color}
                    onClick={() => handleColor(c.color)}
                    title={c.color}
                    style={{
                      width:28, height:28, borderRadius:"50%", cursor:"pointer",
                      background: getColor(c.color),
                      border: colorSel===c.color ? "3px solid #4299e1" : "2px solid #ddd",
                      outline: colorSel===c.color ? "2px solid #4299e1" : "none",
                      outlineOffset:2,
                      boxShadow: c.color==="blanco" ? "inset 0 0 0 1px #ccc" : "none",
                    }}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Tallas */}
          {tieneStock ? (
            <>
              <div>
                <p style={{ margin:"0 0 8px", fontWeight:600, fontSize:13, color:"#555" }}>Talla</p>
                <div style={{ display:"flex", flexWrap:"wrap", gap:8 }}>
                  {varsFiltradas.map(v => (
                    <button
                      key={v.talla}
                      onClick={() => { if (v.stock > 0) { setTallaSel(v.talla); setCantidad(1); } }}
                      disabled={v.stock === 0}
                      style={{
                        minWidth:44, height:38, borderRadius:8, fontSize:13, fontWeight:600,
                        cursor: v.stock===0 ? "not-allowed" : "pointer",
                        border: tallaSel===v.talla ? "2px solid #4299e1" : "2px solid #e2e8f0",
                        background: tallaSel===v.talla ? "#ebf8ff" : v.stock===0 ? "#f7fafc" : "#fff",
                        color: v.stock===0 ? "#cbd5e0" : "#2d3748",
                        textDecoration: v.stock===0 ? "line-through" : "none",
                        transition:"all 0.15s",
                      }}
                    >{v.talla}</button>
                  ))}
                </div>
                {tallaSel && (
                  <p style={{ margin:"6px 0 0", fontSize:12, color:"#718096" }}>
                    {stockActual} unidades disponibles
                  </p>
                )}
              </div>

              {/* Cantidad */}
              <div>
                <p style={{ margin:"0 0 8px", fontWeight:600, fontSize:13, color:"#555" }}>Cantidad</p>
                <div style={{ display:"flex", alignItems:"center", gap:0 }}>
                  <button
                    className="btn btn-outline-secondary btn-sm"
                    style={{ width:36, height:36, padding:0, fontSize:18 }}
                    onClick={() => setCantidad(c => Math.max(1, c-1))}
                  >−</button>
                  <span style={{ width:44, textAlign:"center", fontWeight:700, fontSize:16 }}>{cantidad}</span>
                  <button
                    className="btn btn-outline-secondary btn-sm"
                    style={{ width:36, height:36, padding:0, fontSize:18 }}
                    onClick={() => {
                      if (!tallaSel) {
                        Swal.fire({ icon:"warning", title:"Selecciona una talla", timer:1200, showConfirmButton:false });
                        return;
                      }
                      if (cantidad < stockActual) setCantidad(c => c+1);
                    }}
                  >+</button>
                </div>
              </div>

              {/* ── Botón: solo pide iniciar sesión ── */}
              <button
                className="btn btn-primary w-100 mt-auto"
                style={{ padding:"11px 0", fontWeight:600, fontSize:15, borderRadius:10 }}
                onClick={() => onAgregarAlCarrito()}
              >
                <i className="bi bi-cart-plus me-2"></i>Agregar al carrito
              </button>
            </>
          ) : (
            <p style={{ color:"#e53e3e", fontWeight:600, margin:0 }}>
              Sin stock para este color
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

const arrowStyle = (side, disabled) => ({
  position:"absolute", [side]:10, top:"50%", transform:"translateY(-50%)",
  width:34, height:34, borderRadius:"50%", border:"none",
  background:"rgba(255,255,255,0.88)", fontSize:22, cursor:"pointer",
  display:"flex", alignItems:"center", justifyContent:"center",
  opacity: disabled ? 0.25 : 1, transition:"opacity 0.15s",
  boxShadow:"0 2px 8px rgba(0,0,0,0.15)",
});

// ─── Tienda Pública (sin sesión) ──────────────────────────────────────────────
function TiendaPublica() {
  const [productosAgrupados, setProductosAgrupados] = useState([]);
  const [loading, setLoading]                       = useState(true);
  const [error, setError]                           = useState(null);
  const [modalProducto, setModalProducto]           = useState(null);

  useEffect(() => {
    cargarProductos();
  }, []);

  const cargarProductos = async () => {
    try {
      setLoading(true);
      setError(null);

      // Endpoint público, sin token
      const res = await fetch(`${import.meta.env.VITE_API_URL}/api/productos/agrupados`, {
        headers: { "Content-Type": "application/json" },
      });

      const data = await res.json();
      console.log("📦 Respuesta backend (público):", data);

      if (!res.ok) {
        setError(data.message || `Error ${res.status}`);
        return;
      }

      const lista = data.body || data.data || data;

      if (!Array.isArray(lista)) {
        console.error("❌ Formato inesperado:", lista);
        setError("Formato de respuesta inválido");
        return;
      }

      setProductosAgrupados(lista);
    } catch (err) {
      console.error("❌ Error:", err);
      setError(`Error de conexión: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // ── Al intentar agregar → pedir inicio de sesión ──
  const pedirLogin = () => {
    Swal.fire({
      icon: "info",
      title: "¡Inicia sesión primero!",
      text: "Necesitas una cuenta para agregar productos al carrito.",
      confirmButtonText: "Iniciar sesión",
      showCancelButton: true,
      cancelButtonText: "Cancelar",
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#aaa",
    }).then((result) => {
      if (result.isConfirmed) {
        window.location.href = "/login";
      }
    });
  };

  // Imagen de portada de la card
  const getPortada = (producto) => {
    for (const v of (producto.variantes || [])) {
      if (v.imagenes?.length > 0) return v.imagenes[0];
    }
    return producto.imagen_principal || "/img/no-image.png";
  };

  return (
    <>
      <HeaderLine />

      {/* Sin sidebar de cliente ni carrito */}
      <div className="container-fluid d-flex justify-content-end align-items-center py-2 px-3">
        <div className="me-4 d-flex gap-2">
          <Link to="/login" className="btn btn-outline-primary btn-sm">
            <i className="bi bi-person me-1"></i>Iniciar sesión
          </Link>
          <Link to="/register" className="btn btn-primary btn-sm">
            Registrarse
          </Link>
        </div>
      </div>

      <div className="container text-center mt-1 mb-2">
        <h1 className="fw-bold">TIENDA ONLINE</h1>
        <p className="fw-bold">Dulces sueños con estilo</p>
      </div>

      <div className="container mb-5">
        {loading && (
          <div className="text-center my-5">
            <div className="spinner-border text-primary" role="status" />
            <p className="mt-2">Cargando productos...</p>
          </div>
        )}

        {error && (
          <div className="alert alert-danger text-center">
            {error}
            <br />
            <button className="btn btn-primary mt-2" onClick={cargarProductos}>
              <i className="bi bi-arrow-clockwise me-1"></i> Reintentar
            </button>
          </div>
        )}

        {!loading && !error && productosAgrupados.length === 0 && (
          <div className="alert alert-info text-center">No hay productos disponibles.</div>
        )}

        {!loading && !error && productosAgrupados.length > 0 && (
          <div className="row g-4">
            {productosAgrupados.map((producto, index) => {
              const portada    = getPortada(producto);
              const tieneStock = (producto.variantes || []).some(v => v.stock > 0);
              const precio     = producto.precio_base || producto.variantes?.[0]?.precio || 0;

              return (
                <div className="col-md-4" key={`${producto.nombre}-${index}`}>
                  <div
                    className="card shadow-sm h-100"
                    style={{ cursor:"pointer" }}
                    onClick={() => setModalProducto(producto)}
                  >
                    <img
                      src={portada}
                      className="card-img-top"
                      alt={producto.nombre}
                      style={{ height:300, objectFit:"cover" }}
                      onError={(e) => { e.target.onerror=null; e.target.src="/img/no-image.png"; }}
                    />
                    <div className="card-body d-flex flex-column">
                      <h5 className="card-title mb-1">{producto.nombre}</h5>
                      {producto.estampado && (
                        <p className="card-text text-muted fst-italic small mb-2">{producto.estampado}</p>
                      )}

                      {/* Bolitas colores */}
                      {(producto.colores||[]).length > 0 && (
                        <div style={{ display:"flex", gap:5, marginBottom:8, flexWrap:"wrap" }}>
                          {producto.colores.slice(0,7).map(c => (
                            <span key={c.color} title={c.color} style={{
                              width:14, height:14, borderRadius:"50%", flexShrink:0,
                              background: getColor(c.color),
                              border:"1.5px solid #ddd", display:"inline-block",
                              boxShadow: c.color==="blanco" ? "inset 0 0 0 1px #ccc" : "none",
                            }} />
                          ))}
                          {producto.colores.length > 7 && (
                            <span style={{ fontSize:11, color:"#888", alignSelf:"center" }}>
                              +{producto.colores.length-7}
                            </span>
                          )}
                        </div>
                      )}

                      <p className="fw-bold fs-5 text-primary mb-1">
                        ${Number(precio).toLocaleString("es-CO")} COP
                      </p>

                      {!tieneStock ? (
                        <p className="text-danger small fw-bold mb-0">Sin stock</p>
                      ) : (
                        <p className="text-muted small mb-0">
                          <i className="bi bi-hand-index me-1"></i>
                          Toca para ver tallas y colores
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <FooterLine />

      {modalProducto && (
        <ProductoModal
          producto={modalProducto}
          onClose={() => setModalProducto(null)}
          onAgregarAlCarrito={pedirLogin}  // ← solo pide login, no agrega nada
        />
      )}
    </>
  );
}

export default TiendaPublica;