import React, { useEffect, useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "../styles/Carrito.css";
import HeaderLine from "../components/HeaderLine";
import FooterLine from "../components/FooterLine";
import Swal from "sweetalert2";

// ── Modal: Dirección de envío ─────────────────────────────────────────────────
function ModalDireccion({ onConfirmar, onCerrar }) {
  const [form, setForm] = useState({ DireccionEntrega: "", Ciudad: "", Departamento: "" });
  const [errors, setErrors] = useState({});

  const validar = () => {
    const e = {};
    if (!form.DireccionEntrega.trim()) e.DireccionEntrega = "La dirección es obligatoria";
    if (!form.Ciudad.trim()) e.Ciudad = "La ciudad es obligatoria";
    if (!form.Departamento.trim()) e.Departamento = "El departamento es obligatorio";
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  useEffect(() => {
    const fn = (e) => { if (e.key === "Escape") onCerrar(); };
    window.addEventListener("keydown", fn);
    return () => window.removeEventListener("keydown", fn);
  }, [onCerrar]);

  const inp = (field) => ({
    width: "100%", padding: "10px 12px", borderRadius: 8, fontSize: 14,
    border: errors[field] ? "1.5px solid #e53e3e" : "1.5px solid #e2e8f0",
    outline: "none", marginTop: 4, background: "#fafafa", boxSizing: "border-box",
  });

  return (
    <div onClick={(e) => e.target === e.currentTarget && onCerrar()} style={{
      position: "fixed", inset: 0, zIndex: 1060,
      background: "rgba(0,0,0,0.5)", backdropFilter: "blur(3px)",
      display: "flex", alignItems: "center", justifyContent: "center", padding: 16,
    }}>
      <div style={{
        background: "#fff", borderRadius: 16, width: "100%", maxWidth: 440,
        padding: 28, boxShadow: "0 20px 50px rgba(0,0,0,0.25)",
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div>
            <h5 style={{ margin: 0, fontWeight: 700 }}>📦 Dirección de envío</h5>
            <p style={{ margin: "4px 0 0", fontSize: 13, color: "#888" }}>¿A dónde enviamos tu pedido?</p>
          </div>
          <button onClick={onCerrar} style={{ background: "none", border: "none", fontSize: 20, cursor: "pointer", color: "#aaa" }}>✕</button>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <div>
            <label style={{ fontSize: 13, fontWeight: 600, color: "#444" }}>Dirección</label>
            <input style={inp("DireccionEntrega")} placeholder="Ej: Calle 45 #12-30, Apto 201"
              value={form.DireccionEntrega}
              onChange={(e) => setForm(p => ({ ...p, DireccionEntrega: e.target.value }))} />
            {errors.DireccionEntrega && <p style={{ color: "#e53e3e", fontSize: 12, margin: "3px 0 0" }}>{errors.DireccionEntrega}</p>}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <div>
              <label style={{ fontSize: 13, fontWeight: 600, color: "#444" }}>Ciudad</label>
              <input style={inp("Ciudad")} placeholder="Bogotá"
                value={form.Ciudad}
                onChange={(e) => setForm(p => ({ ...p, Ciudad: e.target.value }))} />
              {errors.Ciudad && <p style={{ color: "#e53e3e", fontSize: 12, margin: "3px 0 0" }}>{errors.Ciudad}</p>}
            </div>
            <div>
              <label style={{ fontSize: 13, fontWeight: 600, color: "#444" }}>Departamento</label>
              <input style={inp("Departamento")} placeholder="Cundinamarca"
                value={form.Departamento}
                onChange={(e) => setForm(p => ({ ...p, Departamento: e.target.value }))} />
              {errors.Departamento && <p style={{ color: "#e53e3e", fontSize: 12, margin: "3px 0 0" }}>{errors.Departamento}</p>}
            </div>
          </div>
        </div>

        <button onClick={() => { if (validar()) onConfirmar(form); }} style={{
          width: "100%", marginTop: 22, padding: "12px 0",
          background: "#800080", color: "#fff", border: "none",
          borderRadius: 10, fontWeight: 700, fontSize: 15, cursor: "pointer",
        }}>
          Confirmar y ver factura →
        </button>
      </div>
    </div>
  );
}

// ── Modal: Factura ────────────────────────────────────────────────────────────
function ModalFactura({ factura, onCerrar }) {
  const fmt = (n) => Number(n).toLocaleString("es-CO");
  const fechaStr = new Date(factura.fecha).toLocaleDateString("es-CO", {
    year: "numeric", month: "long", day: "numeric"
  });

  useEffect(() => {
    const fn = (e) => { if (e.key === "Escape") onCerrar(); };
    window.addEventListener("keydown", fn);
    return () => window.removeEventListener("keydown", fn);
  }, [onCerrar]);

  return (
    <div onClick={(e) => e.target === e.currentTarget && onCerrar()} style={{
      position: "fixed", inset: 0, zIndex: 1060,
      background: "rgba(0,0,0,0.55)", backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center",
      padding: 16, overflowY: "auto",
    }}>
      <div style={{
        background: "#fff", borderRadius: 16, width: "100%", maxWidth: 580,
        boxShadow: "0 24px 64px rgba(0,0,0,0.3)", overflow: "hidden", margin: "auto",
      }}>
        {/* Header */}
        <div style={{ background: "linear-gradient(135deg, #800080, #b000b0)", padding: "24px 28px", color: "#fff" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <p style={{ margin: 0, fontSize: 11, opacity: 0.8, letterSpacing: 1, textTransform: "uppercase" }}>Vibra Positiva Pijamas</p>
              <h4 style={{ margin: "4px 0 0", fontWeight: 800, fontSize: 22 }}>Factura de Compra</h4>
              <p style={{ margin: "4px 0 0", fontSize: 13, opacity: 0.85 }}>#{String(factura.idVenta).padStart(6, "0")}</p>
            </div>
            <div style={{ textAlign: "right" }}>
              <p style={{ margin: 0, fontSize: 11, opacity: 0.8 }}>Fecha</p>
              <p style={{ margin: "2px 0 0", fontSize: 13, fontWeight: 600 }}>{fechaStr}</p>
              <button onClick={onCerrar} style={{
                marginTop: 8, background: "rgba(255,255,255,0.2)", border: "none",
                color: "#fff", borderRadius: 6, padding: "4px 10px", cursor: "pointer", fontSize: 12,
              }}>✕ Cerrar</button>
            </div>
          </div>
        </div>

        <div style={{ padding: "24px 28px", display: "flex", flexDirection: "column", gap: 18 }}>
          {/* Cliente + Envío */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
            <div style={{ background: "#fdf5ff", borderRadius: 10, padding: "14px 16px", border: "1px solid #e9d5ff" }}>
              <p style={{ margin: "0 0 8px", fontWeight: 700, fontSize: 11, color: "#800080", textTransform: "uppercase", letterSpacing: 0.5 }}>👤 Cliente</p>
              <p style={{ margin: "0 0 3px", fontWeight: 600, fontSize: 14 }}>{factura.cliente.nombre}</p>
              {factura.cliente.documento && <p style={{ margin: "0 0 3px", fontSize: 13, color: "#555" }}>CC: {factura.cliente.documento}</p>}
              {factura.cliente.email && <p style={{ margin: "0 0 3px", fontSize: 12, color: "#555" }}>{factura.cliente.email}</p>}
              {factura.cliente.telefono && <p style={{ margin: 0, fontSize: 12, color: "#555" }}>📱 {factura.cliente.telefono}</p>}
            </div>
            <div style={{ background: "#fdf5ff", borderRadius: 10, padding: "14px 16px", border: "1px solid #e9d5ff" }}>
              <p style={{ margin: "0 0 8px", fontWeight: 700, fontSize: 11, color: "#800080", textTransform: "uppercase", letterSpacing: 0.5 }}>📦 Envío</p>
              <p style={{ margin: "0 0 3px", fontSize: 13, color: "#333" }}>{factura.envio.direccion}</p>
              <p style={{ margin: "0 0 3px", fontSize: 13, color: "#555" }}>{factura.envio.ciudad}</p>
              <p style={{ margin: 0, fontSize: 13, color: "#555" }}>{factura.envio.departamento}</p>
            </div>
          </div>

          {/* Productos */}
          <div>
            <p style={{ margin: "0 0 10px", fontWeight: 700, fontSize: 11, color: "#800080", textTransform: "uppercase", letterSpacing: 0.5 }}>🛍️ Productos</p>
            <div style={{ border: "1px solid #e9d5ff", borderRadius: 10, overflow: "hidden" }}>
              <div style={{
                display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr",
                background: "#fdf5ff", padding: "10px 14px",
                fontSize: 11, fontWeight: 700, color: "#800080",
                borderBottom: "1px solid #e9d5ff",
              }}>
                <span>Producto</span>
                <span style={{ textAlign: "center" }}>Cant.</span>
                <span style={{ textAlign: "right" }}>Precio</span>
                <span style={{ textAlign: "right" }}>Subtotal</span>
              </div>
              {factura.productos.map((p, i) => (
                <div key={`${p.nombre}-${p.color}-${p.talla}`} style={{
                  display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr",
                  padding: "12px 14px", alignItems: "center",
                  borderBottom: i < factura.productos.length - 1 ? "1px solid #f3e8ff" : "none",
                  background: i % 2 === 0 ? "#fff" : "#fdf5ff",
                }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    {p.imagen && (
                      <img src={p.imagen} alt={p.nombre}
                        style={{ width: 40, height: 40, objectFit: "cover", borderRadius: 6, flexShrink: 0 }}
                        onError={(e) => { e.target.style.display = "none"; }} />
                    )}
                    <div>
                      <p style={{ margin: 0, fontWeight: 600, fontSize: 13 }}>{p.nombre}</p>
                      <p style={{ margin: 0, fontSize: 11, color: "#888" }}>{p.color} · Talla {p.talla}</p>
                    </div>
                  </div>
                  <span style={{ textAlign: "center", fontWeight: 600 }}>{p.cantidad}</span>
                  <span style={{ textAlign: "right", fontSize: 13, color: "#555" }}>${fmt(p.precioUnitario)}</span>
                  <span style={{ textAlign: "right", fontWeight: 700 }}>${fmt(p.subtotal)}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Total */}
          <div style={{
            display: "flex", justifyContent: "space-between", alignItems: "center",
            background: "linear-gradient(135deg, #fdf5ff, #f3e8ff)",
            border: "1.5px solid #d8b4fe", borderRadius: 10, padding: "14px 18px",
          }}>
            <span style={{ fontWeight: 700, fontSize: 16, color: "#800080" }}>Total a pagar</span>
            <span style={{ fontWeight: 800, fontSize: 22, color: "#800080" }}>${fmt(factura.total)} COP</span>
          </div>

          <button onClick={onCerrar} style={{
            width: "100%", padding: "12px 0", background: "#800080",
            color: "#fff", border: "none", borderRadius: 10,
            fontWeight: 700, fontSize: 15, cursor: "pointer",
          }}>
            ✓ ¡Listo! Continuar comprando
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Componente principal (original intacto + nuevos estados/modales) ──────────
function Carrito() {
  const [carrito, setCarrito] = useState([]);
  const [indexAEliminar, setIndexAEliminar] = useState(null);
  const [cargaInicial, setCargaInicial] = useState(true);
  const [productosSeleccionados, setProductosSeleccionados] = useState([]);
  const [procesandoCompra, setProcesandoCompra] = useState(false);

  // ── NUEVO: estados para los modales ──
  const [mostrarModalDireccion, setMostrarModalDireccion] = useState(false);
  const [factura, setFactura] = useState(null);
  const [productosAComprar, setProductosAComprar] = useState([]);

  useEffect(() => {
    const storedCarro = JSON.parse(localStorage.getItem("carro")) || [];
    console.log("Carrito cargado:", storedCarro);
    setCarrito(storedCarro);
    setProductosSeleccionados(storedCarro.map(() => true));
    setCargaInicial(false);
  }, []);

  useEffect(() => {
    if (!cargaInicial) {
      localStorage.setItem("carro", JSON.stringify(carrito));
      console.log("Carrito guardado:", carrito);
    }
  }, [carrito, cargaInicial]);

  const toggleSeleccion = (index) => {
    const nuevaSeleccion = [...productosSeleccionados];
    nuevaSeleccion[index] = !nuevaSeleccion[index];
    setProductosSeleccionados(nuevaSeleccion);
  };

  const seleccionarTodos = () => {
    setProductosSeleccionados(carrito.map(() => true));
  };

  const deseleccionarTodos = () => {
    setProductosSeleccionados(carrito.map(() => false));
  };

  const actualizarCantidad = (index, nuevaCantidad) => {
    if (nuevaCantidad >= 1 && nuevaCantidad <= carrito[index].stock) {
      const nuevoCarrito = [...carrito];
      nuevoCarrito[index].cantidad = nuevaCantidad;
      setCarrito(nuevoCarrito);
    } else if (nuevaCantidad > carrito[index].stock) {
      Swal.fire({
        icon: "warning",
        title: "Stock insuficiente",
        text: `Solo hay ${carrito[index].stock} unidades disponibles.`,
      });
    }
  };

  const confirmarEliminacion = (index) => {
    setIndexAEliminar(index);
    Swal.fire({
      title: "¿Estás seguro?",
      text: "Este producto será eliminado de tu carrito",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Sí, eliminar",
      cancelButtonText: "Cancelar",
    }).then((result) => {
      if (result.isConfirmed) {
        eliminarProducto();
        Swal.fire({
          icon: "success",
          title: "Eliminado",
          text: "El producto fue eliminado del carrito.",
          timer: 1500,
          showConfirmButton: false,
        });
      }
    });
  };

  const eliminarProducto = () => {
    if (indexAEliminar !== null) {
      const nuevoCarrito = [...carrito];
      const nuevaSeleccion = [...productosSeleccionados];
      nuevoCarrito.splice(indexAEliminar, 1);
      nuevaSeleccion.splice(indexAEliminar, 1);
      setCarrito(nuevoCarrito);
      setProductosSeleccionados(nuevaSeleccion);
      setIndexAEliminar(null);
    }
  };

  const vaciarCarrito = () => {
    Swal.fire({
      title: "¿Vaciar carrito?",
      text: "Se eliminarán todos los productos de tu carrito",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Sí, vaciar",
      cancelButtonText: "Cancelar",
    }).then((result) => {
      if (result.isConfirmed) {
        setCarrito([]);
        setProductosSeleccionados([]);
        localStorage.removeItem("carro");
        Swal.fire({ icon: "success", title: "Carrito vaciado", timer: 1500, showConfirmButton: false });
      }
    });
  };

  // ── MODIFICADO: finalizarCompra ahora abre el modal de dirección ──
  const finalizarCompra = async () => {
    const seleccionados = carrito.filter((_, index) => productosSeleccionados[index]);

    if (seleccionados.length === 0) {
      Swal.fire({ icon: "info", title: "Selecciona un producto", text: "Por favor selecciona al menos un producto para comprar." });
      return;
    }

    // Guardar productos a comprar y abrir modal dirección
    setProductosAComprar(seleccionados);
    setMostrarModalDireccion(true);
  };

  // ── NUEVO: procesarCompra se ejecuta al confirmar la dirección ──
  const procesarCompra = async (direccionData) => {
    setMostrarModalDireccion(false);
    setProcesandoCompra(true);

    try {
      const token = localStorage.getItem("auth_token") || localStorage.getItem("token");

      const currentUserStr = localStorage.getItem("current_user");
      let idPersona = null;
      if (currentUserStr) {
        try {
          const currentUser = JSON.parse(currentUserStr);
          idPersona = currentUser.idPersona || currentUser.id;
        } catch (e) {
          console.error("Error parseando current_user:", e);
        }
      }
      if (!idPersona) idPersona = localStorage.getItem("idPersona");

      if (!token || !idPersona) {
        Swal.fire({ icon: "error", title: "Error de sesión", text: "No se encontró información del usuario. Inicia sesión nuevamente." });
        setProcesandoCompra(false);
        return;
      }

      console.log("🛒 Iniciando proceso de compra...");

      // PASO 1: Crear el Carrito
      const carritoData = { FechaCreacion: new Date().toISOString(), Estado: "Pendiente", Persona_FK: parseInt(idPersona) };
      const carritoResponse = await fetch(`${import.meta.env.VITE_API_URL}/api/carrito`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(carritoData),
      });
      const carritoResult = await carritoResponse.json();
      if (!carritoResponse.ok) throw new Error(carritoResult.message || "Error al crear el carrito");
      const idCarrito = carritoResult.body?.id || carritoResult.id || carritoResult.body?.idCarrito || carritoResult.idCarrito;
      if (!idCarrito) throw new Error("No se pudo obtener el ID del carrito");
      console.log("✅ Carrito creado con ID:", idCarrito);

      // PASO 2: Crear los DetalleCarrito
      await Promise.all(productosAComprar.map(async (producto) => {
        const res = await fetch(`${import.meta.env.VITE_API_URL}/api/detallecarrito`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({ Carrito_FK: idCarrito, Producto_FK: producto.idProducto, Cantidad: producto.cantidad }),
        });
        const result = await res.json();
        if (!res.ok) throw new Error(`Error al guardar detalle de ${producto.nombre}: ${result.message}`);
      }));
      console.log("✅ DetalleCarrito creados");

      // PASO 3: Crear la Venta
      const totalVenta = productosAComprar.reduce((acc, prod) => acc + prod.precio * prod.cantidad, 0);
      const ventaData = {
        Persona_FK: parseInt(idPersona),
        Fecha: new Date().toISOString().split("T")[0],
        Total: totalVenta,
        DireccionEntrega: direccionData.DireccionEntrega,
        Ciudad: direccionData.Ciudad,
        Departamento: direccionData.Departamento,
      };
      const ventaResponse = await fetch(`${import.meta.env.VITE_API_URL}/api/venta`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(ventaData),
      });
      const ventaResult = await ventaResponse.json();
      if (!ventaResponse.ok) throw new Error(ventaResult.message || ventaResult.Message || "Error al crear la venta");
      const idVenta = ventaResult.id || ventaResult.body?.id || ventaResult.body?.idVenta || ventaResult.idVenta;
      if (!idVenta) throw new Error("No se pudo obtener el ID de la venta");
      console.log("✅ Venta creada con ID:", idVenta);

      // PASO 4: Crear los DetalleVenta
      await Promise.all(productosAComprar.map(async (producto) => {
        const res = await fetch(`${import.meta.env.VITE_API_URL}/api/detalleventa`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({ Venta_FK: idVenta, Producto_FK: producto.idProducto, Cantidad: producto.cantidad, PrecioUnitario: producto.precio }),
        });
        const result = await res.json();
        if (!res.ok) throw new Error(`Error al guardar detalle de venta de ${producto.nombre}: ${result.message}`);
      }));
      console.log("✅ DetalleVenta creados");

      // PASO 5: Crear Movimientos de Salida
      await Promise.all(productosAComprar.map(async (producto) => {
        const res = await fetch(`${import.meta.env.VITE_API_URL}/api/movimiento`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({
            Tipo: "Salida", Cantidad: producto.cantidad, Fecha: new Date().toISOString(),
            Motivo: `Venta #${idVenta} - ${producto.nombre}`,
            Persona_FK: parseInt(idPersona), Producto_FK: producto.idProducto,
          }),
        });
        const result = await res.json();
        if (!res.ok) throw new Error(`Error al registrar movimiento de ${producto.nombre}: ${result.Message || result.message}`);
      }));
      console.log("✅ Movimientos de salida creados");

      // PASO 6: Actualizar stock
      await Promise.all(productosAComprar.map(async (producto) => {
        const res = await fetch(`${import.meta.env.VITE_API_URL}/api/producto/${producto.idProducto}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({ Stock: producto.stock - producto.cantidad }),
        });
        if (!res.ok) { const err = await res.json(); throw new Error(`Error al actualizar stock de ${producto.nombre}: ${err.message}`); }
      }));
      console.log("✅ Stock actualizado");

      // PASO 7: Actualizar estado carrito
      await fetch(`${import.meta.env.VITE_API_URL}/api/carrito/${idCarrito}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ Estado: "completado" }),
      });
      console.log("✅ Estado del carrito actualizado");

      // Quitar productos comprados del carrito local
      const carritoActualizado = carrito.filter((_, index) => !productosSeleccionados[index]);
      setCarrito(carritoActualizado);
      setProductosSeleccionados(carritoActualizado.map(() => true));
      localStorage.setItem("carro", JSON.stringify(carritoActualizado));

      // ── NUEVO: obtener datos del cliente para la factura ──
      const currentUser = JSON.parse(localStorage.getItem("current_user") || "{}");

      // Mostrar modal de factura
      setFactura({
        idVenta,
        fecha: new Date(),
        cliente: {
          nombre: `${currentUser.Primer_Nombre || ""} ${currentUser.Primer_Apellido || ""}`.trim() || "Cliente",
          documento: currentUser.Numero_Documento || "",
          email: currentUser.Correo || "",
          telefono: currentUser.Telefono || "",
        },
        envio: {
          direccion: direccionData.DireccionEntrega,
          ciudad: direccionData.Ciudad,
          departamento: direccionData.Departamento,
        },
        productos: productosAComprar.map(p => ({
          nombre: p.nombre,
          color: p.color,
          talla: p.talla,
          imagen: p.imagen || null,
          cantidad: p.cantidad,
          precioUnitario: p.precio,
          subtotal: p.precio * p.cantidad,
        })),
        total: totalVenta,
      });

    } catch (error) {
      console.error("❌ Error en el proceso de compra:", error);
      Swal.fire({ icon: "error", title: "Error en la compra", text: `Error al procesar la compra: ${error.message}` });
    } finally {
      setProcesandoCompra(false);
    }
  };

  const total = carrito.reduce((acc, prod, index) => {
    if (productosSeleccionados[index]) return acc + prod.precio * prod.cantidad;
    return acc;
  }, 0);

  const cantidadSeleccionada = productosSeleccionados.filter(Boolean).length;

  return (
    <>
      <HeaderLine />
      <div className="container my-5">
        <h2 className="text-center mb-4">Tu Carrito de Compras</h2>

        {carrito.length === 0 ? (
          <div className="text-center my-5">
            <p className="fs-4">Tu carrito está vacío</p>
            <a href="/TiendaLine" className="btn btn-primary mt-3">Ir a la tienda</a>
          </div>
        ) : (
          <>
            <div className="d-flex justify-content-between align-items-center mb-3">
              <div>
                <button className="btn btn-sm btn-outline-primary me-2" onClick={seleccionarTodos}>Seleccionar todos</button>
                <button className="btn btn-sm btn-outline-secondary" onClick={deseleccionarTodos}>Deseleccionar todos</button>
              </div>
              <div>
                <span className="badge bg-info text-dark">
                  {cantidadSeleccionada} de {carrito.length} productos seleccionados
                </span>
              </div>
            </div>

            <div className="table-responsive">
              <table className="table text-center align-middle">
                <thead className="table-light">
                  <tr>
                    <th>
                      <input type="checkbox"
                        checked={productosSeleccionados.every(Boolean) && carrito.length > 0}
                        onChange={(e) => { if (e.target.checked) seleccionarTodos(); else deseleccionarTodos(); }} />
                    </th>
                    <th>Imagen</th>
                    <th>Producto</th>
                    <th>Color</th>
                    <th>Talla</th>
                    <th>Precio</th>
                    <th>Cantidad</th>
                    <th>Subtotal</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                 {carrito.map((prod, index) => {
  const subtotal = prod.precio * prod.cantidad;
  const estaSeleccionado = productosSeleccionados[index];
  return (
    <tr key={`${prod.idProducto}-${prod.color}-${prod.talla}`} className={estaSeleccionado ? "" : "table-secondary"} style={{ opacity: estaSeleccionado ? 1 : 0.6 }}>
      <td>
        <input type="checkbox" checked={estaSeleccionado || false} onChange={() => toggleSeleccion(index)} />
      </td>
      <td>
        <img src={prod.imagen || "img/default.jpg"} width="80" alt={prod.nombre}
          style={{ objectFit: "cover", height: "80px" }} />
      </td>
      <td className="fw-bold">{prod.nombre}</td>
      <td>{prod.color}</td>
      <td><span className="badge bg-secondary">{prod.talla}</span></td>
      <td>${prod.precio.toLocaleString()} COP</td>
      <td>
        <div className="d-flex justify-content-center align-items-center gap-2">
          <button className="btn btn-sm btn-outline-secondary"
            onClick={() => actualizarCantidad(index, prod.cantidad - 1)} disabled={prod.cantidad <= 1}>-</button>
          <input type="number" className="form-control text-center" value={prod.cantidad}
            min="1" max={prod.stock} style={{ width: "60px" }}
            onChange={(e) => actualizarCantidad(index, parseInt(e.target.value) || 1)} />
          <button className="btn btn-sm btn-outline-secondary"
            onClick={() => actualizarCantidad(index, prod.cantidad + 1)} disabled={prod.cantidad >= prod.stock}>+</button>
        </div>
        <small className="text-muted d-block mt-1">Stock: {prod.stock}</small>
      </td>
      <td className="fw-bold">${subtotal.toLocaleString()} COP</td>
      <td>
        <button className="btn btn-danger btn-sm" onClick={() => confirmarEliminacion(index)}>
          <i className="bi bi-trash"></i> Eliminar
        </button>
      </td>
    </tr>
  );
})}
                </tbody>
              </table>
            </div>

            <div className="row mt-4">
              <div className="col-md-6">
                <button className="btn btn-outline-danger" onClick={vaciarCarrito} disabled={procesandoCompra}>Vaciar carrito</button>
              </div>
              <div className="col-md-6 text-end">
                <h4>Total a pagar: <span className="text-primary">${total.toLocaleString()} COP</span></h4>
                {cantidadSeleccionada === 0 && <small className="text-danger d-block">Selecciona al menos un producto</small>}
              </div>
            </div>

            <div className="d-flex justify-content-between mt-4">
              <a href="/TiendaLine" className="btn btn-secondary">
                <i className="bi bi-arrow-left"></i> Seguir Comprando
              </a>
              <button className="btn btn-success btn-lg"
                disabled={cantidadSeleccionada === 0 || procesandoCompra}
                onClick={finalizarCompra}>
                {procesandoCompra ? (
                  <><span className="spinner-border spinner-border-sm me-2" role="status"></span>Procesando...</>
                ) : (
                  <><i className="bi bi-check-circle"></i> Finalizar Compra ({cantidadSeleccionada} productos)</>
                )}
              </button>
            </div>
          </>
        )}

        {/* Modal Bootstrap original */}
        <div className="modal fade" id="confirmarModal" tabIndex="-1" aria-labelledby="confirmarLabel" aria-hidden="true">
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title" id="confirmarLabel">¿Estás seguro?</h5>
                <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div className="modal-body">¿Deseas eliminar este producto del carrito?</div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="button" className="btn btn-danger" onClick={eliminarProducto}>Eliminar</button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <FooterLine />

      {/* ── NUEVOS MODALES ── */}
      {mostrarModalDireccion && (
        <ModalDireccion
          onConfirmar={procesarCompra}
          onCerrar={() => setMostrarModalDireccion(false)}
        />
      )}
      {factura && (
        <ModalFactura
          factura={factura}
          onCerrar={() => setFactura(null)}
        />
      )}
    </>
  );
}

export default Carrito;