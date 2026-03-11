const API_URL = import.meta.env.VITE_API_URL || `${import.meta.env.VITE_API_URL}/api/reportes`;

const getToken = () => localStorage.getItem('token');

const descargarReporte = async (endpoint, nombreArchivo) => {
  const token = getToken();

  if (!token) throw new Error('No se encontró token de autenticación');

  const response = await fetch(`${API_URL}/${endpoint}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (response.status === 401) throw new Error('Sesión expirada. Por favor inicia sesión nuevamente');
  if (!response.ok) throw new Error(`Error al generar el reporte: ${response.status}`);

  const blob = await response.blob();
  const urlBlob = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = urlBlob;
  a.download = `${nombreArchivo}_${Date.now()}.pdf`;
  a.click();
  window.URL.revokeObjectURL(urlBlob);
};

const reporteService = {
  descargarClientes: () => descargarReporte('clientes/pdf', 'Reporte_Clientes'),
  descargarVentas: () => descargarReporte('ventas/pdf', 'Reporte_Ventas'),
  descargarInventario: () => descargarReporte('inventario/pdf', 'Reporte_Inventario'),
  descargarProduccion: () => descargarReporte('produccion/pdf', 'Reporte_Produccion'),
  descargarEmpleados: () => descargarReporte('empleados/pdf', 'Reporte_Empleados'),
  descargarMovimientos: () => descargarReporte('movimientos/pdf', 'Reporte_Movimientos'),
  descargarCarritosAbandonados: () => descargarReporte('carritos-abandonados/pdf', 'Reporte_Carritos_Abandonados'),
  descargarMisTareas: () => descargarReporte('mis-tareas/pdf', 'Reporte_Mis_Tareas'),
};

export default reporteService;