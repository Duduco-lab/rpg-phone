import { useCallback, useEffect, useRef, useState } from 'react';

const DURATION_MS = 2800;

export function useToast() {
  const [message, setMessage] = useState<string | null>(null);
  const timer = useRef<number | undefined>(undefined);

  const show = useCallback((text: string) => {
    window.clearTimeout(timer.current);
    setMessage(text);
    timer.current = window.setTimeout(() => setMessage(null), DURATION_MS);
  }, []);

  useEffect(() => () => window.clearTimeout(timer.current), []);
  return { message, show };
}

export function Toast({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <div className="mail-toast" role="status" key={message}>
      {message}
    </div>
  );
}
