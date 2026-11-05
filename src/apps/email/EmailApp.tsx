import { useCallback, useEffect, useRef, useState } from 'react';
import type { ConversationId, MailFolder } from '../../domain/email';
import { composeReply, newCompose, type ComposeInit } from '../../features/email/compose';
import { useMailbox } from '../../features/email/MailboxProvider';
import { usePhone } from '../../phone/PhoneContext';
import { CenteredSpinner } from '../../ui/Spinner';
import { ErrorState } from '../../ui/ErrorState';
import { ComposeView } from './components/ComposeView';
import { FolderDrawer } from './components/FolderDrawer';
import { MailboxView } from './components/MailboxView';
import { SearchView } from './components/SearchView';
import { ThreadView } from './components/ThreadView';
import { Toast, useToast } from './components/Toast';
import './email.css';

type Route =
  | { name: 'mailbox' }
  | { name: 'thread'; conversationId: ConversationId; inTrash: boolean }
  | { name: 'compose'; init: ComposeInit }
  | { name: 'search' };

export function EmailApp() {
  const { status, error, reload, snapshot } = useMailbox();
  const { pendingIntent, consumeIntent, goHome } = usePhone();
  const [folder, setFolder] = useState<MailFolder>('inbox');
  const [stack, setStack] = useState<Route[]>([{ name: 'mailbox' }]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const toast = useToast();

  const push = useCallback((r: Route) => setStack((s) => [...s, r]), []);
  const pop = useCallback(() => {
    setStack((s) => (s.length > 1 ? s.slice(0, -1) : s));
  }, []);

  // Pedidos vindos de outros apps ou de notificações (cada um tratado uma única vez).
  const handledIntent = useRef<number | null>(null);
  useEffect(() => {
    if (!pendingIntent || handledIntent.current === pendingIntent.key) return;
    const { key, intent } = pendingIntent;
    handledIntent.current = key;
    if (intent.type === 'email.compose') push({ name: 'compose', init: newCompose(intent.to) });
    if (intent.type === 'email.openThread') {
      setStack([{ name: 'mailbox' }, { name: 'thread', conversationId: intent.conversationId, inTrash: false }]);
    }
    consumeIntent(key);
  }, [pendingIntent, consumeIntent, push]);

  if (status === 'loading' && !snapshot) return <div className="mail-app"><CenteredSpinner label="Carregando e-mails" /></div>;
  if (!snapshot) {
    return (
      <div className="mail-app">
        <ErrorState message={error ?? 'Não foi possível carregar a caixa de e-mail.'} onRetry={() => void reload()} />
      </div>
    );
  }

  const route = stack[stack.length - 1]!;
  const openThread = (conversationId: ConversationId, inTrash = false) =>
    push({ name: 'thread', conversationId, inTrash });
  const openCompose = (init: ComposeInit) => push({ name: 'compose', init });

  return (
    <div className="mail-app">
      {/* A lista permanece montada por baixo para preservar a rolagem. */}
      <div className="mail-layer" hidden={route.name !== 'mailbox'}>
        <MailboxView
          folder={folder}
          onMenu={() => setDrawerOpen(true)}
          onSearch={() => push({ name: 'search' })}
          onOpenThread={openThread}
          onCompose={openCompose}
          onExit={goHome}
          toast={toast.show}
        />
      </div>

      {route.name === 'thread' && (
        <div className="mail-layer mail-layer--push" key={`t-${route.conversationId}`}>
          <ThreadView
            conversationId={route.conversationId}
            inTrash={route.inTrash}
            onBack={pop}
            onCompose={openCompose}
            onReply={(m, all) => openCompose(composeReply(m, snapshot.ownerAddress, all))}
            toast={toast.show}
          />
        </div>
      )}

      {route.name === 'search' && (
        <div className="mail-layer mail-layer--push">
          <SearchView onBack={pop} onOpenThread={(id) => openThread(id)} />
        </div>
      )}

      {route.name === 'compose' && (
        <div className="mail-layer mail-layer--up" key={`c-${stack.length}`}>
          <ComposeView
            init={route.init}
            onClose={(message) => {
              pop();
              if (message) toast.show(message);
            }}
          />
        </div>
      )}

      <FolderDrawer
        open={drawerOpen}
        current={folder}
        onClose={() => setDrawerOpen(false)}
        onSelect={(f) => {
          setFolder(f);
          setStack([{ name: 'mailbox' }]);
          setDrawerOpen(false);
        }}
      />

      <Toast message={toast.message} />
    </div>
  );
}
