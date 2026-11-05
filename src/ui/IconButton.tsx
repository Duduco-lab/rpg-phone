import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  children: ReactNode;
  active?: boolean;
}

/** Botão só com ícone — sempre com rótulo acessível e dica. */
export function IconButton({ label, children, active = false, className = '', type = 'button', ...rest }: Props) {
  return (
    <button
      type={type}
      aria-label={label}
      title={label}
      className={`icon-btn ${active ? 'is-active' : ''} ${className}`}
      {...rest}
    >
      {children}
    </button>
  );
}
