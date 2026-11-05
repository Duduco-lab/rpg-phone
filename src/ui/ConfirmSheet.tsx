import type { ReactNode } from 'react';

export interface SheetAction {
  label: string;
  onSelect: () => void;
  tone?: 'default' | 'danger' | 'primary';
}

interface Props {
  title: string;
  message?: ReactNode;
  actions: SheetAction[];
  onCancel: () => void;
  cancelLabel?: string;
}

/** Folha de ações modal no estilo mobile (ancorada na base da tela). */
export function ConfirmSheet({ title, message, actions, onCancel, cancelLabel = 'Cancelar' }: Props) {
  return (
    <div className="sheet-backdrop" onClick={onCancel} role="presentation">
      <div
        className="sheet"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sheet-head">
          <strong>{title}</strong>
          {message && <p>{message}</p>}
        </div>
        <div className="sheet-actions">
          {actions.map((a) => (
            <button key={a.label} type="button" className={`sheet-btn tone-${a.tone ?? 'default'}`} onClick={a.onSelect}>
              {a.label}
            </button>
          ))}
        </div>
        <button type="button" className="sheet-btn sheet-cancel" onClick={onCancel}>
          {cancelLabel}
        </button>
      </div>
    </div>
  );
}
