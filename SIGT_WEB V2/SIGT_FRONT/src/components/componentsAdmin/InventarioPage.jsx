import React, { useState, useEffect } from "react";

export default function InventarioPage() {
  const [productos, setProductos] = useState([]);
  const [modo, setModo] = useState("crear");
  const [productoEditar, setProductoEditar] = useState(null);
  const [productoEliminar, setProductoEliminar] = useState(null);
  const [busqueda, setBusqueda] = useState("");

  const [form, setForm] = useState({
    nombre: "",
    categoria: "",
    talla: "",
    stock: "",
    precio: "",
    fecha: "",
    ubicacion: "",
    estado: "",
  });

  useEffect(() => {
    fetch("http://localhost:4000/api/productos")
      .then((res) => res.json())
      .then((data) => setProductos(data))
      .catch((err) => console.error("Error al cargar productos:", err));
  }, []);

 

  const handleEditar = (producto) => {
    setModo("editar");
    setProductoEditar(producto.id);
    setForm(producto);
  };

  const handleGuardar = async (e) => {
    e.preventDefault();
    try {
      if (modo === "crear") {
        const res = await fetch("http://localhost:4000/api/productos", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(form),
        });
        const nuevo = await res.json();
        setProductos([...productos, nuevo]);
      } else if (modo === "editar") {
        const res = await fetch(
          `http://localhost:4000/api/productos/${productoEditar}`,
          {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(form),
          }
        );
        const actualizado = await res.json();
        setProductos(
          productos.map((p) =>
            p.id === productoEditar ? actualizado : p
          )
        );
      }
      document.querySelector("#productoModal .btn-close").click();
    } catch (error) {
      console.error("Error al guardar producto:", error);
    }
  };

  const handleEliminarConfirmado = async () => {
    try {
      await fetch(`http://localhost:4000/api/productos/${productoEliminar}`, {
        method: "DELETE",
      });
      setProductos(productos.filter((p) => p.id !== productoEliminar));
      setProductoEliminar(null);
      document.querySelector("#modalEliminar .btn-close").click();
      const modal = new window.bootstrap.Modal(
        document.getElementById("modalEliminado")
      );
      modal.show();
    } catch (error) {
      console.error("Error al eliminar producto:", error);
    }
  };

  const productosFiltrados = productos.filter((p) =>
    p.nombre.toLowerCase().includes(busqueda.toLowerCase())
  );

  return (
    
    <main className="flex-grow-1 p-4 bg-light">
      <h1 className="py-3 text-center merriweather-font">Administrar Inventario</h1>
     
      {/* Barra de búsqueda centrada con icono */}
      <div className="d-flex justify-content-center mb-4">
        <div className="input-group w-50">
          <span className="input-group-text bg-white">
            <i className="bi bi-search"></i>
          </span>
          <input
            type="text"
            className="form-control p-2"
            placeholder="Buscar producto..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
          />
        </div>
      </div>
      <div className="row g-4 mb-4">
        <div className="col-12">
          <div className="card shadow-sm">
            <div className="card-header d-flex justify-content-between align-items-center">
            
              <span className="fw-bold fs-5">Inventario</span>
              <div className="d-flex justify-content-center mb-4">

</div>
            </div>
            <div className="card-body table-responsive">
              <table className="table table-bordered align-middle text-center">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Nombre Producto</th>
                    <th>Categoría</th>
                    <th>Talla</th>
                    <th>Stock</th>
                    <th>Precio</th>
                    <th>Fecha de Ingreso</th>
                    <th>Ubicación en Almacén</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {productosFiltrados.map((p) => (
                    <tr key={p.id}>
                      <td>{p.id}</td>
                      <td>{p.nombre}</td>
                      <td>{p.categoria}</td>
                      <td>{p.talla}</td>
                      <td>{p.stock}</td>
                      <td>{p.precio}</td>
                      <td>{p.fecha}</td>
                      <td>{p.ubicacion}</td>
                      <td>{p.estado}</td>
                      <td>
                        <button
                          className="btn btn-sm btn-warning me-1"
                          onClick={() => handleEditar(p)}
                          data-bs-toggle="modal"
                          data-bs-target="#productoModal"
                        >
                          <i className="bi bi-pencil"></i>
                        </button>
                        <button
                          className="btn btn-sm btn-danger"
                          onClick={() => setProductoEliminar(p.id)}
                          data-bs-toggle="modal"
                          data-bs-target="#modalEliminar"
                        >
                          <i className="bi bi-trash"></i>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="text-center mt-3">
                <a href="AdminInventario.php" className="btn btn-secondary login-btn">
                  Volver
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
  
      {/* --- MODALES --- */}

      {/* Modal Crear/Editar */}
      <div className="modal fade" id="productoModal" tabIndex="-1" aria-hidden="true">
        <div className="modal-dialog">
          <div className="modal-content">
            <form onSubmit={handleGuardar}>
              <div className="modal-header text-black">
                <h5 className="modal-title">
                  {modo === "crear" ? "Agregar Producto" : "Editar Producto"}
                </h5>
                <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div className="modal-body">
                {/* Campos del formulario */}
                {[
                  { label: "Nombre Producto", type: "text", key: "nombre" },
                  { label: "Stock", type: "number", key: "stock" },
                  { label: "Precio", type: "text", key: "precio" },
                  { label: "Fecha de Ingreso", type: "date", key: "fecha" },
                ].map((f) => (
                  <div className="mb-3" key={f.key}>
                    <label className="form-label">{f.label}</label>
                    <input
                      type={f.type}
                      className="form-control"
                      value={form[f.key]}
                      onChange={(e) => setForm({ ...form, [f.key]: e.target.value })}
                      required
                    />
                  </div>
                ))}

                {/* Selects */}
                <div className="mb-3">
                  <label className="form-label">Categoría</label>
                  <select
                    className="form-select"
                    value={form.categoria}
                    onChange={(e) => setForm({ ...form, categoria: e.target.value })}
                    required
                  >
                    <option value="">Seleccione una categoría</option>
                    <option value="Hombre">Hombre</option>
                    <option value="Mujer">Mujer</option>
                    <option value="Niño">Niño</option>
                    <option value="Bebé">Bebé</option>
                  </select>
                </div>

                <div className="mb-3">
                  <label className="form-label">Talla</label>
                  <select
                    className="form-select"
                    value={form.talla}
                    onChange={(e) => setForm({ ...form, talla: e.target.value })}
                    required
                  >
                    <option value="">Seleccione una talla</option>
                    {["2","3","4","5","6","7","8","10","12","14","16","XS","S","M","L","XL","XXL","Unica"].map((t) => (
                      <option key={t} value={t}>{t}</option>
                    ))}
                  </select>
                </div>

                <div className="mb-3">
                  <label className="form-label">Ubicación en Almacén</label>
                  <select
                    className="form-select"
                    value={form.ubicacion}
                    onChange={(e) => setForm({ ...form, ubicacion: e.target.value })}
                    required
                  >
                    <option value="">Seleccione ubicación</option>
                    {[
                      "Estante A1","Estante A2","Estante A3",
                      "Estante B1","Estante B2","Estante B3",
                      "Estante C1","Estante C2",
                      "Bodega Principal","Almacén Secundario","En Tránsito"
                    ].map((u) => (
                      <option key={u} value={u}>{u}</option>
                    ))}
                  </select>
                </div>

                <div className="mb-3">
                  <label className="form-label">Estado</label>
                  <select
                    className="form-select"
                    value={form.estado}
                    onChange={(e) => setForm({ ...form, estado: e.target.value })}
                    required
                  >
                    <option value="">Seleccione estado</option>
                    <option value="Disponible">Disponible</option>
                    <option value="Baja Existencia">Baja Existencia</option>
                    <option value="Agotado">Agotado</option>
                    <option value="Dañado">Dañado</option>
                    <option value="Reservado">Reservado</option>
                    <option value="En Reposición">En Reposición</option>
                  </select>
                </div>
              </div>

              <div className="modal-footer d-flex justify-content-center">
                <button type="button" className="btn btn-danger text-white" data-bs-dismiss="modal">
                  Cancelar
                </button>
                <button type="submit" className="btn custom-btn text-black">
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Modal Eliminar */}
      <div className="modal fade" id="modalEliminar" tabIndex="-1" aria-hidden="true">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header bg-danger text-white">
              <h5 className="modal-title w-100 text-center">¿Estás seguro?</h5>
              <button type="button" className="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div className="modal-body text-center">
              Esta acción no se puede deshacer<br />¿Deseas eliminar este producto?
            </div>
            <div className="modal-footer justify-content-center">
              <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
              <button type="button" className="btn btn-danger" onClick={handleEliminarConfirmado}>
                Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Modal Eliminado */}
      <div className="modal fade" id="modalEliminado" tabIndex="-1" aria-hidden="true">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content border-success">
            <div className="modal-header text-black">
              <h5 className="modal-title">¡Eliminado!</h5>
              <button type="button" className="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div className="modal-body text-center">
              El producto ha sido eliminado exitosamente.
            </div>
            <div className="modal-footer justify-content-center">
              <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">Aceptar</button>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
