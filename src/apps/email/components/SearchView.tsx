import { ArrowLeft, Search, X } from 'lucide-react';
import { useDeferredValue, useMemo, useState } from 'react';
import type { ConversationId } from '../../../domain/email';
import {
  SEARCH_SCOPE_LABELS,
  searchThreads,
  type SearchScope,
} from '../../../features/email/mailboxQueries';
import { useMailbox } from '../../../features/email/MailboxProvider';
import { useMailActions } from '../../../features/email/useMailActions';
import { useNow } from '../../../hooks/useNow';
import { useSession } from '../../../session/SessionContext';
import { IconButton } from '../../../ui/IconButton';
import { ThreadRow } from './ThreadRow';

const SCOPES = Object.keys(SEARCH_SCOPE_LABELS) as SearchScope[];

interface Props {
  onBack: () => void;
  onOpenThread: (id: ConversationId) => void;
}

export function SearchView({ onBack, onOpenThread }: Props) {
  const { snapshot } = useMailbox();
  const { identityOf } = useSession();
  const actions = useMailActions(() => undefined);
  const now = useNow();
  const [query, setQuery] = useState('');
  const [scope, setScope] = useState<SearchScope>('all');
  const deferred = useDeferredValue(query);

  const results = useMemo(
    () => (snapshot ? searchThreads(snapshot, deferred, scope, (a) => identityOf(a).name) : []),
    [snapshot, deferred, scope, identityOf],
  );
  if (!snapshot) return null;

  return (
    <div className="search-view">
      <header className="mail-toolbar search-toolbar">
        <IconButton label="Voltar" onClick={onBack}>
          <ArrowLeft size={22} />
        </IconButton>
        <input
          className="search-input"
          type="search"
          placeholder="Pesquisar no e-mail"
          aria-label="Pesquisar no e-mail"
          autoFocus
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {query && (
          <IconButton label="Limpar pesquisa" onClick={() => setQuery('')}>
            <X size={20} />
          </IconButton>
        )}
      </header>

      <div className="scope-chips" role="radiogroup" aria-label="Pesquisar em">
        {SCOPES.map((s) => (
          <button
            key={s}
            type="button"
            role="radio"
            aria-checked={scope === s}
            className={`scope-chip ${scope === s ? 'is-on' : ''}`}
            onClick={() => setScope(s)}
          >
            {SEARCH_SCOPE_LABELS[s]}
          </button>
        ))}
      </div>

      <div className="mail-scroll">
        {!deferred.trim() ? (
          <div className="mail-empty">
            <Search size={38} strokeWidth={1.4} />
            <p>Pesquise por remetente, destinatário, assunto ou conteúdo.</p>
          </div>
        ) : results.length === 0 ? (
          <div className="mail-empty">
            <p>Nenhum resultado para “{deferred}”.</p>
          </div>
        ) : (
          <>
            <div className="folder-title">
              {results.length} conversa{results.length > 1 ? 's' : ''}
            </div>
            <ul className="thread-list">
              {results.map((t) => (
                <ThreadRow
                  key={t.conversationId}
                  thread={t}
                  owner={snapshot.ownerAddress}
                  folder="inbox"
                  now={now}
                  onOpen={() => onOpenThread(t.conversationId)}
                  onToggleImportant={() => void actions.setImportant(t.conversationId, !t.important)}
                />
              ))}
            </ul>
          </>
        )}
      </div>
    </div>
  );
}
