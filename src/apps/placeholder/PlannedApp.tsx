import { Hammer } from 'lucide-react';
import type { AppDefinition } from '../../phone/apps';
import { usePhone } from '../../phone/PhoneContext';
import { AppHeader } from '../shared/AppHeader';
import '../shared/system-apps.css';

/**
 * Tela de apps ainda não implementados. Informa o que está planejado,
 * sem simular funcionalidades que não existem.
 */
export function PlannedApp({ app }: { app: AppDefinition }) {
  const { goHome } = usePhone();
  const Icon = app.icon;
  return (
    <div className="sys-app">
      <AppHeader title={app.name} onBack={goHome} />
      <div className="planned">
        <span className="planned-icon" style={{ background: app.background }}>
          <Icon size={44} color={app.id === 'calendar' ? '#e5304f' : '#fff'} strokeWidth={1.7} />
        </span>
        <h2>Em desenvolvimento</h2>
        <p>Este aplicativo será disponibilizado em uma próxima fase do RPG Phone.</p>
        {app.plannedFeatures && (
          <div className="sys-group planned-list">
            <div className="sys-group-title">
              <Hammer size={13} /> Planejado
            </div>
            <ul>
              {app.plannedFeatures.map((f) => (
                <li key={f}>{f}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
