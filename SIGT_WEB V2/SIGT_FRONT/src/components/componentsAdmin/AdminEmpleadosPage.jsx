


import { useEffect } from "react";

export default function AdminEmpleadosPage() {
  useEffect(() => {
    // Inicializar tooltips, popovers o cualquier JS de Bootstrap si lo usas
    // Puedes dejar vacío si solo dependes de data-bs-*
  }, []);

  return (
    <main className="flex-grow-1 p-4 bg-light">
      <h1 className="py-3 text-center merriweather-font">Administrar Empleados</h1>
      <div className="row g-4 mb-4">
        <div className="col-12">
          <div className="card shadow-sm">
            <div className="card-header d-flex justify-content-between align-items-center">
              <span className="fw-bold fs-5">Empleados</span>
              <div className="btn-group">
                <button
                  className="btn btn-success btn-sm fs-5"
                  id="btnAgregarEmpleado"
                  title="Crear"
                  data-bs-toggle="modal"
                  data-bs-target="#modalEmpleado"
                >
                  <i className="bi bi-person-plus"></i>
                </button>
              </div>
            </div>
            <div className="card-body table-responsive">
              <table className="table table-bordered align-middle text-center">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Empleado</th>
                    <th>Tipo Documento</th>
                    <th>Número Documento</th>
                    <th>EPS</th>
                    <th>Teléfono</th>
                    <th>Correo</th>
                    <th>Rol</th>
                    <th>Tareas Hechas</th>
                    <th>Pendientes</th>
                    <th>Total de Tareas</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody id="tablaEmpleados">
                  <tr>
                    <td>1</td>
                    <td>Cristian Valencia</td>
                    <td>CC</td>
                    <td>1023456789</td>
                    <td>Compensar</td>
                    <td>3208478371</td>
                    <td>crismatius46@gmail.com</td>
                    <td>Corte</td>
                    <td>5</td>
                    <td>2</td>
                    <td>7</td>
                    <td>
                      <button className="btn btn-sm btn-warning btn-editar">
                        <i className="bi bi-pencil"></i>
                      </button>
                      <button className="btn btn-sm btn-danger btn-eliminar">
                        <i className="bi bi-trash"></i>
                      </button>
                    </td>
                  </tr>
                  <tr>
                    <td>2</td>
                    <td>Juan Cruz</td>
                    <td>CC</td>
                    <td>1145678910</td>
                    <td>Capital Salud</td>
                    <td>3129876543</td>
                    <td>juan.crz@gmail.com</td>
                    <td>Domiciliario</td>
                    <td>8</td>
                    <td>1</td>
                    <td>9</td>
                    <td>
                      <button className="btn btn-sm btn-warning btn-editar">
                        <i className="bi bi-pencil"></i>
                      </button>
                      <button className="btn btn-sm btn-danger btn-eliminar">
                        <i className="bi bi-trash"></i>
                      </button>
                    </td>
                  </tr>
                  <tr>
                    <td>3</td>
                    <td>Valeria Meza</td>
                    <td>CC</td>
                    <td>1151544897</td>
                    <td>Compensar</td>
                    <td>3046005887</td>
                    <td>linaphernandez21@gmail.com</td>
                    <td>Ventas</td>
                    <td>8</td>
                    <td>1</td>
                    <td>9</td>
                    <td>
                      <button className="btn btn-sm btn-warning btn-editar">
                        <i className="bi bi-pencil"></i>
                      </button>
                      <button className="btn btn-sm btn-danger btn-eliminar">
                        <i className="bi bi-trash"></i>
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
              <div className="text-center mt-3">
                <a href="admin" className="btn btn-secondary login-btn">
                  Volver
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* MODAL: AGREGAR EMPLEADO */}
      <div
        className="modal fade"
        id="modalEmpleado"
        tabIndex="-1"
        aria-labelledby="modalEmpleadoLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog">
          <div className="modal-content">
            <form id="formEmpleado">
              <div className="modal-header">
                <h5 className="modal-title">Nuevo Empleado</h5>
                <button
                  type="button"
                  className="btn-close"
                  data-bs-dismiss="modal"
                  aria-label="Cerrar"
                ></button>
              </div>
              <div className="modal-body">
                <div className="mb-3">
                  <label htmlFor="nombre" className="form-label">
                    Empleado
                  </label>
                  <input type="text" className="form-control" id="nombre" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="tipoDoc" className="form-label">
                    Tipo Documento
                  </label>
                  <select className="form-select" id="tipoDoc" required>
                    <option value="" disabled selected>
                      Seleccione
                    </option>
                    <option value="CC">Cédula</option>
                    <option value="TI">Tarjeta Identidad</option>
                    <option value="CE">Cédula Extranjería</option>
                    <option value="Pasaporte">Pasaporte</option>
                  </select>
                </div>
                <div className="mb-3">
                  <label htmlFor="numDoc" className="form-label">
                    Número Documento
                  </label>
                  <input type="number" className="form-control" id="numDoc" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="eps" className="form-label">
                    EPS
                  </label>
                  <input type="text" className="form-control" id="eps" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="telefono" className="form-label">
                    Teléfono
                  </label>
                  <input type="text" className="form-control" id="telefono" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="correo" className="form-label">
                    Correo
                  </label>
                  <input type="email" className="form-control" id="correo" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="rolEmpleado" className="form-label">
                    Rol
                  </label>
                  <select className="form-select" id="rolEmpleado" required>
                    <option value="" disabled selected>
                      Seleccione un rol
                    </option>
                    <option value="Corte">Corte</option>
                    <option value="Confección">Confección</option>
                    <option value="Ventas">Ventas</option>
                    <option value="Recepción de Pedidos">Recepción de Pedidos</option>
                    <option value="Operaria de Fileteadora">Operaria de Fileteadora</option>
                    <option value="Operaria de Máquina Collarín">Operaria de Máquina Collarín</option>
                    <option value="Domiciliario">Domiciliario</option>
                  </select>
                </div>
              </div>
              <div className="modal-footer justify-content-center">
                <button type="button" className="btn btn-danger" data-bs-dismiss="modal">
                  Cancelar
                </button>
                <button type="submit" className="btn btn-success" id="btnGuardar" disabled>
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* MODAL: CONFIRMACIÓN */}
      <div
        className="modal fade"
        id="modalExito"
        tabIndex="-1"
        aria-labelledby="modalExitoLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content border-success">
            <div className="modal-header bg-success text-white">
              <h5 className="modal-title" id="modalExitoLabel">
                ¡Empleado agregado!
              </h5>
              <button
                type="button"
                className="btn-close btn-close-white"
                data-bs-dismiss="modal"
              ></button>
            </div>
            <div className="modal-body text-center">
              El empleado se ha registrado correctamente.
            </div>
            <div className="modal-footer justify-content-center">
              <button type="button" className="btn btn-success" data-bs-dismiss="modal">
                Aceptar
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* MODAL DE CONFIRMACIÓN PARA ELIMINAR */}
      <div
        className="modal fade"
        id="modalEliminar"
        tabIndex="-1"
        aria-labelledby="modalEliminarLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content border-danger">
            <div className="modal-header bg-danger text-white">
              <h5 className="modal-title" id="modalEliminarLabel">
                ¿Eliminar empleado?
              </h5>
              <button
                type="button"
                className="btn-close btn-close-white"
                data-bs-dismiss="modal"
              ></button>
            </div>
            <div className="modal-body text-center">
              ¿Estás seguro que deseas eliminar este empleado? Esta acción no se
              puede deshacer.
            </div>
            <div className="modal-footer justify-content-center">
              <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">
                Cancelar
              </button>
              <button type="button" className="btn btn-danger" id="confirmarEliminar">
                Sí, eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
