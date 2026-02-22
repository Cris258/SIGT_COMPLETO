import React from 'react';

const CustomButton = ({ text, isLoading, onClick, variant = 'primary' }) => {
  const isOutline = variant === 'outline';

  return (
    <button
      onClick={onClick}
      disabled={isLoading}
      style={{
        width: '100%',
        padding: '16px',
        backgroundColor: isOutline ? 'white' : '#d8b4fe',
        color: isOutline ? '#7e22ce' : '#000',
        fontWeight: 700,
        fontSize: '15px',
        borderRadius: '14px',
        border: isOutline ? '2px solid #d8b4fe' : 'none',
        cursor: 'pointer',
        opacity: isLoading ? 0.7 : 1,
        transition: 'all 0.2s ease',
      }}
    >
      {isLoading ? 'Enviando...' : text}
    </button>
  );
};

export default CustomButton;
