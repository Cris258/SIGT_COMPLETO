import { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";

const colorMap = {
  rojo:"#e53e3e", azul:"#3182ce", verde:"#38a169", amarillo:"#ecc94b",
  negro:"#1a202c", blanco:"#f7fafc", gris:"#718096", rosa:"#f687b3",
  morado:"#805ad5", naranja:"#ed8936", cafe:"#8b4513", café:"#8b4513",
  beige:"#f5f5dc", celeste:"#87ceeb", turquesa:"#40e0d0", violeta:"#9f7aea",
  fucsia:"#d53f8c", marino:"#2c5282", vino:"#702459", crema:"#fffdd0",
};
const getColorCode = (name) => colorMap[(name||"").toLowerCase().trim()] || "#a0aec0";
const fmt = (n) => new Intl.NumberFormat("es-CO", { style:"currency", currency:"COP", minimumFractionDigits:0 }).format(n);
const fmtFecha = (f) => new Date(f).toLocaleDateString("es-CO", { year:"numeric", month:"short", day:"numeric" });

// Maneja string, array, o null
const procesarImg = (url) => {
  if (!url) return null;
  // Si es array, tomar el primer elemento
  if (Array.isArray(url)) return url.length > 0 ? url[0] : null;
  // Si es string
  const s = String(url).trim();
  if (!s || s === "null") return null;
  if (s.startsWith("http")) return s;
  return `http://localhost:3001${s}`;
};

// ── Modal detalle de venta ────────────────────────────────────────────────────
function ModalDetalle({ venta, onCerrar }) {
  useEffect(() => {
    const fn = (e) => { if (e.key === "Escape") onCerrar(); };
    window.addEventListener("keydown", fn);
    return () => window.removeEventListener("keydown", fn);
  }, [onCerrar]);

  const total = venta.Total || venta.detalles?.reduce((a, d) => a + d.Cantidad * d.PrecioUnitario, 0) || 0;
  const fechaStr = new Date(venta.FechaVenta).toLocaleDateString("es-CO", { year:"numeric", month:"long", day:"numeric" });

  return (
    <div onClick={(e) => e.target === e.currentTarget && onCerrar()} style={{
      position:"fixed", inset:0, zIndex:1060,
      background:"rgba(0,0,0,0.55)", backdropFilter:"blur(4px)",
      display:"flex", alignItems:"center", justifyContent:"center",
      padding:16, overflowY:"auto",
    }}>
      <div style={{
        background:"#fff", borderRadius:16, width:"100%", maxWidth:640,
        boxShadow:"0 24px 64px rgba(0,0,0,0.3)", overflow:"hidden", margin:"auto",
      }}>
        {/* Header */}
        <div style={{ background:"linear-gradient(135deg, #800080, #b000b0)", padding:"22px 28px", color:"#fff" }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
            <div>
              <p style={{ margin:0, fontSize:11, opacity:0.8, letterSpacing:1, textTransform:"uppercase" }}>Vibra Positiva Pijamas</p>
              <h4 style={{ margin:"4px 0 0", fontWeight:800, fontSize:20 }}>Detalle del Pedido</h4>
              <p style={{ margin:"4px 0 0", fontSize:13, opacity:0.85 }}>#{String(venta.idVenta).padStart(6,"0")} · {fechaStr}</p>
            </div>
            <button onClick={onCerrar} style={{
              background:"rgba(255,255,255,0.2)", border:"none", color:"#fff",
              borderRadius:8, padding:"6px 12px", cursor:"pointer", fontSize:13, fontWeight:600,
            }}>✕ Cerrar</button>
          </div>
        </div>

        <div style={{ padding:"22px 28px", display:"flex", flexDirection:"column", gap:18, maxHeight:"70vh", overflowY:"auto" }}>

          {/* Productos */}
          <div>
            <p style={{ margin:"0 0 10px", fontWeight:700, fontSize:11, color:"#800080", textTransform:"uppercase", letterSpacing:0.5 }}>🛍️ Productos</p>
            <div style={{ border:"1px solid #e9d5ff", borderRadius:10, overflow:"hidden" }}>
              <div style={{
                display:"grid", gridTemplateColumns:"2fr 1fr 1fr 1fr",
                background:"#fdf5ff", padding:"10px 14px",
                fontSize:11, fontWeight:700, color:"#800080",
                borderBottom:"1px solid #e9d5ff",
              }}>
                <span>Producto</span>
                <span style={{ textAlign:"center" }}>Cant.</span>
                <span style={{ textAlign:"right" }}>Precio</span>
                <span style={{ textAlign:"right" }}>Subtotal</span>
              </div>

              {venta.detalles && venta.detalles.length > 0 ? venta.detalles.map((d, i) => {
                const img = procesarImg(d.ImagenUrl || d.Imagen || d.imagenUrl || d.imagen);
                return (
                  <div key={i} style={{
                    display:"grid", gridTemplateColumns:"2fr 1fr 1fr 1fr",
                    padding:"12px 14px", alignItems:"center",
                    borderBottom: i < venta.detalles.length-1 ? "1px solid #f3e8ff" : "none",
                    background: i%2===0 ? "#fff" : "#fdf5ff",
                  }}>
                    <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                      {img ? (
                        <img src={img} alt={d.NombreProducto}
                          style={{ width:44, height:44, objectFit:"cover", borderRadius:8, flexShrink:0 }}
                          onError={(e) => { e.target.style.display="none"; }} />
                      ) : (
                        <div style={{
                          width:44, height:44, borderRadius:8, flexShrink:0,
                          background:"#f3e8ff", display:"flex", alignItems:"center", justifyContent:"center", fontSize:18,
                        }}>🩳</div>
                      )}
                      <div>
                        <p style={{ margin:0, fontWeight:600, fontSize:13 }}>{d.NombreProducto || "Sin nombre"}</p>
                        <div style={{ display:"flex", alignItems:"center", gap:5, marginTop:2 }}>
                          <span style={{
                            width:10, height:10, borderRadius:"50%", flexShrink:0,
                            background:getColorCode(d.Color), border:"1px solid #ddd", display:"inline-block",
                          }} />
                          <span style={{ fontSize:11, color:"#888" }}>{d.Color} · Talla {d.Talla}</span>
                        </div>
                      </div>
                    </div>
                    <span style={{ textAlign:"center", fontWeight:600, fontSize:14 }}>{d.Cantidad}</span>
                    <span style={{ textAlign:"right", fontSize:13, color:"#555" }}>{fmt(d.PrecioUnitario)}</span>
                    <span style={{ textAlign:"right", fontWeight:700, fontSize:13 }}>{fmt(d.Cantidad * d.PrecioUnitario)}</span>
                  </div>
                );
              }) : (
                <div style={{ padding:"20px", textAlign:"center", color:"#888", fontSize:13 }}>
                  No hay productos disponibles para este pedido
                </div>
              )}
            </div>
          </div>

          {/* Dirección */}
          {(venta.DireccionEntrega || venta.Ciudad || venta.Departamento) && (
            <div style={{ background:"#fdf5ff", borderRadius:10, padding:"14px 16px", border:"1px solid #e9d5ff" }}>
              <p style={{ margin:"0 0 8px", fontWeight:700, fontSize:11, color:"#800080", textTransform:"uppercase", letterSpacing:0.5 }}>📦 Dirección de entrega</p>
              {venta.DireccionEntrega && <p style={{ margin:"0 0 3px", fontSize:13 }}>{venta.DireccionEntrega}</p>}
              {(venta.Ciudad || venta.Departamento) && (
                <p style={{ margin:0, fontSize:13, color:"#555" }}>
                  {[venta.Ciudad, venta.Departamento].filter(Boolean).join(", ")}
                </p>
              )}
            </div>
          )}

          {/* Total */}
          <div style={{
            display:"flex", justifyContent:"space-between", alignItems:"center",
            background:"linear-gradient(135deg, #fdf5ff, #f3e8ff)",
            border:"1.5px solid #d8b4fe", borderRadius:10, padding:"14px 18px",
          }}>
            <span style={{ fontWeight:700, fontSize:16, color:"#800080" }}>Total del pedido</span>
            <span style={{ fontWeight:800, fontSize:22, color:"#800080" }}>{fmt(total)}</span>
          </div>

          <button onClick={onCerrar} style={{
            width:"100%", padding:"12px 0", background:"#800080",
            color:"#fff", border:"none", borderRadius:10,
            fontWeight:700, fontSize:15, cursor:"pointer",
          }}>
            ✓ Cerrar
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Componente principal ──────────────────────────────────────────────────────
export default function HistorialCompras() {
  const [ventas, setVentas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [ventaModal, setVentaModal] = useState(null);

  useEffect(() => { cargarHistorial(); }, []);

  const cargarHistorial = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("auth_token") || localStorage.getItem("token");
      const currentUserStr = localStorage.getItem("current_user");
      let idPersona = null;
      if (currentUserStr) {
        try {
          const cu = JSON.parse(currentUserStr);
          idPersona = cu.idPersona || cu.id;
        } catch (e) { console.error(e); }
      }
      if (!idPersona) idPersona = localStorage.getItem("idPersona");
      if (!token || !idPersona) throw new Error("No hay sesión activa.");

      const res = await fetch(`http://localhost:3001/api/venta/historial/${idPersona}`, {
        headers: { "Content-Type":"application/json", Authorization:`Bearer ${token}` },
      });
      if (res.status === 404) { setVentas([]); return; }
      if (!res.ok) throw new Error(`Error ${res.status}`);
      const data = await res.json();
      setVentas(data.body || data.data || []);
    } catch (err) {
      console.error("Error historial:", err);
      setVentas([]);
    } finally {
      setLoading(false);
    }
  };

  const ventasFiltradas = ventas.filter(v =>
    (v.idVenta?.toString()||"").includes(search) ||
    (v.FechaVenta||"").toLowerCase().includes(search.toLowerCase()) ||
    (v.Total?.toString()||"").includes(search)
  );

  if (loading) return (
    <div style={{ display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", minHeight:300, gap:16 }}>
      <div className="spinner-border" style={{ color:"#800080" }} role="status" />
      <p style={{ color:"#888", margin:0 }}>Cargando historial...</p>
    </div>
  );

  return (
    <div style={{ maxWidth:860, margin:"0 auto", padding:"32px 16px", textAlign:"center" }}>
      <h2 style={{ fontWeight:800, marginBottom:8, color:"#2d3748" }}>Mis Compras</h2>
      <p style={{ color:"#888", marginBottom:24, fontSize:20 }}>Aquí puedes ver el historial de todos tus pedidos</p>

      {/* Buscador */}
      <div style={{ position:"relative", marginBottom:24, maxWidth:1000 }}>
        <i className="bi bi-search" style={{ position:"absolute", left:12, top:"50%", transform:"translateY(-50%)", color:"#aaa" }} />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por ID, fecha o total..."
          style={{
            width:"100%", padding:"10px 12px 10px 36px", borderRadius:10,
            border:"1.5px solid #e2e8f0", fontSize:14, outline:"none",
            boxSizing:"border-box", background:"#fafafa",
          }}
        />
        {search && (
          <button onClick={() => setSearch("")} style={{
            position:"absolute", right:10, top:"50%", transform:"translateY(-50%)",
            background:"none", border:"none", cursor:"pointer", color:"#aaa", fontSize:16,
          }}>✕</button>
        )}
      </div>

      {/* Lista */}
      {ventasFiltradas.length === 0 ? (
        <div style={{
          textAlign:"center", padding:"48px 24px", borderRadius:16,
          background:"#fdf5ff", border:"1.5px dashed #d8b4fe",
        }}>
          <p style={{ fontSize:40, margin:"0 0 12px" }}>🛍️</p>
          <p style={{ fontWeight:600, color:"#800080", margin:0 }}>
            {search ? "No se encontraron resultados" : "Aún no tienes compras"}
          </p>
          {!search && <p style={{ color:"#aaa", fontSize:13, marginTop:4 }}>Cuando hagas una compra aparecerá aquí</p>}
        </div>
      ) : (
        <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
          {ventasFiltradas.map((venta) => (
            <div key={venta.idVenta} style={{
              background:"#fff", borderRadius:14, overflow:"hidden",
              boxShadow:"0 2px 12px rgba(0,0,0,0.07)", border:"1px solid #f3e8ff",
            }}>
              <div style={{
                background:"linear-gradient(135deg, #800080, #b000b0)",
                padding:"14px 20px", color:"#fff",
                display:"flex", justifyContent:"space-between", alignItems:"center",
                flexWrap:"wrap", gap:8,
              }}>
                <div style={{ display:"flex", alignItems:"center", gap:12 }}>
                  <span style={{ fontWeight:700, fontSize:15 }}>
                    Pedido #{String(venta.idVenta).padStart(6,"0")}
                  </span>
                  <span style={{ background:"rgba(255,255,255,0.2)", borderRadius:20, padding:"2px 10px", fontSize:12 }}>
                    <i className="bi bi-calendar me-1" />{fmtFecha(venta.FechaVenta)}
                  </span>
                </div>
                <span style={{ background:"rgba(255,255,255,0.25)", borderRadius:20, padding:"4px 12px", fontWeight:700, fontSize:14 }}>
                  {fmt(venta.Total)}
                </span>
              </div>

              <div style={{ padding:"14px 20px", display:"flex", justifyContent:"space-between", alignItems:"center", flexWrap:"wrap", gap:12 }}>
                {/* Miniaturas */}
                <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                  <div style={{ display:"flex" }}>
                    {(venta.detalles || []).slice(0,4).map((d, i) => {
                      const img = procesarImg(d.ImagenUrl || d.Imagen || d.imagenUrl || d.imagen);
                      return img ? (
                        <img key={i} src={img} alt={d.NombreProducto}
                          style={{ width:40, height:40, objectFit:"cover", borderRadius:8, border:"2px solid #fff", marginLeft:i>0?-8:0 }}
                          onError={(e) => { e.target.style.display="none"; }} />
                      ) : (
                        <div key={i} style={{
                          width:40, height:40, borderRadius:8, flexShrink:0,
                          background:"#f3e8ff", display:"flex", alignItems:"center",
                          justifyContent:"center", fontSize:16, border:"2px solid #fff", marginLeft:i>0?-8:0,
                        }}>🩳</div>
                      );
                    })}
                  </div>
                  <span style={{ fontSize:13, color:"#888" }}>
                    {venta.detalles?.length || 0} {venta.detalles?.length === 1 ? "producto" : "productos"}
                  </span>
                </div>

                <button onClick={() => setVentaModal(venta)} style={{
                  background:"#800080", color:"#fff", border:"none",
                  borderRadius:10, padding:"8px 18px", fontWeight:600,
                  fontSize:13, cursor:"pointer", display:"flex", alignItems:"center", gap:6,
                }}>
                  <i className="bi bi-receipt" /> Ver detalle
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {ventaModal && (
        <ModalDetalle venta={ventaModal} onCerrar={() => setVentaModal(null)} />
      )}
    </div>
  );
}