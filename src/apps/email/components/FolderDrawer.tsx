import { Archive, File, Inbox, Send, Star, Trash2, type LucideIcon } from 'lucide-react';
import type { MailFolder } from '../../../domain/email';
import { FOLDER_LABELS } from '../../../features/email/mailboxQueries';
import { useMailbox } from '../../../features/email/MailboxProvider';
import { useSession } from '../../../session/SessionContext';

export const FOLDER_ICONS: Record<MailFolder, LucideIcon> = {
  inbox: Inbox,
  important: Star,
  sent: Send,
  drafts: File,
  archived: Archive,
  trash: Trash2,
};

const ORDER: MailFolder[] = ['inbox', 'important', 'sent', 'drafts', 'archived', 'trash'];

interface Props {
  open: boolean;
  current: MailFolder;
  onClose: () => void;
  onSelect: (folder: MailFolder) => void;
}

export function FolderDrawer({ open, current, onClose, onSelect }: Props) {
  const { counts } = useMailbox();
  const { activeCharacter } = useSession();
  const countFor = (f: MailFolder) =>
    f === 'inbox' ? counts.inbox : f === 'important' ? counts.important : f === 'drafts' ? counts.drafts : 0;

  return (
    <div className={`drawer-root ${open ? 'is-open' : ''}`} aria-hidden={!open}>
      <div className="drawer-scrim" onClick={onClose} />
      <nav className="drawer" aria-label="Pastas de e-mail">
        <div className="drawer-brand">
          <span className="drawer-logo">rpg</span>mail
        </div>
        {activeCharacter && <div className="drawer-account">{activeCharacter.email}</div>}
        <ul>
          {ORDER.map((f, i) => {
            const Icon = FOLDER_ICONS[f];
            const count = countFor(f);
            return (
              <li key={f} className={i === 2 ? 'drawer-sep' : undefined}>
                <button
                  type="button"
                  tabIndex={open ? 0 : -1}
                  className={`drawer-item ${current === f ? 'is-current' : ''}`}
                  onClick={() => onSelect(f)}
                >
                  <Icon size={20} />
                  <span>{FOLDER_LABELS[f]}</span>
                  {count > 0 && <span className="drawer-count">{count}</span>}
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </div>
  );
}
