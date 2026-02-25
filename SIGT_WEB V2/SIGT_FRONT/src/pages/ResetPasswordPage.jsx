import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Lock, Eye, EyeOff, Key, CheckCircle, Clock, ArrowLeft } from 'lucide-react';
import CustomTextField from '../components/CustomTextField';
import CustomButton from '../components/CustomButton';

const ResetPasswordPage = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  // ============================================
  // ESTILOS INLINE
  // ============================================
  const styles = {
    page: {
      minHeight: '100vh',
      backgroundColor: '#f9fafb',
    },
    appbar: {
      background: 'linear-gradient(to right, #e9d5ff, #fbcfe8)',
      boxShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
    },
    appbarContainer: {
      maxWidth: '1280px',
      margin: '0 auto',
      padding: '0 1.5rem',
    },
    appbarContent: {
      display: 'flex',
      alignItems: 'center',
      height: '5rem',
    },
    backButton: {
      marginRight: '1rem',
      padding: '0.75rem',
      backgroundColor: 'rgba(255, 255, 255, 0.5)',
      border: 'none',
      borderRadius: '9999px',
      cursor: 'pointer',
      transition: 'all 0.2s ease',
      boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
    },
    backButtonHover: {
      backgroundColor: 'rgba(255, 255, 255, 0.8)',
      boxShadow: '0 4px 6px rgba(0, 0, 0, 0.15)',
    },
    title: {
      fontSize: '1.25rem',
      fontWeight: 700,
      color: '#581c87',
    },
    notification: {
      position: 'fixed',
      top: '6rem',
      left: '50%',
      transform: 'translateX(-50%)',
      zIndex: 50,
      padding: '1rem 2rem',
      borderRadius: '0.75rem',
      boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
      fontSize: '1.125rem',
      fontWeight: 500,
      color: 'white',
    },
    notificationSuccess: {
      backgroundColor: '#10b981',
    },
    notificationError: {
      backgroundColor: '#ef4444',
    },
    modalOverlay: {
      position: 'fixed',
      inset: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 50,
      padding: '1rem',
    },
    modal: {
      backgroundColor: 'white',
      borderRadius: '1.5rem',
      boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
      maxWidth: '28rem',
      width: '100%',
      padding: '2rem',
    },
    modalContent: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
    },
    modalIconWrapper: {
      width: '5rem',
      height: '5rem',
      background: 'linear-gradient(to bottom right, #d1fae5, #a7f3d0)',
      borderRadius: '9999px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: '1.5rem',
      boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    },
    modalTitle: {
      fontSize: '1.5rem',
      fontWeight: 700,
      textAlign: 'center',
      marginBottom: '0.75rem',
      color: '#1f2937',
    },
    modalText: {
      fontSize: '1rem',
      color: '#4b5563',
      textAlign: 'center',
      marginBottom: '1.5rem',
      lineHeight: '1.5',
    },
    modalButton: {
      width: '100%',
      backgroundColor: '#581c87',
      color: 'white',
      padding: '1rem',
      borderRadius: '0.75rem',
      fontWeight: 600,
      fontSize: '1.125rem',
      border: 'none',
      cursor: 'pointer',
      transition: 'background-color 0.2s ease',
      boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    },
    content: {
      maxWidth: '36rem',
      margin: '0 auto',
      padding: '3rem 1.5rem',
    },
    iconCircle: {
      marginTop: '2rem',
      marginBottom: '3rem',
      display: 'flex',
      justifyContent: 'center',
    },
    iconWrapper: {
      width: '10rem',
      height: '10rem',
      background: 'linear-gradient(to bottom right, #f3e8ff, #fce7f3)',
      borderRadius: '9999px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    },
    heading: {
      fontSize: '1.875rem',
      fontWeight: 700,
      textAlign: 'center',
      color: '#1f2937',
      marginBottom: '1.5rem',
    },
    description: {
      fontSize: '1.125rem',
      color: '#4b5563',
      textAlign: 'center',
      marginBottom: '3rem',
      lineHeight: '1.75',
      padding: '0 1rem',
    },
    inputWrapper: {
      marginBottom: '1.5rem',
    },
    strengthContainer: {
      marginBottom: '2rem',
    },
    strengthBar: {
      display: 'flex',
      alignItems: 'center',
      gap: '0.75rem',
      marginBottom: '0.5rem',
    },
    strengthBarTrack: {
      flex: 1,
      height: '0.375rem',
      backgroundColor: '#d1d5db',
      borderRadius: '9999px',
      overflow: 'hidden',
    },
    strengthBarFill: {
      height: '100%',
      transition: 'all 0.3s ease',
    },
    strengthText: {
      fontSize: '0.75rem',
      fontWeight: 700,
    },
    strengthRecommendation: {
      fontSize: '0.75rem',
      color: '#4b5563',
    },
    submitWrapper: {
      marginBottom: '1.5rem',
    },
    expirationInfo: {
      background: 'linear-gradient(to bottom right, #fff7ed, #ffedd5)',
      border: '2px solid #fed7aa',
      borderRadius: '1rem',
      padding: '1rem',
      display: 'flex',
      alignItems: 'center',
      boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)',
    },
    expirationText: {
      fontSize: '0.875rem',
      color: '#374151',
      marginLeft: '0.5rem',
    },
  };

  // ============================================
  // BACKEND CONFIGURATION & LOGIC
  // ============================================
  const API_BASE_URL = 'http://localhost:3001/api';
  
  const APP_CONFIG = {
    headers: {
      'Content-Type': 'application/json',
    },
    endpoint: (path) => `${API_BASE_URL}/${path}`,
  };

  const isValidPassword = (password) => {
    return password.length >= 6;
  };

  const resetPassword = async (token, newPassword) => {
    try {
      console.log('🔐 Restableciendo contraseña con token...');
      
      const url = APP_CONFIG.endpoint('persona/reset-password');
      console.log('🌐 URL:', url);
      
      const body = JSON.stringify({
        token: token,
        newPassword: newPassword,
      });
      console.log('📤 Body enviado (sin password)');
      
      const response = await fetch(url, {
        method: 'POST',
        headers: APP_CONFIG.headers,
        body: body,
      });
      
      console.log('📥 Respuesta:', response.status);
      const responseText = await response.text();
      console.log('📥 Body:', responseText);
      
      if (response.status === 200) {
        const data = JSON.parse(responseText);
        console.log('✅ Contraseña actualizada exitosamente');
        
        return {
          success: true,
          message: data.Message || 'Contraseña actualizada exitosamente',
        };
      } else if (response.status === 404) {
        console.log('❌ Usuario no encontrado');
        return {
          success: false,
          message: 'Usuario no encontrado',
        };
      } else {
        const data = JSON.parse(responseText);
        console.log(`❌ Error ${response.status}: ${data.Message}`);
        return {
          success: false,
          message: data.Message || 'Error al restablecer contraseña',
        };
      }
    } catch (e) {
      console.log('❌ Excepción en resetPassword:', e);
      console.log('Stack trace:', e.stack);
      
      if (e.toString().includes('jwt') || e.toString().includes('expired')) {
        return {
          success: false,
          message: 'El token ha expirado. Solicita un nuevo enlace de recuperación.',
        };
      }
      
      return {
        success: false,
        message: `Error de conexión: ${e.message}`,
      };
    }
  };

  // ============================================
  // STATE MANAGEMENT
  // ============================================
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [obscureNewPassword, setObscureNewPassword] = useState(true);
  const [obscureConfirmPassword, setObscureConfirmPassword] = useState(true);
  const [errors, setErrors] = useState({});
  const [notification, setNotification] = useState(null);
  const [showSuccessDialog, setShowSuccessDialog] = useState(false);
  const [token, setToken] = useState(null);
  const [isBackButtonHovered, setIsBackButtonHovered] = useState(false);
  const [isModalButtonHovered, setIsModalButtonHovered] = useState(false);

  // ============================================
  // GET TOKEN FROM URL
  // ============================================
  useEffect(() => {
    const tokenFromUrl = searchParams.get('token');
    
    if (tokenFromUrl) {
      setToken(tokenFromUrl);
      console.log('🔑 Token recibido: Sí');
    } else {
      console.log('🔑 Token recibido: No');
    }
  }, [searchParams]);

  // ============================================
  // VALIDATION
  // ============================================
  const validateForm = () => {
    const newErrors = {};

    if (!newPassword) {
      newErrors.newPassword = 'Por favor ingresa tu nueva contraseña';
    } else if (!isValidPassword(newPassword)) {
      newErrors.newPassword = 'La contraseña debe tener al menos 6 caracteres';
    }

    if (!confirmPassword) {
      newErrors.confirmPassword = 'Por favor confirma tu contraseña';
    } else if (confirmPassword !== newPassword) {
      newErrors.confirmPassword = 'Las contraseñas no coinciden';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // ============================================
  // PASSWORD STRENGTH INDICATOR
  // ============================================
  const getPasswordStrength = () => {
    if (!newPassword) return null;

    if (newPassword.length < 6) {
      return {
        color: '#ef4444',
        text: 'Débil',
        value: 33,
        textColor: '#ef4444',
      };
    } else if (newPassword.length < 8) {
      return {
        color: '#f97316',
        text: 'Media',
        value: 66,
        textColor: '#f97316',
      };
    } else {
      return {
        color: '#10b981',
        text: 'Fuerte',
        value: 100,
        textColor: '#10b981',
      };
    }
  };

  // ============================================
  // HANDLERS
  // ============================================
  const showNotification = (message, type = 'success') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), type === 'success' ? 3000 : 4000);
  };

  const handleResetPassword = async () => {
    if (!validateForm()) return;

    if (!token) {
      showNotification('Token inválido o expirado', 'error');
      return;
    }

    setIsLoading(true);

    try {
      const result = await resetPassword(token, newPassword);

      if (result.success) {
        showNotification(result.message, 'success');
        setShowSuccessDialog(true);
      } else {
        showNotification(result.message, 'error');
      }
    } catch (error) {
      showNotification(`Error: ${error.toString()}`, 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoToLogin = () => {
    navigate('/login', { replace: true });
  };

  const handleGoBack = () => {
    navigate(-1);
  };

  const passwordStrength = getPasswordStrength();

  // ============================================
  // RENDER
  // ============================================
  return (
    <div style={styles.page}>
      {/* AppBar */}
      <div style={styles.appbar}>
        <div style={styles.appbarContainer}>
          <div style={styles.appbarContent}>
            <button
              onClick={handleGoBack}
              style={{
                ...styles.backButton,
                ...(isBackButtonHovered ? styles.backButtonHover : {}),
              }}
              onMouseEnter={() => setIsBackButtonHovered(true)}
              onMouseLeave={() => setIsBackButtonHovered(false)}
              aria-label="Volver atrás"
            >
              <ArrowLeft style={{ width: '1.5rem', height: '1.5rem', color: '#7e22ce' }} />
            </button>
            <h1 style={styles.title}>
              Nueva Contraseña
            </h1>
          </div>
        </div>
      </div>

      {/* Notification */}
      {notification && (
        <div style={{
          ...styles.notification,
          ...(notification.type === 'success' ? styles.notificationSuccess : styles.notificationError)
        }}>
          {notification.message}
        </div>
      )}

      {/* Success Dialog */}
      {showSuccessDialog && (
        <div style={styles.modalOverlay}>
          <div style={styles.modal}>
            <div style={styles.modalContent}>
              <div style={styles.modalIconWrapper}>
                <CheckCircle style={{ width: '3rem', height: '3rem', color: '#10b981' }} />
              </div>
              <h2 style={styles.modalTitle}>
                ¡Contraseña Actualizada!
              </h2>
              <p style={styles.modalText}>
                Tu contraseña ha sido restablecida exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.
              </p>
              <button
                onClick={handleGoToLogin}
                style={{
                  ...styles.modalButton,
                  backgroundColor: isModalButtonHovered ? '#6b21a8' : '#581c87',
                  boxShadow: isModalButtonHovered 
                    ? '0 20px 25px -5px rgba(0, 0, 0, 0.1)' 
                    : '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
                }}
                onMouseEnter={() => setIsModalButtonHovered(true)}
                onMouseLeave={() => setIsModalButtonHovered(false)}
              >
                IR A INICIAR SESIÓN
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Main Content */}
      <div style={styles.content}>
        <div style={styles.iconCircle}>
          <div style={styles.iconWrapper}>
            <Key size={80} style={{ color: '#c084fc' }} />
          </div>
        </div>

        <h2 style={styles.heading}>
          Crear Nueva Contraseña
        </h2>

        <p style={styles.description}>
          Tu nueva contraseña debe ser diferente a las anteriores y tener al menos 6 caracteres.
        </p>

        {/* Nueva Contraseña */}
        <div style={styles.inputWrapper}>
          <CustomTextField
            value={newPassword}
            onChange={setNewPassword}
            label="Nueva Contraseña"
            icon={Lock}
            type={obscureNewPassword ? 'password' : 'text'}
            error={errors.newPassword}
            placeholder="Ingresa tu nueva contraseña"
            suffixIcon={
              <button
                type="button"
                onClick={() => setObscureNewPassword(!obscureNewPassword)}
                style={{
                  color: '#6b7280',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: 0,
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                {obscureNewPassword ? <Eye style={{ width: '1.25rem', height: '1.25rem' }} /> : <EyeOff style={{ width: '1.25rem', height: '1.25rem' }} />}
              </button>
            }
          />
        </div>

        {/* Confirmar Contraseña */}
        <div style={styles.inputWrapper}>
          <CustomTextField
            value={confirmPassword}
            onChange={setConfirmPassword}
            label="Confirmar Contraseña"
            icon={Lock}
            type={obscureConfirmPassword ? 'password' : 'text'}
            error={errors.confirmPassword}
            placeholder="Confirma tu contraseña"
            suffixIcon={
              <button
                type="button"
                onClick={() => setObscureConfirmPassword(!obscureConfirmPassword)}
                style={{
                  color: '#6b7280',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: 0,
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                {obscureConfirmPassword ? <Eye style={{ width: '1.25rem', height: '1.25rem' }} /> : <EyeOff style={{ width: '1.25rem', height: '1.25rem' }} />}
              </button>
            }
          />
        </div>

        {/* Password Strength Indicator */}
        {passwordStrength && (
          <div style={styles.strengthContainer}>
            <div style={styles.strengthBar}>
              <div style={styles.strengthBarTrack}>
                <div
                  style={{
                    ...styles.strengthBarFill,
                    width: `${passwordStrength.value}%`,
                    backgroundColor: passwordStrength.color,
                  }}
                />
              </div>
              <span style={{
                ...styles.strengthText,
                color: passwordStrength.textColor,
              }}>
                {passwordStrength.text}
              </span>
            </div>
            <p style={styles.strengthRecommendation}>
              Recomendación: Usa al menos 8 caracteres con letras y números
            </p>
          </div>
        )}

        <div style={styles.submitWrapper}>
          <CustomButton
            text="RESTABLECER CONTRASEÑA"
            onClick={handleResetPassword}
            isLoading={isLoading}
          />
        </div>

        {/* Token Expiration Info */}
        <div style={styles.expirationInfo}>
          <Clock style={{ width: '1.5rem', height: '1.5rem', color: '#f97316', flexShrink: 0 }} />
          <p style={styles.expirationText}>
            Este enlace expira en 15 minutos
          </p>
        </div>
      </div>
    </div>
  );
};

export default ResetPasswordPage;