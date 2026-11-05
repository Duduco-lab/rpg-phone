import { useEffect } from 'react';
import { useMailbox } from '../features/email/MailboxProvider';
import { snippet } from '../lib/format';
import { useSession } from '../session/SessionContext';
import { APPS } from './apps';
import { usePhone, type PhoneNotification } from './PhoneContext';

const AUTO_DISMISS_MS = 5500;

function Banner({ n }: { n: PhoneNotification }) {
  const { openApp, dismissNotification } = usePhone();
  const app = APPS[n.appId];
  const Icon = app.icon;

  useEffect(() => {
    const t = window.setTimeout(() => dismissNotification(n.id), AUTO_DISMISS_MS);
    return () => window.clearTimeout(t);
  }, [n.id, dismissNotification]);

  return (
    <button
      type="button"
      className="notif glass-strong"
      onClick={() => {
        dismissNotification(n.id);
        openApp(n.appId, n.intent ?? undefined);
      }}
    >
      <span className="notif-icon" style={{ background: app.background }}>
        <Icon size={16} color="#fff" />
      </span>
      <span className="notif-text">
        <span className="notif-meta">
          {app.name} <span>agora</span>
        </span>
        <strong>{n.title}</strong>
        <span className="notif-body">{n.body}</span>
      </span>
    </button>
  );
}

export function NotificationStack() {
  const { notifications } = usePhone();
  return (
    <div className="notif-stack" aria-live="polite">
      {notifications.map((n) => (
        <Banner key={n.id} n={n} />
      ))}
    </div>
  );
}

/** Converte e-mails recebidos em notificações do sistema. */
export function EmailNotifier() {
  const { onReceived } = useMailbox();
  const { notify } = usePhone();
  const { identityOf } = useSession();

  useEffect(
    () =>
      onReceived((message) => {
        notify({
          appId: 'email',
          title: identityOf(message.from).name,
          body: `${message.subject} — ${snippet(message.body, 70)}`,
          intent: { type: 'email.openThread', conversationId: message.conversationId },
        });
      }),
    [onReceived, notify, identityOf],
  );

  return null;
}
