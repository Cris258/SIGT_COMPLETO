import React from 'react';
import { Mail } from 'lucide-react';

const CustomTextField = ({
  label,
  icon: Icon = Mail,
  error,
  value,
  onChange,
  placeholder,
  type = 'text',
}) => {
  return (
    <div style={{ width: '100%' }}>
      {/* Label */}
      <label
        style={{
          display: 'block',
          marginBottom: '0.5rem',
          fontWeight: 600,
          color: '#374151',
        }}
      >
        {label}
      </label>

      {/* Input with icon */}
      <div style={{ position: 'relative' }}>
        <Icon
          size={18}
          style={{
            position: 'absolute',
            left: '14px',
            top: '50%',
            transform: 'translateY(-50%)',
            color: '#c084fc',
          }}
        />

        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          style={{
            width: '100%',
            padding: '14px 14px 14px 44px',
            borderRadius: '12px',
            border: error ? '2px solid #ef4444' : '1px solid #d1d5db',
            fontSize: '15px',
            outline: 'none',
            transition: 'border-color 0.2s ease',
          }}
        />
      </div>

      {/* Error */}
      {error && (
        <span
          style={{
            color: '#ef4444',
            fontSize: '0.875rem',
            marginTop: '0.25rem',
            display: 'block',
          }}
        >
          {error}
        </span>
      )}
    </div>
  );
};

export default CustomTextField;
