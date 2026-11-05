import { Signal, Wifi } from 'lucide-react';
import { useNow } from '../hooks/useNow';
import { formatClock } from '../lib/format';

/**
 * Barra de status. Horário real do dispositivo; sinal, Wi-Fi e bateria são
 * elementos de ambientação (o "aparelho" é fictício).
 */
export function StatusBar({ tone }: { tone: 'light' | 'dark' }) {
  const now = useNow();
  return (
    <div className={`status-bar tone-${tone}`}>
      <span className="status-time">{formatClock(now)}</span>
      <span className="status-icons" aria-hidden="true">
        <Signal size={15} strokeWidth={2.6} />
        <Wifi size={15} strokeWidth={2.6} />
        <span className="battery">
          <span className="battery-level" style={{ width: '78%' }} />
        </span>
      </span>
    </div>
  );
}
