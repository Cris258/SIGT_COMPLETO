import React, { useState, useEffect } from "react";


export default function AdministrarClientes() {
  const [clientes, setClientes] = useState([]);
  const [ setShowFormModal] = useState(false);
  const [ setShowExito] = useState(false);
  const [ setShowEliminar] = useState(false);
  const [ setFormDisabled] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [search, setSearch] = useState("");

  const [form, setForm] = useState({
    nombre: "",
    correo: "",
    telefono: "",
    direccion: "",
    departamento: "",
    productosAdquiridos: "",
    registro: "",
    estado: "",
  });

  const [toDeleteId, setToDeleteId] = useState(null);

  useEffect(() => {
    fetch("http://localhost:3001/api/clientes")
      .then((res) => res.json())
      .then((data) => setClientes(data))
      .catch(() => {
        setClientes([
          {
            id: 1,
            nombre: "María Gómez",
            correo: "maria@gmail.com",
            telefono: "3124567890",
            direccion: "Calle 123 #45-67",
            departamento: "Bogota",
            productosAdquiridos: 12,
            registro: "2024-11-20",
            estado: "Activo",
          },
          {
            id: 2,
            nombre: "Nicolas Pérez",
            correo: "nicolas.pz@hotmail.com",
            telefono: "3109876543",
            direccion: "Carrera 9 #78-45",
            departamento: "Cali",
            productosAdquiridos: 4,
            registro: "2025-01-15",
            estado: "Activo",
          },
          {
            id: 3,
            nombre: "Esteban Andrade",
            correo: "esteban.andra@gmail.com",
            telefono: "3001234567",
            direccion: "Calle 76 h #45 - 67",
            departamento: "Bogotá",
            productosAdquiridos: 7,
            registro: "2024-09-05",
            estado: "Inactivo",
          },
        ]);
      });
  }, []);

  useEffect(() => {
    const ok =
      form.nombre.trim() &&
      form.correo.trim() &&
      form.telefono.toString().trim() &&
      form.direccion.trim() &&
      form.departamento.trim() &&
      form.productosAdquiridos.toString().trim() &&
      form.registro &&
      form.estado;
    setFormDisabled(!ok);
  }, [form]);

  function abrirAgregar() {
    setEditingId(null);
    setForm({
      nombre: "",
      correo: "",
      telefono: "",
      direccion: "",
      departamento: "",
      productosAdquiridos: "",
      registro: "",
      estado: "",
    });
    setShowFormModal(true);
  }

  function abrirEditar(cliente) {
    setEditingId(cliente.id);
    setForm({
      nombre: cliente.nombre,
      correo: cliente.correo,
      telefono: cliente.telefono,
      direccion: cliente.direccion,
      departamento: cliente.departamento,
      productosAdquiridos: cliente.productosAdquiridos,
      registro: cliente.registro,
      estado: cliente.estado,
    });
    setShowFormModal(true);
  }

 

  function pedirEliminar(id) {
    setToDeleteId(id);
    setShowEliminar(true);
  }



  const clientesFiltrados = clientes.filter(
    (c) =>
      c.nombre.toLowerCase().includes(search.toLowerCase()) ||
      c.correo.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="min-vh-100 bg-light">
      <main className="flex-grow-1 p-4">
        <h1 className="py-3 text-center merriweather-font">Administrar Clientes</h1>

        {/* Buscador */}
        <div className="row mb-3">
          <div className="col-12 col-md-6 mx-auto">
            <input
              type="text"
              className="form-control"
              placeholder="Buscar por nombre o correo..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="row g-4 mb-4">
          <div className="col-12">
            <div className="card shadow-sm">
              <div className="card-header d-flex justify-content-between align-items-center">
                <span className="fw-bold fs-5">Clientes</span>
                <div className="btn-group">
                  <button className="btn btn-success btn-sm fs-5" onClick={abrirAgregar}>
                    <i className="bi bi-person-plus"></i>
                  </button>
                </div>
              </div>
              <div className="card-body table-responsive">
                <table className="table table-bordered align-middle text-center">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Nombre</th>
                      <th>Correo</th>
                      <th>Telefono</th>
                      <th>Dirección</th>
                      <th>Departamento</th>
                      <th>Productos Adquiridos</th>
                      <th>Fecha de registro</th>
                      <th>Estado</th>
                      <th>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {clientesFiltrados.map((cliente) => (
                      <tr key={cliente.id}>
                        <td>{cliente.id}</td>
                        <td>{cliente.nombre}</td>
                        <td>{cliente.correo}</td>
                        <td>{cliente.telefono}</td>
                        <td>{cliente.direccion}</td>
                        <td>{cliente.departamento}</td>
                        <td>{cliente.productosAdquiridos}</td>
                        <td>{cliente.registro}</td>
                        <td>{cliente.estado}</td>
                        <td>
                          <button
                            className="btn btn-sm btn-warning me-2"
                            onClick={() => abrirEditar(cliente)}
                          >
                            <i className="bi bi-pencil"></i>
                          </button>
                          <button
                            className="btn btn-sm btn-danger"
                            onClick={() => pedirEliminar(cliente.id)}
                          >
                            <i className="bi bi-trash"></i>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="text-center mt-3">
                  <a href="AdminClientes.php" className="btn btn-secondary login-btn">
                    Volver
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
