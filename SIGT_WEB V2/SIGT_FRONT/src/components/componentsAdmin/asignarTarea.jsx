import React, { useState, useEffect } from "react";
import Swal from "sweetalert2";

function AsignarTareas() {
  const [empleados, setEmpleados] = useState([]);
  const [productos, setProductos] = useState([]);
  const [formData, setFormData] = useState({
    Descripcion: "",
    FechaAsignacion: "",
    FechaLimite: "",
    EstadoTarea: "Pendiente",
    Prioridad: "",
    Persona_FK: "",
    Producto_FK: "",
  });
  const [cantidad, setCantidad] = useState("");
  const [isLoadingData, setIsLoadingData] = useState(true);

  useEffect(() => {
    const cargarDatos = async () => {
      setIsLoadingData(true);
      try {
        const token = localStorage.getItem("token");
        
        if (!token) {
          Swal.fire({
            icon: "error",
            title: "Error",
            text: "No se encontró token de autenticación",
            confirmButtonColor: "#d33",
          });
          return;
        }

        // Cargar empleados y productos en paralelo
        await Promise.all([fetchEmpleados(token), fetchProductos(token)]);

        // Establecer fecha de hoy
        const hoy = new Date().toISOString().split("T")[0];
        setFormData((prev) => ({ ...prev, FechaAsignacion: hoy }));
      } catch (error) {
        console.error("Error al cargar datos:", error);
        Swal.fire({
          icon: "error",
          title: "Error",
          text: "Error al cargar datos iniciales",
          confirmButtonColor: "#d33",
        });
      } finally {
        setIsLoadingData(false);
      }
    };

    cargarDatos();
  }, []);

  const fetchEmpleados = async (token) => {
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/persona`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });
      const data = await response.json();

      const soloEmpleados = data.body.filter(
        (persona) => persona.Rol?.NombreRol?.toLowerCase() === "empleado"
      );
      setEmpleados(soloEmpleados);
      console.log("Empleados cargados:", soloEmpleados.length);
    } catch (error) {
      console.error("Error al obtener empleados:", error);
      Swal.fire({
        icon: "error",
        title: "Error",
        text: "No se pudieron obtener los empleados",
        confirmButtonColor: "#d33",
      });
    }
  };

  const fetchProductos = async (token) => {
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/producto`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });
      const data = await response.json();

      const productosFormateados = data.body.map((p) => ({
        id: p.idProducto,
        nombre: p.NombreProducto || "",
        color: p.Color || "",
        talla: p.Talla || "",
        estampado: p.Estampado || "",
        stock: p.Stock || 0,
        precio: p.Precio || 0,
      }));

      setProductos(productosFormateados);
      console.log("Productos cargados:", productosFormateados.length);
    } catch (error) {
      console.error("Error al cargar productos:", error);
      Swal.fire({
        icon: "error",
        title: "Error",
        text: "No se pudieron obtener los productos",
        confirmButtonColor: "#d33",
      });
    }
  };

  const generarDescripcion = (productoId, cantidadProducir) => {
    if (!productoId || !cantidadProducir) return;

    const producto = productos.find((p) => p.id === parseInt(productoId));
    if (producto) {
      const descripcion = `Hacer ${cantidadProducir} pijamas estilo ${producto.nombre}, color ${producto.color}, talla ${producto.talla}, estampado ${producto.estampado}`;
      setFormData((prev) => ({ ...prev, Descripcion: descripcion }));
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });

    // Regenerar descripción si cambia el producto
    if (name === "Producto_FK") {
      generarDescripcion(value, cantidad);
    }
  };

  const handleCantidadChange = (e) => {
    const value = e.target.value;
    setCantidad(value);
    generarDescripcion(formData.Producto_FK, value);
  };

  const formatearProducto = (producto) => {
    return `${producto.nombre} - ${producto.color} - ${producto.talla} - ${producto.estampado} (Stock: ${producto.stock})`;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validaciones
    if (!formData.Producto_FK) {
      Swal.fire({
        icon: "warning",
        title: "Campo requerido",
        text: "Debe seleccionar un producto",
        confirmButtonColor: "#f39c12",
      });
      return;
    }

    if (!cantidad || parseInt(cantidad) <= 0) {
      Swal.fire({
        icon: "warning",
        title: "Cantidad inválida",
        text: "Debe ingresar una cantidad válida mayor a 0",
        confirmButtonColor: "#f39c12",
      });
      return;
    }

    if (formData.FechaLimite < formData.FechaAsignacion) {
      Swal.fire({
        icon: "warning",
        title: "Fecha inválida",
        text: "La fecha límite no puede ser anterior a la fecha de asignación",
        confirmButtonColor: "#f39c12",
      });
      return;
    }

    const tareaData = {
      Descripcion: formData.Descripcion,
      FechaAsignacion: formData.FechaAsignacion,
      FechaLimite: formData.FechaLimite,
      EstadoTarea: "Pendiente",
      Prioridad: formData.Prioridad,
      Persona_FK: parseInt(formData.Persona_FK),
      Producto_FK: parseInt(formData.Producto_FK),
    };

    console.log("Creando tarea:", tareaData);

    try {
      const token = localStorage.getItem("token");
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/tarea`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(tareaData),
      });

      console.log("📡 Status:", response.status);
      const data = await response.json();
      console.log("📡 Response:", data);

      if (response.ok || response.status === 201) {
        Swal.fire({
          icon: "success",
          title: "Tarea asignada",
          text: "La tarea se asignó exitosamente ",
          confirmButtonColor: "#bb4dbb",
        });

        // Limpiar formulario
        const fechaAsignacion = formData.FechaAsignacion;
        setFormData({
          Descripcion: "",
          FechaAsignacion: fechaAsignacion,
          FechaLimite: "",
          EstadoTarea: "Pendiente",
          Prioridad: "",
          Persona_FK: "",
          Producto_FK: "",
        });
        setCantidad("");
      } else {
        Swal.fire({
          icon: "error",
          title: "Error",
          text: data.Message || data.message || "No se pudo asignar la tarea",
          confirmButtonColor: "#d33",
        });
      }
    } catch (error) {
      console.error("❌ Error completo:", error);
      Swal.fire({
        icon: "error",
        title: "Error de conexión",
        text: `Error: ${error.toString()}`,
        confirmButtonColor: "#d33",
      });
    }
  };

  const obtenerNombreCompleto = (empleado) => {
    const partes = [
      empleado.Primer_Nombre,
      empleado.Segundo_Nombre || "",
      empleado.Primer_Apellido,
      empleado.Segundo_Apellido || "",
    ].filter(Boolean);
    return partes.join(" ");
  };

  if (isLoadingData) {
    return (
      <section className="container">
        <div className="card shadow-lg border-0 overflow-hidden">
          <div className="text-center py-5">
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Cargando...</span>
            </div>
            <p className="mt-3">Cargando datos...</p>
          </div>
        </div>
      </section>
    );
  }

  return (
    <>
      <section className="container">
        <div className="card shadow-lg border-0 overflow-hidden">
          <div className="row text-center align-items-stretch">
            {/* Formulario */}
            <div className="col-md-8 d-flex flex-column align-items-center justify-content-center my-5">
              <form onSubmit={handleSubmit}>
                <p className="parrafo fs-5 text-black merriweather-font text-center">
                  ¡Vibra Positiva Pijamas!
                  <br />
                  Asigna una nueva tarea a un empleado.
                </p>

                {/* Producto */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="producto" className="form-label">
                    Seleccionar Producto
                  </label>
                  <select
                    className="form-select"
                    id="producto"
                    name="Producto_FK"
                    required
                    value={formData.Producto_FK}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione un producto
                    </option>
                    {productos.length > 0 ? (
                      productos.map((producto) => (
                        <option key={producto.id} value={producto.id}>
                          {formatearProducto(producto)}
                        </option>
                      ))
                    ) : (
                      <option disabled>No hay productos disponibles</option>
                    )}
                  </select>
                  {productos.length === 0 && (
                    <small className="text-muted">
                      No se encontraron productos registrados
                    </small>
                  )}
                </div>

                {/* Cantidad */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="cantidad" className="form-label">
                    Cantidad a Producir
                  </label>
                  <input
                    type="number"
                    className="form-control"
                    id="cantidad"
                    placeholder="Ej: 25"
                    required
                    min="1"
                    value={cantidad}
                    onChange={handleCantidadChange}
                  />
                </div>

                {/* Descripción (auto-generada) */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="descripcion" className="form-label">
                    Descripción de la Tarea
                  </label>
                  <textarea
                    className="form-control"
                    id="descripcion"
                    name="Descripcion"
                    rows="3"
                    placeholder="Se generará automáticamente..."
                    required
                    value={formData.Descripcion}
                    readOnly
                    style={{ backgroundColor: "#f8f9fa" }}
                  />
                  {!formData.Descripcion && (
                    <small className="text-muted">
                      Seleccione un producto y cantidad para generar la descripción
                    </small>
                  )}
                </div>

                {/* Fecha Asignación */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="fechaAsignacion" className="form-label">
                    Fecha de Asignación
                  </label>
                  <input
                    type="date"
                    className="form-control"
                    id="fechaAsignacion"
                    name="FechaAsignacion"
                    required
                    value={formData.FechaAsignacion}
                    onChange={handleChange}
                  />
                </div>

                {/* Fecha Límite */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="fechaLimite" className="form-label">
                    Fecha Límite
                  </label>
                  <input
                    type="date"
                    className="form-control"
                    id="fechaLimite"
                    name="FechaLimite"
                    required
                    min={formData.FechaAsignacion}
                    value={formData.FechaLimite}
                    onChange={handleChange}
                  />
                </div>

                {/* Prioridad */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="prioridad" className="form-label">
                    Prioridad
                  </label>
                  <select
                    className="form-select"
                    id="prioridad"
                    name="Prioridad"
                    required
                    value={formData.Prioridad}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione una prioridad
                    </option>
                    <option value="Alta">🔴 Alta</option>
                    <option value="Media">🟡 Media</option>
                    <option value="Baja">🟢 Baja</option>
                    <option value="Urgente">🚨 Urgente</option>
                  </select>
                </div>

                {/* Empleado */}
                <div className="mb-3 text-start w-100">
                  <label htmlFor="empleado" className="form-label">
                    Asignar a Empleado
                  </label>
                  <select
                    className="form-select"
                    id="empleado"
                    name="Persona_FK"
                    required
                    value={formData.Persona_FK}
                    onChange={handleChange}
                  >
                    <option value="" disabled>
                      Seleccione un empleado
                    </option>
                    {empleados.length > 0 ? (
                      empleados.map((empleado) => (
                        <option key={empleado.idPersona} value={empleado.idPersona}>
                          {obtenerNombreCompleto(empleado)}
                        </option>
                      ))
                    ) : (
                      <option disabled>No hay empleados disponibles</option>
                    )}
                  </select>
                  {empleados.length === 0 && (
                    <small className="text-muted">
                      No se encontraron empleados registrados
                    </small>
                  )}
                </div>

                {/* Botón */}
                <div className="d-grid mt-5">
                  <button type="submit" className="boton">
                    Asignar Tarea
                  </button>
                </div>
              </form>
            </div>

            {/* Imagen lateral */}
            <div className="col-md-4 img-col">
              <img src="img/Logo Vibra Positiva.jpg" alt="Registro" />
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

export default AsignarTareas;