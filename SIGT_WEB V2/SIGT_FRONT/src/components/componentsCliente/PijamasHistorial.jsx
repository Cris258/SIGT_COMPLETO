import React from "react";

export default function PijamasHistorial() {
  const compras = [
    { modelo: "Mario", talla: "M", precio: "$80.000" },
    { modelo: "Dragon Ball", talla: "L", precio: "$95.000" },
    { modelo: "Stitch", talla: "S", precio: "$85.000" },
  ];

  return (
    <div className="card shadow-sm" style={{ borderRadius: "12px" }}>
      <div className="card-header fw-bold">Historial de Pijamas</div>
      <div className="card-body p-0">
        <table className="table table-bordered text-center align-middle mb-0">
          <thead className="table-light">
            <tr>
              <th>Modelo</th>
              <th>Talla</th>
              <th>Precio</th>
            </tr>
          </thead>
          <tbody>
            {compras.map((c) => (
              <tr key={c.id || `${c.modelo}-${c.talla}`}>
                <td>{c.modelo}</td>
                <td>{c.talla}</td>
                <td>{c.precio}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
