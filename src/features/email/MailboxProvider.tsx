import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import type { EmailMessage, MailboxSnapshot } from '../../domain/email';
import { errorMessage, type MailboxClient } from '../../services/backend';
import { folderCounts, type FolderCounts } from './mailboxQueries';

type ReceivedListener = (message: EmailMessage) => void;

interface MailboxValue {
  client: MailboxClient;
  snapshot: MailboxSnapshot | null;
  status: 'loading' | 'ready' | 'error';
  error: string | null;
  counts: FolderCounts;
  reload: () => Promise<MailboxSnapshot | null>;
  /** Avisado quando chega um novo e-mail (usado pelas notificações do telefone). */
  onReceived: (listener: ReceivedListener) => () => void;
}

const MailboxContext = createContext<MailboxValue | null>(null);

const EMPTY_COUNTS: FolderCounts = { inbox: 0, important: 0, drafts: 0 };

/**
 * Mantém a caixa postal do personagem ativo sincronizada.
 * Compartilhada pelo app de E-mail, widgets e notificações da tela inicial.
 */
export function MailboxProvider({ client, children }: { client: MailboxClient; children: ReactNode }) {
  const [snapshot, setSnapshot] = useState<MailboxSnapshot | null>(null);
  const [status, setStatus] = useState<MailboxValue['status']>('loading');
  const [error, setError] = useState<string | null>(null);
  const receivedListeners = useRef(new Set<ReceivedListener>());
  const requestSeq = useRef(0);

  const reload = useCallback(async (): Promise<MailboxSnapshot | null> => {
    const seq = ++requestSeq.current;
    try {
      const data = await client.load();
      if (seq !== requestSeq.current) return null; // resposta antiga
      setSnapshot(data);
      setStatus('ready');
      setError(null);
      return data;
    } catch (e) {
      if (seq !== requestSeq.current) return null;
      setError(errorMessage(e));
      setStatus('error');
      return null;
    }
  }, [client]);

  useEffect(() => {
    void reload();
    const notified = new Set<string>();
    return client.subscribe(async (event) => {
      const data = await reload();
      if (event.type !== 'received' || notified.has(event.messageId)) return;
      const message = data?.messages.find((m) => m.id === event.messageId);
      if (!message) return;
      notified.add(event.messageId);
      receivedListeners.current.forEach((l) => l(message));
    });
  }, [client, reload]);

  const onReceived = useCallback((listener: ReceivedListener) => {
    receivedListeners.current.add(listener);
    return () => {
      receivedListeners.current.delete(listener);
    };
  }, []);

  const counts = useMemo(() => (snapshot ? folderCounts(snapshot) : EMPTY_COUNTS), [snapshot]);

  const value = useMemo<MailboxValue>(
    () => ({ client, snapshot, status, error, counts, reload, onReceived }),
    [client, snapshot, status, error, counts, reload, onReceived],
  );

  return <MailboxContext.Provider value={value}>{children}</MailboxContext.Provider>;
}

export function useMailbox(): MailboxValue {
  const ctx = useContext(MailboxContext);
  if (!ctx) throw new Error('useMailbox deve ser usado dentro de <MailboxProvider>.');
  return ctx;
}
