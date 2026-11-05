import { ChevronLeft } from 'lucide-react';
import type { ReactNode } from 'react';

interface Props {
  title: string;
  onBack: () => void;
  backLabel?: string;
  right?: ReactNode;
}

/** Cabeçalho padrão dos apps do sistema (estilo "título grande"). */
export function AppHeader({ title, onBack, backLabel = 'Início', right }: Props) {
  return (
    <header className="sys-header">
      <div className="sys-header-bar">
        <button type="button" className="sys-back" onClick={onBack}>
          <ChevronLeft size={22} />
          {backLabel}
        </button>
        {right}
      </div>
      <h1 className="sys-title">{title}</h1>
    </header>
  );
}
