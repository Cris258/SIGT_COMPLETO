import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, ArrowLeft, CheckCircle, Lock, Key, Code } from 'lucide-react';
import CustomTextField from '../components/CustomTextField';
import CustomButton from '../components/CustomButton';

const ForgotPasswordPage = () => {
  const navigate = useNavigate();

  /* ===================== ESTILOS ===================== */
  const styles = {
    page: { minHeight: '100vh', backgroundColor: '#f9fafb' },
    appbar: {
      background: 'linear-gradient(to right, #e9d5ff, #fbcfe8)',
      boxShadow: '0 2px 8px rgba(0,0,0,.1)',
    },
    appbarContent: {
      display: 'flex',
      alignItems: 'center',
      height: '5rem',
      padding: '0 1.5rem',
    },
    backButton: {
      marginRight: '1rem',
      padding: '0.75rem',
      borderRadius: '9999px',
      border: 'none',
      cursor: 'pointer',
      backgroundColor: 'rgba(255,255,255,.6)',
    },
    title: { fontSize: '1.25rem', fontWeight: 700, color: '#581c87' },

    content: {
      maxWidth: '36rem',
      margin: '0 auto',
      padding: '3rem 1.5rem',
    },

    iconWrapper: {
      width: '9rem',
      height: '9rem',
      borderRadius: '9999px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      margin: '0 auto 2.5rem',
      background: 'linear-gradient(to bottom right, #f3e8ff, #fce7f3)',
    },

    heading: {
      fontSize: '1.8rem',
      fontWeight: 700,
      textAlign: 'center',
      marginBottom: '1rem',
    },

    description: {
      textAlign: 'center',
      color: '#4b5563',
      marginBottom: '2.5rem',
    },

    modalOverlay: {
      position: 'fixed',
      inset: 0,
      backgroundColor: 'rgba(0,0,0,.5)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 50,
    },

    modal: {
      backgroundColor: '#fff',
      borderRadius: '1rem',
      padding: '2rem',
      maxWidth: '28rem',
      width: '100%',
    },

    modalButton: {
      width: '100%',
      padding: '1rem',
      borderRadius: '0.75rem',
      border: 'none',
      backgroundColor: '#9333ea',
      color: '#fff',
      fontWeight: 600,
      cursor: 'pointer',
      marginBottom: '1rem',
    },

    modalClose: {
      background: 'none',
      border: 'none',
      width: '100%',
      cursor: 'pointer',
      color: '#6b7280',
    },
  };

  /* ===================== CONFIG ===================== */
  const API_BASE_URL = `${import.meta.env.VITE_API_URL}/api`;

  const forgotPassword = async (correo) => {
    const response = await fetch(`${API_BASE_URL}/persona/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ Correo: correo }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.Message || 'Error al enviar correo');
    }

    return data;
  };

  /* ===================== STATES ===================== */
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const [showDevDialog, setShowDevDialog] = useState(false);
  const [resetToken, setResetToken] = useState(null);

  /* ===================== HANDLERS ===================== */
  const handleForgotPassword = async () => {
    if (!email) return;

    setIsLoading(true);
    try {
      const result = await forgotPassword(email);

      setEmailSent(true);

      if (result.resetLink) {
        const url = new URL(result.resetLink);
        const token = url.searchParams.get('token');
        setResetToken(token);
        setShowDevDialog(true);
      }
    } catch (e) {
      alert(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoToResetPassword = () => {
    setShowDevDialog(false);
    navigate(`/ResetPasswordPage?token=${resetToken}`);
  };

  /* ===================== RENDER ===================== */
  return (
    <div style={styles.page}>
      {/* AppBar */}
      <div style={styles.appbar}>
        <div style={styles.appbarContent}>
          <button style={styles.backButton} onClick={() => navigate('/login')}>
            <ArrowLeft />
          </button>
          <h1 style={styles.title}>Recuperar Contraseña</h1>
        </div>
      </div>

      {/* MODAL DEV */}
      {showDevDialog && (
        <div style={styles.modalOverlay}>
          <div style={styles.modal}>
            <h2 style={{ fontWeight: 700, marginBottom: '1rem' }}>
              <Code /> Modo Desarrollo
            </h2>
            <p style={{ marginBottom: '1.5rem' }}>
              En producción este enlace llegaría por correo.
            </p>
            <button style={styles.modalButton} onClick={handleGoToResetPassword}>
              <Key /> Ir a Restablecer Contraseña
            </button>
            <button style={styles.modalClose} onClick={() => setShowDevDialog(false)}>
              Cerrar
            </button>
          </div>
        </div>
      )}

      {/* CONTENIDO */}
      <div style={styles.content}>
        {!emailSent ? (
          <>
            <div style={styles.iconWrapper}>
              <Lock size={64} color="#c084fc" />
            </div>
            <h2 style={styles.heading}>¿Olvidaste tu contraseña?</h2>
            <p style={styles.description}>
              Ingresa tu correo y te enviaremos un enlace de recuperación.
            </p>

            <CustomTextField
              label="Correo electrónico"
              value={email}
              onChange={setEmail}
              icon={Mail}
            />

            <CustomButton
              text="ENVIAR ENLACE DE RECUPERACIÓN"
              onClick={handleForgotPassword}
              isLoading={isLoading}
            />
          </>
        ) : (
          <>
            <div style={styles.iconWrapper}>
              <CheckCircle size={64} color="#10b981" />
            </div>
            <h2 style={styles.heading}>Correo enviado</h2>
            <p style={styles.description}>
              Revisa tu correo para continuar con la recuperación.
            </p>
          </>
        )}
      </div>
    </div>
  );
};

export default ForgotPasswordPage;
