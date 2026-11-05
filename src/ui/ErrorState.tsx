import { AlertTriangle } from 'lucide-react';

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="centered-state error-state" role="alert">
      <AlertTriangle size={32} />
      <p>{message}</p>
      {onRetry && (
        <button type="button" className="text-btn" onClick={onRetry}>
          Tentar novamente
        </button>
      )}
    </div>
  );
}
