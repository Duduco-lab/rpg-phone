import { ArrowLeft, Menu, Pencil, Search } from 'lucide-react';
import { useMemo } from 'react';
import type { ConversationId, MailFolder } from '../../../domain/email';
import { composeFromDraft, newCompose, type ComposeInit } from '../../../features/email/compose';
import { FOLDER_LABELS, threadsForFolder } from '../../../features/email/mailboxQueries';
import { useMailbox } from '../../../features/email/MailboxProvider';
import { useMailActions } from '../../../features/email/useMailActions';
import { useNow } from '../../../hooks/useNow';
import { formatListDate, snippet } from '../../../lib/format';
import { useSession } from '../../../session/SessionContext';
import { Avatar } from '../../../ui/Avatar';
import { IconButton } from '../../../ui/IconButton';
import { FOLDER_ICONS } from './FolderDrawer';
import { ThreadRow } from './ThreadRow';

interface Props {
  folder: MailFolder;
  onMenu: () => void;
  onSearch: () => void;
  onOpenThread: (id: ConversationId, inTrash?: boolean) => void;
  onCompose: (init: ComposeInit) => void;
  onExit: () => void;
  toast: (message: string) => void;
}

const EMPTY_TEXT: Record<MailFolder, string> = {
  inbox: 'Nada na caixa de entrada.',
  important: 'Nenhuma conversa marcada como importante.',
  sent: 'Você ainda não enviou nenhum e-mail.',
  drafts: 'Nenhum rascunho salvo.',
  archived: 'Nenhuma conversa arquivada.',
  trash: 'A lixeira está vazia.',
};

export function MailboxView({ folder, onMenu, onSearch, onOpenThread, onCompose, onExit, toast }: Props) {
  const { snapshot } = useMailbox();
  const { activeCharacter, identityOf } = useSession();
  const actions = useMailActions(toast);
  const now = useNow();

  const threads = useMemo(() => (snapshot ? threadsForFolder(snapshot, folder) : []), [snapshot, folder]);
  const drafts = useMemo(
    () => [...(snapshot?.drafts ?? [])].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)),
    [snapshot],
  );
  if (!snapshot) return null;

  const FolderIcon = FOLDER_ICONS[folder];
  const isEmpty = folder === 'drafts' ? drafts.length === 0 : threads.length === 0;

  return (
    <div className="mailbox">
      <header className="mail-search-bar">
        <IconButton label="Sair do e-mail" onClick={onExit} className="mail-exit">
          <ArrowLeft size={20} />
        </IconButton>
        <div className="search-pill">
          <IconButton label="Abrir pastas" onClick={onMenu}>
            <Menu size={20} />
          </IconButton>
          <button type="button" className="search-pill-input" onClick={onSearch}>
            <Search size={16} />
            Pesquisar no e-mail
          </button>
          {activeCharacter && (
            <Avatar
              name={identityOf(activeCharacter.email).name}
              color={activeCharacter.avatarColor}
              imageUrl={activeCharacter.avatarUrl}
              size={30}
            />
          )}
        </div>
      </header>

      <div className="mail-scroll">
        <div className="folder-title">
          <FolderIcon size={14} />
          {FOLDER_LABELS[folder]}
        </div>

        {isEmpty && (
          <div className="mail-empty">
            <FolderIcon size={40} strokeWidth={1.4} />
            <p>{EMPTY_TEXT[folder]}</p>
          </div>
        )}

        {folder === 'drafts' ? (
          <ul className="thread-list">
            {drafts.map((d) => (
              <li key={d.id} className="thread-row">
                <button type="button" className="thread-row-main" onClick={() => onCompose(composeFromDraft(d))}>
                  <span className="draft-avatar">
                    <Pencil size={18} />
                  </span>
                  <span className="thread-row-text">
                    <span className="thread-row-line">
                      <span className="thread-row-from">
                        <span className="draft-tag">Rascunho</span>
                        {d.to.length ? d.to.map((a) => identityOf(a).name).join(', ') : '(sem destinatário)'}
                      </span>
                      <span className="thread-row-date">{formatListDate(d.updatedAt, now)}</span>
                    </span>
                    <span className="thread-row-subject">{d.subject || '(sem assunto)'}</span>
                    <span className="thread-row-snippet">{snippet(d.body, 90) || ' '}</span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        ) : (
          <ul className="thread-list">
            {threads.map((t) => (
              <ThreadRow
                key={t.conversationId}
                thread={t}
                owner={snapshot.ownerAddress}
                folder={folder}
                now={now}
                onOpen={() => onOpenThread(t.conversationId, folder === 'trash')}
                onToggleImportant={() => void actions.setImportant(t.conversationId, !t.important)}
              />
            ))}
          </ul>
        )}
      </div>

      <button type="button" className="compose-fab" onClick={() => onCompose(newCompose())}>
        <Pencil size={20} />
        Escrever
      </button>
    </div>
  );
}
