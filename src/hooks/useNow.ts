import { useEffect, useState } from 'react';

/** Data/hora atual, atualizada a cada virada de minuto. */
export function useNow(): Date {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    let timer: number;
    const schedule = () => {
      const ms = 60_000 - (Date.now() % 60_000) + 50;
      timer = window.setTimeout(() => {
        setNow(new Date());
        schedule();
      }, ms);
    };
    schedule();
    return () => window.clearTimeout(timer);
  }, []);
  return now;
}
