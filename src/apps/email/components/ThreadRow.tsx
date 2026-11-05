import { Star } from 'lucide-react';
import type { EmailAddress, MailFolder } from '../../../domain/email';
import type { ThreadSummary } from '../../../features/email/mailboxQueries';
import { formatListDate, snippet } from '../../../lib/format';
import { useSession, type Identity } from '../../../session/SessionContext';
import { Avatar } from '../../../ui/Avatar';

interface Props {
  thread: ThreadSummary;
  owner: EmailAddress;
  folder: MailFolder;
  now: Date;
  onOpen: () => void;
  onToggleImportant: () => void;
}

/** Nomes exibidos na linha: remetentes da conversa ("eu" para o dono). */
function participantLabel(thread: ThreadSummary, owner: EmailAddress, folder: MailFolder, id: (a: string) => Identity) {
  const first = (a: EmailAddress) => (a === owner ? 'eu' : id(a).name.split(' ')[0] ?? a);
  const senders = [...new Set(thread.messages.map((m) => m.from))];
  if (folder === 'sent' && senders.length === 1 && senders[0] === owner) {
    const recipients = [...new Set(thread.messages.flatMap((m) => m.to))].filter((a) => a !== owner);
    return `Para: ${recipients.map((a) => id(a).name).join(', ') || 'eu'}`;
  }
  if (senders.length === 1) return senders[0] === owner ? 'eu' : id(senders[0]!).name;
  return senders.map(first).join(', ');
}

export function ThreadRow({ thread, owner, folder, now, onOpen, onToggleImportant }: Props) {
  const { identityOf } = useSession();
  const latest = thread.latest;
  const avatarAddress = latest.from !== owner ? latest.from : (thread.participants[0] ?? owner);
  const avatar = identityOf(avatarAddress);

  return (
    <li className={`thread-row ${thread.unread ? 'is-unread' : ''} ${thread.important ? 'is-important' : ''}`}>
      <button type="button" className="thread-row-main" onClick={onOpen}>
        <Avatar name={avatar.name} color={avatar.color} imageUrl={avatar.avatarUrl} size={40} />
        <span className="thread-row-text">
          <span className="thread-row-line">
            <span className="thread-row-from">
              {participantLabel(thread, owner, folder, identityOf)}
              {thread.count > 1 && <span className="thread-row-count">{thread.count}</span>}
            </span>
            <span className="thread-row-date">{formatListDate(latest.sentAt, now)}</span>
          </span>
          <span className="thread-row-subject">
            {thread.hasDraft && <span className="draft-tag">Rascunho</span>}
            {thread.subject}
          </span>
          <span className="thread-row-snippet">{snippet(latest.body, 90)}</span>
        </span>
      </button>
      <button
        type="button"
        className={`star-btn ${thread.important ? 'is-on' : ''}`}
        aria-label={thread.important ? 'Remover de Importantes' : 'Marcar como importante'}
        aria-pressed={thread.important}
        title={thread.important ? 'Remover de Importantes' : 'Marcar como importante'}
        onClick={onToggleImportant}
      >
        <Star size={19} />
      </button>
      {thread.unread && <span className="unread-dot" aria-label="Não lida" />}
    </li>
  );
}
