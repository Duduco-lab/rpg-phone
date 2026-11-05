import { Mail } from 'lucide-react';
import { useMemo } from 'react';
import { threadsForFolder } from '../features/email/mailboxQueries';
import { useMailbox } from '../features/email/MailboxProvider';
import { useNow } from '../hooks/useNow';
import { formatClock, formatListDate, formatLongDate } from '../lib/format';
import { useSession } from '../session/SessionContext';
import { AppIcon } from './AppIcon';
import { APPS, DOCK, HOME_GRID } from './apps';
import { usePhone } from './PhoneContext';

function EmailWidget() {
  const { snapshot, counts, status } = useMailbox();
  const { identityOf } = useSession();
  const { openApp } = usePhone();
  const now = useNow();

  const latestUnread = useMemo(
    () => (snapshot ? threadsForFolder(snapshot, 'inbox').find((t) => t.unread) ?? null : null),
    [snapshot],
  );

  return (
    <button
      type="button"
      className="widget glass email-widget"
      onClick={() =>
        openApp(
          'email',
          latestUnread ? { type: 'email.openThread', conversationId: latestUnread.conversationId } : undefined,
        )
      }
    >
      <span className="widget-head">
        <span className="widget-app-dot" style={{ background: APPS.email.background }}>
          <Mail size={12} color="#fff" />
        </span>
        E-mail
        <span className="widget-count">
          {status === 'loading' ? '…' : counts.inbox === 0 ? 'Tudo lido' : `${counts.inbox} não lida${counts.inbox > 1 ? 's' : ''}`}
        </span>
      </span>
      {latestUnread ? (
        <span className="widget-body">
          <span className="widget-row">
            <strong>{identityOf(latestUnread.latest.from).name}</strong>
            <span className="widget-time">{formatListDate(latestUnread.latest.sentAt, now)}</span>
          </span>
          <span className="widget-subject">{latestUnread.subject}</span>
        </span>
      ) : (
        <span className="widget-body widget-empty">Nenhuma mensagem nova.</span>
      )}
    </button>
  );
}

export function HomeScreen() {
  const now = useNow();
  const { openApp } = usePhone();
  const { counts } = useMailbox();
  const badgeFor = (id: string) => (id === 'email' ? counts.inbox : 0);

  return (
    <div className="home">
      <div className="home-clock">
        <span className="home-time">{formatClock(now)}</span>
        <span className="home-date">{formatLongDate(now)}</span>
      </div>

      <EmailWidget />

      <div className="home-grid">
        {HOME_GRID.map((id) => (
          <AppIcon key={id} app={APPS[id]} badge={badgeFor(id)} onOpen={() => openApp(id)} />
        ))}
      </div>

      <nav className="dock glass" aria-label="Aplicativos fixos">
        {DOCK.map((id) => (
          <AppIcon key={id} app={APPS[id]} badge={badgeFor(id)} showLabel={false} onOpen={() => openApp(id)} />
        ))}
      </nav>
    </div>
  );
}
