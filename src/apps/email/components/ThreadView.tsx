import { Archive, ArchiveRestore, ArrowLeft, Mail, RotateCcw, Star, Trash2 } from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import type { ConversationId, EmailMessage } from '../../../domain/email';
import { composeForward, type ComposeInit } from '../../../features/email/compose';
import { conversationLocation, findThread, FOLDER_LABELS } from '../../../features/email/mailboxQueries';
import { useMailbox } from '../../../features/email/MailboxProvider';
import { useMailActions } from '../../../features/email/useMailActions';
import { useNow } from '../../../hooks/useNow';
import { useSession } from '../../../session/SessionContext';
import { ConfirmSheet } from '../../../ui/ConfirmSheet';
import { IconButton } from '../../../ui/IconButton';
import { MessageItem } from './MessageItem';

interface Props {
  conversationId: ConversationId;
  inTrash: boolean;
  onBack: () => void;
  onCompose: (init: ComposeInit) => void;
  onReply: (message: EmailMessage, all: boolean) => void;
  toast: (message: string) => void;
}

export function ThreadView({ conversationId, inTrash, onBack, onCompose, onReply, toast }: Props) {
  const { snapshot } = useMailbox();
  const { identityOf } = useSession();
  const actions = useMailActions(toast);
  const now = useNow();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const thread = useMemo(
    () => (snapshot ? findThread(snapshot, conversationId, inTrash) : null),
    [snapshot, conversationId, inTrash],
  );
  const location = snapshot ? conversationLocation(snapshot, conversationId) : 'inbox';

  // Expande a última mensagem e as não lidas no momento em que a conversa é aberta.
  const [expanded, setExpanded] = useState<Set<string>>(() => {
    const set = new Set<string>();
    if (thread && snapshot) {
      set.add(thread.latest.id);
      thread.messages.forEach((m) => {
        if (m.from !== snapshot.ownerAddress && !snapshot.entries[m.id]?.isRead) set.add(m.id);
      });
    }
    return set;
  });

  // Ao abrir, marca a conversa como lida (uma única vez).
  const markedRead = useRef(false);
  useEffect(() => {
    if (thread?.unread && !markedRead.current) {
      markedRead.current = true;
      void actions.markRead(conversationId);
    }
  }, [thread?.unread, conversationId, actions]);

  // Novas mensagens que chegam com a conversa aberta aparecem expandidas.
  const latestId = thread?.latest.id;
  useEffect(() => {
    if (latestId) setExpanded((s) => (s.has(latestId) ? s : new Set(s).add(latestId)));
  }, [latestId]);

  if (!snapshot) return null;
  if (!thread) {
    return (
      <div className="thread">
        <header className="mail-toolbar">
          <IconButton label="Voltar" onClick={onBack}>
            <ArrowLeft size={22} />
          </IconButton>
        </header>
        <div className="mail-empty">
          <p>Esta conversa não está mais disponível.</p>
        </div>
      </div>
    );
  }

  const leaveAfter = (ok: boolean) => {
    if (ok) onBack();
  };

  const toggle = (id: string) =>
    setExpanded((s) => {
      const next = new Set(s);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const nameOf = (a: string) => identityOf(a).name;

  return (
    <div className="thread">
      <header className="mail-toolbar">
        <IconButton label="Voltar" onClick={onBack}>
          <ArrowLeft size={22} />
        </IconButton>
        <div className="mail-toolbar-actions">
          {inTrash ? (
            <>
              <IconButton
                label="Restaurar"
                disabled={actions.busy}
                onClick={async () => leaveAfter(await actions.restore(conversationId))}
              >
                <RotateCcw size={20} />
              </IconButton>
              <IconButton label="Excluir para sempre" disabled={actions.busy} onClick={() => setConfirmDelete(true)}>
                <Trash2 size={20} />
              </IconButton>
            </>
          ) : (
            <>
              {location === 'archived' ? (
                <IconButton
                  label="Mover para a Caixa de entrada"
                  disabled={actions.busy}
                  onClick={async () => leaveAfter(await actions.unarchive(conversationId))}
                >
                  <ArchiveRestore size={20} />
                </IconButton>
              ) : (
                <IconButton
                  label="Arquivar"
                  disabled={actions.busy}
                  onClick={async () => leaveAfter(await actions.archive(conversationId))}
                >
                  <Archive size={20} />
                </IconButton>
              )}
              <IconButton
                label="Excluir"
                disabled={actions.busy}
                onClick={async () => leaveAfter(await actions.trash(conversationId))}
              >
                <Trash2 size={20} />
              </IconButton>
              <IconButton
                label="Marcar como não lida"
                disabled={actions.busy}
                onClick={async () => leaveAfter(await actions.markUnread(conversationId))}
              >
                <Mail size={20} />
              </IconButton>
            </>
          )}
        </div>
      </header>

      <div className="mail-scroll thread-scroll">
        <div className="thread-subject">
          <h1>{thread.subject}</h1>
          <button
            type="button"
            className={`star-btn ${thread.important ? 'is-on' : ''}`}
            aria-pressed={thread.important}
            aria-label={thread.important ? 'Remover de Importantes' : 'Marcar como importante'}
            title={thread.important ? 'Remover de Importantes' : 'Marcar como importante'}
            onClick={() => void actions.setImportant(conversationId, !thread.important)}
          >
            <Star size={22} />
          </button>
        </div>
        <div className="thread-labels">
          <span className="label-chip">{FOLDER_LABELS[inTrash ? 'trash' : location]}</span>
          {thread.important && <span className="label-chip label-chip--important">Importante</span>}
        </div>

        <div className="thread-messages">
          {thread.messages.map((m) => (
            <MessageItem
              key={m.id}
              message={m}
              owner={snapshot.ownerAddress}
              expanded={expanded.has(m.id)}
              unread={m.from !== snapshot.ownerAddress && !snapshot.entries[m.id]?.isRead}
              now={now}
              onToggle={() => toggle(m.id)}
              onReply={(all) => onReply(m, all)}
              onForward={() => onCompose(composeForward(m, nameOf))}
            />
          ))}
        </div>
      </div>

      {confirmDelete && (
        <ConfirmSheet
          title="Excluir para sempre?"
          message="A conversa será removida definitivamente da sua caixa. Os outros participantes mantêm as cópias deles."
          onCancel={() => setConfirmDelete(false)}
          actions={[
            {
              label: 'Excluir para sempre',
              tone: 'danger',
              onSelect: async () => {
                setConfirmDelete(false);
                leaveAfter(await actions.deleteForever(conversationId));
              },
            },
          ]}
        />
      )}
    </div>
  );
}
