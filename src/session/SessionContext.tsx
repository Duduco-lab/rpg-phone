import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { fullName, type CharacterId, type CharacterProfile } from '../domain/character';
import { normalizeAddress, type EmailAddress } from '../domain/email';
import { colorFromString } from '../lib/format';
import { errorMessage, type DataBackend } from '../services/backend';

export interface Identity {
  name: string;
  address: EmailAddress;
  color: string;
  avatarUrl: string | null;
  character: CharacterProfile | null;
}

interface SessionValue {
  backend: DataBackend;
  status: 'loading' | 'ready' | 'error';
  error: string | null;
  characters: CharacterProfile[];
  /**
   * Personagem em uso. Na Fase 1 é escolhido no painel de demonstração;
   * na Fase 6 virá da autenticação do Discord validada no backend.
   */
  activeCharacter: CharacterProfile | null;
  setActiveCharacterId: (id: CharacterId) => void;
  identityOf: (address: EmailAddress) => Identity;
  reload: () => void;
  /** Ações da conta (modo online). Ausentes no modo demonstração. */
  accountActions: AccountActions | null;
}

export interface AccountActions {
  switchCharacter: () => void;
  /** null quando sair não se aplica (dentro do Discord). */
  signOut: (() => void) | null;
}

const SessionContext = createContext<SessionValue | null>(null);

interface Props {
  backend: DataBackend;
  initialCharacterId: CharacterId;
  accountActions?: AccountActions | null;
  children: ReactNode;
}

export function SessionProvider({ backend, initialCharacterId, accountActions = null, children }: Props) {
  const [characters, setCharacters] = useState<CharacterProfile[]>([]);
  const [status, setStatus] = useState<SessionValue['status']>('loading');
  const [error, setError] = useState<string | null>(null);
  const [activeId, setActiveId] = useState<CharacterId>(initialCharacterId);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    // Recarregamentos posteriores atualizam em segundo plano (sem desmontar o telefone).
    setStatus((s) => (s === 'ready' ? s : 'loading'));
    backend.directory
      .listCharacters()
      .then((list) => {
        if (cancelled) return;
        setCharacters(list);
        setStatus('ready');
        setError(null);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(errorMessage(e));
        setStatus('error');
      });
    return () => {
      cancelled = true;
    };
  }, [backend, reloadKey]);

  const byAddress = useMemo(() => {
    const map = new Map<string, CharacterProfile>();
    for (const c of characters) map.set(c.email, c);
    return map;
  }, [characters]);

  const identityOf = useCallback(
    (address: EmailAddress): Identity => {
      const normalized = normalizeAddress(address);
      const c = byAddress.get(normalized) ?? null;
      return {
        name: c ? fullName(c) : normalized,
        address: normalized,
        color: c?.avatarColor ?? colorFromString(normalized),
        avatarUrl: c?.avatarUrl ?? null,
        character: c,
      };
    },
    [byAddress],
  );

  const value = useMemo<SessionValue>(
    () => ({
      backend,
      status,
      error,
      characters,
      activeCharacter: characters.find((c) => c.id === activeId) ?? null,
      setActiveCharacterId: setActiveId,
      identityOf,
      reload: () => setReloadKey((k) => k + 1),
      accountActions,
    }),
    [backend, status, error, characters, activeId, identityOf, accountActions],
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): SessionValue {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error('useSession deve ser usado dentro de <SessionProvider>.');
  return ctx;
}
