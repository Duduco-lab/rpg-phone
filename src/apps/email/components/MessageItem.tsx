import { ChevronDown, Forward, Reply, ReplyAll } from 'lucide-react';
import { useState } from 'react';
import type { EmailAddress, EmailMessage } from '../../../domain/email';
import { formatFullDate, formatListDate, snippet } from '../../../lib/format';
import { useSession } from '../../../session/SessionContext';
import { Avatar } from '../../../ui/Avatar';
import { IconButton } from '../../../ui/IconButton';

interface Props {
  message: EmailMessage;
  owner: EmailAddress;
  expanded: boolean;
  unread: boolean;
  now: Date;
  onToggle: () => void;
  onReply: (all: boolean) => void;
  onForward: () => void;
}

export function MessageItem({ message, owner, expanded, unread, now, onToggle, onReply, onForward }: Props) {
  const { identityOf } = useSession();
  const [details, setDetails] = useState(false);
  const sender = identityOf(message.from);
  const others = new Set([message.from, ...message.to]);
  others.delete(owner);
  const canReplyAll = others.size > 1;

  const recipientSummary = message.to
    .map((a) => (a === owner ? 'mim' : identityOf(a).name.split(' ')[0]))
    .join(', ');

  if (!expanded) {
    return (
      <article className={`msg msg--collapsed ${unread ? 'is-unread' : ''}`}>
        <button type="button" className="msg-collapsed-btn" onClick={onToggle}>
          <Avatar name={sender.name} color={sender.color} imageUrl={sender.avatarUrl} size={36} />
          <span className="msg-collapsed-text">
            <span className="msg-line">
              <strong>{message.from === owner ? 'Eu' : sender.name}</strong>
              <span className="msg-date">{formatListDate(message.sentAt, now)}</span>
            </span>
            <span className="msg-snippet">{snippet(message.body, 70)}</span>
          </span>
        </button>
      </article>
    );
  }

  return (
    <article className="msg msg--expanded">
      <div className="msg-head">
        <button type="button" className="msg-head-btn" onClick={onToggle} aria-label="Recolher mensagem">
          <Avatar name={sender.name} color={sender.color} imageUrl={sender.avatarUrl} size={40} />
        </button>
        <div className="msg-head-text">
          <div className="msg-line">
            <strong>{message.from === owner ? 'Eu' : sender.name}</strong>
            <span className="msg-date">{formatListDate(message.sentAt, now)}</span>
          </div>
          <button
            type="button"
            className="msg-to-toggle"
            aria-expanded={details}
            onClick={() => setDetails((d) => !d)}
          >
            para {recipientSummary}
            <ChevronDown size={14} className={details ? 'rot' : ''} />
          </button>
        </div>
        <div className="msg-head-actions">
          <IconButton label="Responder" onClick={() => onReply(false)}>
            <Reply size={18} />
          </IconButton>
        </div>
      </div>

      {details && (
        <dl className="msg-details">
          <dt>De</dt>
          <dd>
            {sender.name} <span>&lt;{message.from}&gt;</span>
          </dd>
          <dt>Para</dt>
          <dd>
            {message.to.map((a) => (
              <span key={a} className="msg-details-addr">
                {identityOf(a).name} <span>&lt;{a}&gt;</span>
              </span>
            ))}
          </dd>
          <dt>Data</dt>
          <dd>{formatFullDate(message.sentAt)}</dd>
          <dt>Assunto</dt>
          <dd>{message.subject}</dd>
        </dl>
      )}

      <div className="msg-body">{message.body}</div>

      <div className="msg-actions">
        <button type="button" className="pill-btn" onClick={() => onReply(false)}>
          <Reply size={16} /> Responder
        </button>
        {canReplyAll && (
          <button type="button" className="pill-btn" onClick={() => onReply(true)}>
            <ReplyAll size={16} /> Resp. a todos
          </button>
        )}
        <button type="button" className="pill-btn" onClick={onForward}>
          <Forward size={16} /> Encaminhar
        </button>
      </div>
    </article>
  );
}
