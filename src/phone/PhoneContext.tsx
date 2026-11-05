import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';
import type { ConversationId, EmailAddress } from '../domain/email';
import type { AppId } from './apps';

/** Pedidos que um app (ou notificação) pode fazer ao abrir outro app. */
export type AppIntent =
  | { type: 'email.compose'; to: EmailAddress[] }
  | { type: 'email.openThread'; conversationId: ConversationId };

export interface PhoneNotification {
  id: number;
  appId: AppId;
  title: string;
  body: string;
  intent: AppIntent | null;
}

interface PhoneNavValue {
  currentApp: AppId | null;
  pendingIntent: { key: number; intent: AppIntent } | null;
  openApp: (id: AppId, intent?: AppIntent) => void;
  goHome: () => void;
  consumeIntent: (key: number) => void;
  notifications: PhoneNotification[];
  notify: (n: Omit<PhoneNotification, 'id'>) => void;
  dismissNotification: (id: number) => void;
}

const PhoneContext = createContext<PhoneNavValue | null>(null);

export function PhoneProvider({ children }: { children: ReactNode }) {
  const [currentApp, setCurrentApp] = useState<AppId | null>(null);
  const [pendingIntent, setPendingIntent] = useState<PhoneNavValue['pendingIntent']>(null);
  const [notifications, setNotifications] = useState<PhoneNotification[]>([]);
  const seq = useRef(0);

  const openApp = useCallback((id: AppId, intent?: AppIntent) => {
    setCurrentApp(id);
    if (intent) setPendingIntent({ key: ++seq.current, intent });
  }, []);

  const goHome = useCallback(() => setCurrentApp(null), []);

  const consumeIntent = useCallback((key: number) => {
    setPendingIntent((p) => (p && p.key === key ? null : p));
  }, []);

  const dismissNotification = useCallback((id: number) => {
    setNotifications((list) => list.filter((n) => n.id !== id));
  }, []);

  const notify = useCallback((n: Omit<PhoneNotification, 'id'>) => {
    const id = ++seq.current;
    // Mantém no máximo 3 banners empilhados.
    setNotifications((list) => [...list.slice(-2), { ...n, id }]);
  }, []);

  const value = useMemo<PhoneNavValue>(
    () => ({
      currentApp,
      pendingIntent,
      openApp,
      goHome,
      consumeIntent,
      notifications,
      notify,
      dismissNotification,
    }),
    [currentApp, pendingIntent, openApp, goHome, consumeIntent, notifications, notify, dismissNotification],
  );

  return <PhoneContext.Provider value={value}>{children}</PhoneContext.Provider>;
}

export function usePhone(): PhoneNavValue {
  const ctx = useContext(PhoneContext);
  if (!ctx) throw new Error('usePhone deve ser usado dentro de <PhoneProvider>.');
  return ctx;
}
