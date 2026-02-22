import React, { useState } from 'react';

import Swal from 'sweetalert2';

const CambiarPasswordModal = () => {
  const [passwords, setPasswords] = useState({
    currentPassword: '',
    newPassword: '',
    confirmarPassword: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});
  const [showPasswords, setShowPasswords] = useState({
    actual: false,
    nueva: false,
    confirmar: false
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setPasswords(prev => ({
      ...prev,
      [name]: value
    }));
    
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!passwords.currentPassword.trim()) {
      newErrors.currentPassword = 'La contraseña actual es requerida';
    }
    
    if (!passwords.newPassword.trim()) {
      newErrors.newPassword = 'La nueva contraseña es requerida';
    } else if (passwords.newPassword.length < 6) {
      newErrors.newPassword = 'La contraseña debe tener al menos 6 caracteres';
    }
    
    if (!passwords.confirmarPassword.trim()) {
      newErrors.confirmarPassword = 'Confirmar la contraseña es requerido';
    } else if (passwords.newPassword !== passwords.confirmarPassword) {
      newErrors.confirmarPassword = 'Las contraseñas no coinciden';
    }

    if (passwords.currentPassword && passwords.newPassword && 
        passwords.currentPassword === passwords.newPassword) {
      newErrors.newPassword = 'La nueva contraseña debe ser diferente a la actual';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    console.log('🔒 Iniciando cambio de contraseña...');
    
    if (!validateForm()) {
      console.log('❌ Validación fallida');
      return;
    }

    setLoading(true);

    try {
      const datosPassword = {
        currentPassword: passwords.currentPassword,
        newPassword: passwords.newPassword
      };

      const userId = localStorage.getItem('idPersona');
      const token = localStorage.getItem('token');
      
      console.log('📦 Datos de localStorage:');
      console.log('  - ID Usuario:', userId);
      console.log('  - Token:', token ? 'Existe ✅' : 'No existe ❌');
      
      if (!userId) {
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'No se encontró información del usuario',
          confirmButtonColor: '#d33'
        });
        return;
      }

      const url = `http://localhost:3001/api/persona/${userId}/password`;
      console.log('🌐 Haciendo petición PUT a:', url);

      const response = await fetch(url, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(datosPassword)
      });

      console.log('📡 Respuesta del servidor:');
      console.log('  - Status:', response.status);
      console.log('  - OK:', response.ok);

      const result = await response.json();
      console.log('📥 Respuesta completa:', result);

      if (response.ok) {
        Swal.fire({
          icon: 'success',
          title: '¡Contraseña actualizada!',
          text: 'Tu contraseña fue cambiada correctamente.',
          confirmButtonColor: '#4CAF50'
        }).then(() => {
          setPasswords({
            currentPassword: '',
            newPassword: '',
            confirmarPassword: ''
          });
          
          const modalElement = document.getElementById('modalCambiarPassword');
          const closeButton = modalElement?.querySelector('[data-bs-dismiss="modal"]');
          closeButton?.click();
        });

        console.log('✅ Contraseña actualizada exitosamente');
        
      } else {
        console.error('❌ Error del servidor:', result);
        
        if (result.errors) {
          setErrors(result.errors);
        } else {
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: result.Message || result.message || 'Error al cambiar la contraseña',
            confirmButtonColor: '#d33'
          });
        }
      }
    } catch (error) {
      console.error('💥 Error de conexión:', error);
      Swal.fire({
        icon: 'error',
        title: 'Error de conexión',
        text: 'Por favor, intente nuevamente.',
        confirmButtonColor: '#d33'
      });
    } finally {
      setLoading(false);
      console.log('🏁 Proceso finalizado');
    }
  };

  const togglePasswordVisibility = (field) => {
    setShowPasswords(prev => ({
      ...prev,
      [field]: !prev[field]
    }));
  };

  return (
    <div
      className="modal fade"
      id="modalCambiarPassword"
      tabIndex={-1}
      aria-labelledby="modalCambiarPasswordLabel"
      aria-hidden="true"
    >
      <div className="modal-dialog">
        <div className="modal-content rounded-3 shadow">
          <div className="modal-header text-black">
            <h5 className="modal-title" id="modalCambiarPasswordLabel">
              Cambiar Contraseña
            </h5>
            <button
              type="button"
              className="btn-close btn-close-black"
              data-bs-dismiss="modal"
              aria-label="Cerrar"
            />
          </div>
          
          <form onSubmit={handleSubmit}>
            <div className="modal-body bg-light">
              <div className="mb-3">
                <label className="form-label">
                  Contraseña Actual <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <input
                    type={showPasswords.actual ? "text" : "password"}
                    className={`form-control ${errors.currentPassword ? 'is-invalid' : ''}`}
                    name="currentPassword"
                    value={passwords.currentPassword}
                    onChange={handleInputChange}
                    required
                    disabled={loading}
                  />
                  <button
                    type="button"
                    className="btn btn-outline-secondary"
                    onClick={() => togglePasswordVisibility('actual')}
                    disabled={loading}
                  >
                    <i className={`bi bi-eye${showPasswords.actual ? '-slash' : ''}`}></i>
                  </button>
                </div>
                {errors.currentPassword && (
                  <div className="invalid-feedback d-block">{errors.currentPassword}</div>
                )}
              </div>
              
              <div className="mb-3">
                <label className="form-label">
                  Nueva Contraseña <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <input
                    type={showPasswords.nueva ? "text" : "password"}
                    className={`form-control ${errors.newPassword ? 'is-invalid' : ''}`}
                    name="newPassword"
                    value={passwords.newPassword}
                    onChange={handleInputChange}
                    required
                    disabled={loading}
                  />
                  <button
                    type="button"
                    className="btn btn-outline-secondary"
                    onClick={() => togglePasswordVisibility('nueva')}
                    disabled={loading}
                  >
                    <i className={`bi bi-eye${showPasswords.nueva ? '-slash' : ''}`}></i>
                  </button>
                </div>
                {errors.newPassword && (
                  <div className="invalid-feedback d-block">{errors.newPassword}</div>
                )}
                <small className="text-muted">Mínimo 6 caracteres</small>
              </div>
              
              <div className="mb-3">
                <label className="form-label">
                  Confirmar Nueva Contraseña <span className="text-danger">*</span>
                </label>
                <div className="input-group">
                  <input
                    type={showPasswords.confirmar ? "text" : "password"}
                    className={`form-control ${errors.confirmarPassword ? 'is-invalid' : ''}`}
                    name="confirmarPassword"
                    value={passwords.confirmarPassword}
                    onChange={handleInputChange}
                    required
                    disabled={loading}
                  />
                  <button
                    type="button"
                    className="btn btn-outline-secondary"
                    onClick={() => togglePasswordVisibility('confirmar')}
                    disabled={loading}
                  >
                    <i className={`bi bi-eye${showPasswords.confirmar ? '-slash' : ''}`}></i>
                  </button>
                </div>
                {errors.confirmarPassword && (
                  <div className="invalid-feedback d-block">{errors.confirmarPassword}</div>
                )}
              </div>

              {passwords.newPassword && (
                <div className="mb-3">
                  <small className="text-muted">Fortaleza de contraseña:</small>
                  <div className="progress" style={{ height: '5px' }}>
                    <div
                      className={`progress-bar ${
                        passwords.newPassword.length >= 8 ? 'bg-success' : 
                        passwords.newPassword.length >= 6 ? 'bg-warning' : 'bg-danger'
                      }`}
                      role="progressbar"
                      style={{
                        width: `${Math.min(passwords.newPassword.length * 12.5, 100)}%`
                      }}
                    ></div>
                  </div>
                </div>
              )}
            </div>
            
            <div className="modal-footer">
              <button 
                type="button" 
                className="btn btn-secondary" 
                data-bs-dismiss="modal"
                disabled={loading}
              >
                Cancelar
              </button>
              <button 
                type="submit" 
                className="btn custom-btn"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <span className="spinner-border spinner-border-sm me-2" role="status"></span>
                    Cambiando...
                  </>
                ) : (
                  'Cambiar Contraseña'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CambiarPasswordModal;