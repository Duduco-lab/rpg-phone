import { ChevronLeft, Mail, Phone as PhoneIcon, Search } from 'lucide-react';
import { useMemo, useState } from 'react';
import { fullName, type CharacterProfile } from '../../domain/character';
import { usePhone } from '../../phone/PhoneContext';
import { useSession } from '../../session/SessionContext';
import { Avatar } from '../../ui/Avatar';
import { CenteredSpinner } from '../../ui/Spinner';
import { ErrorState } from '../../ui/ErrorState';
import { AppHeader } from '../shared/AppHeader';
import { CircleEditor } from '../../circle/CircleEditor';
import '../shared/system-apps.css';

const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

function ContactDetail({ c, onBack }: { c: CharacterProfile; onBack: () => void }) {
  const { openApp } = usePhone();
  return (
    <div className="sys-app contact-detail">
      <div className="sys-header-bar contact-detail-bar">
        <button type="button" className="sys-back" onClick={onBack}>
          <ChevronLeft size={22} />
          Contatos
        </button>
      </div>
      <div className="contact-hero">
        <Avatar name={fullName(c)} color={c.avatarColor} imageUrl={c.avatarUrl} size={96} />
        <h2>{fullName(c)}</h2>
        <div className="contact-quick">
          <button type="button" onClick={() => openApp('email', { type: 'email.compose', to: [c.email] })}>
            <Mail size={20} />
            E-mail
          </button>
        </div>
      </div>
      <div className="sys-group">
        <div className="sys-cell sys-cell--stack">
          <small>e-mail</small>
          <span className="link-text">{c.email}</span>
        </div>
        <div className="sys-cell sys-cell--stack">
          <small>telefone</small>
          <span>
            <PhoneIcon size={13} /> {c.phoneNumber}
          </span>
        </div>
      </div>
      {c.description && (
        <div className="sys-group">
          <div className="sys-cell sys-cell--stack">
            <small>sobre</small>
            <span className="contact-desc">{c.description}</span>
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * Contatos: o círculo social do personagem (com Supabase) e o diretório de
 * todos os personagens cadastrados no RPG Phone.
 */
export function ContactsApp() {
  const { goHome } = usePhone();
  const { backend, characters, activeCharacter, status, error, reload } = useSession();
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState<CharacterProfile | null>(null);
  const [tab, setTab] = useState<'circle' | 'all'>(backend.circle ? 'circle' : 'all');

  if (selected) return <ContactDetail c={selected} onBack={() => setSelected(null)} />;

  if (tab === 'circle' && backend.circle && activeCharacter) {
    return (
      <div className="sys-app">
        <AppHeader title="Contatos" onBack={goHome} />
        <ContactsTabs tab={tab} onTab={setTab} />
        <div className="sys-scroll sys-pad">
          <CircleEditor
            client={backend.circle}
            characterId={activeCharacter.id}
            directory={characters}
            onChanged={reload}
            onOpenMember={(m) => setSelected(m.character)}
          />
        </div>
      </div>
    );
  }

  return <ContactsDirectory {...{ characters, activeCharacter, status, error, reload, query, setQuery, setSelected, tab, setTab, hasCircle: !!backend.circle }} />;
}

function ContactsTabs({ tab, onTab }: { tab: 'circle' | 'all'; onTab: (t: 'circle' | 'all') => void }) {
  return (
    <div className="segmented contacts-tabs" role="tablist">
      <button type="button" role="tab" aria-selected={tab === 'circle'} className={tab === 'circle' ? 'is-on' : ''} onClick={() => onTab('circle')}>
        Círculo
      </button>
      <button type="button" role="tab" aria-selected={tab === 'all'} className={tab === 'all' ? 'is-on' : ''} onClick={() => onTab('all')}>
        Todos
      </button>
    </div>
  );
}

interface DirectoryProps {
  characters: CharacterProfile[];
  activeCharacter: CharacterProfile | null;
  status: 'loading' | 'ready' | 'error';
  error: string | null;
  reload: () => void;
  query: string;
  setQuery: (q: string) => void;
  setSelected: (c: CharacterProfile) => void;
  tab: 'circle' | 'all';
  setTab: (t: 'circle' | 'all') => void;
  hasCircle: boolean;
}

function ContactsDirectory({ characters, activeCharacter, status, error, reload, query, setQuery, setSelected, tab, setTab, hasCircle }: DirectoryProps) {
  const { goHome } = usePhone();

  const others = useMemo(() => {
    const q = fold(query.trim());
    return characters
      .filter((c) => c.id !== activeCharacter?.id)
      .filter((c) => !q || fold(`${fullName(c)} ${c.email}`).includes(q))
      .sort((a, b) => fullName(a).localeCompare(fullName(b), 'pt-BR'));
  }, [characters, activeCharacter, query]);

  return (
    <div className="sys-app">
      <AppHeader title="Contatos" onBack={goHome} />
      {hasCircle && <ContactsTabs tab={tab} onTab={setTab} />}
      <div className="sys-search">
        <Search size={16} />
        <input
          type="search"
          placeholder="Buscar por nome ou e-mail"
          aria-label="Buscar contatos"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <div className="sys-scroll">
        {status === 'loading' && <CenteredSpinner />}
        {status === 'error' && <ErrorState message={error ?? 'Erro ao carregar contatos.'} onRetry={reload} />}
        {status === 'ready' && (
          <>
            {activeCharacter && !query && (
              <button type="button" className="my-card" onClick={() => setSelected(activeCharacter)}>
                <Avatar
                  name={fullName(activeCharacter)}
                  color={activeCharacter.avatarColor}
                  imageUrl={activeCharacter.avatarUrl}
                  size={56}
                />
                <span>
                  <strong>{fullName(activeCharacter)}</strong>
                  <small>Meu cartão</small>
                </span>
              </button>
            )}
            <div className="sys-group-title sys-group-title--pad">Personagens no RPG Phone</div>
            {others.length === 0 ? (
              <p className="sys-note">Nenhum personagem encontrado.</p>
            ) : (
              <ul className="sys-group contact-list">
                {others.map((c) => (
                  <li key={c.id}>
                    <button type="button" className="sys-cell contact-row" onClick={() => setSelected(c)}>
                      <Avatar name={fullName(c)} color={c.avatarColor} imageUrl={c.avatarUrl} size={36} />
                      <span>
                        <strong>
                          {fullName(c)} {c.kind === 'npc' && <span className="kind-badge is-npc">NPC</span>}
                        </strong>
                        <small>{c.email}</small>
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
            {!hasCircle && (
              <p className="sys-note">
                O círculo do personagem (família, amigos e NPCs) fica disponível ao conectar o Supabase.
              </p>
            )}
          </>
        )}
      </div>
    </div>
  );
}
