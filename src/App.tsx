import { LogOut, Users } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { DEFAULT_DEMO_CHARACTER_ID } from './data/demo/characters';
import { DemoPanel } from './demo/DemoPanel';
import { fullName, type CharacterProfile } from './domain/character';
import { readJson, writeJson } from './lib/storage';
import { isInDiscord } from './discord/discord';
import { AuthScreen } from './onboarding/AuthScreen';
import { CharacterGate } from './onboarding/CharacterGate';
import { SetupScreen } from './onboarding/SetupScreen';
import { Phone } from './phone/Phone';
import type { AccountSession, DataBackend } from './services/backend';
import { createBackend } from './services/createBackend';
import type { DemoBackend } from './services/demo/demoBackend';
import { SessionProvider, useSession, type AccountActions } from './session/SessionContext';
import { Avatar } from './ui/Avatar';
import { CenteredSpinner } from './ui/Spinner';
import { ErrorState } from './ui/ErrorState';

function Stage() {
  const { status, error, activeCharacter, reload } = useSession();
  if (status === 'loading') return <CenteredSpinner label="Ligando o telefone" />;
  if (status === 'error' || !activeCharacter) {
    return <ErrorState message={error ?? 'Personagem não disponível.'} onRetry={reload} />;
  }
  // `key` garante um aparelho novo (estado limpo) ao trocar de personagem.
  return <Phone key={activeCharacter.id} character={activeCharacter} />;
}

/** Modo demonstração: dados em memória e painel para trocar de personagem. */
function DemoApp({ backend }: { backend: DemoBackend }) {
  return (
    <SessionProvider backend={backend} initialCharacterId={DEFAULT_DEMO_CHARACTER_ID}>
      <main className="app-root">
        <DemoPanel backend={backend} />
        <div className="stage-area">
          <Stage />
        </div>
      </main>
    </SessionProvider>
  );
}

/** Barra da conta (fora do telefone). Usa o perfil da sessão para refletir edições. */
function AccountBar({
  fallback,
  email,
  onSwitch,
  onSignOut,
}: {
  fallback: CharacterProfile;
  email: string;
  onSwitch: () => void;
  /** null = sem botão Sair (dentro do Discord a conta é a do Discord). */
  onSignOut: (() => void) | null;
}) {
  const { activeCharacter } = useSession();
  const c = activeCharacter ?? fallback;
  return (
    <div className="account-bar">
      <Avatar name={fullName(c)} color={c.avatarColor} imageUrl={c.avatarUrl} size={30} />
      <span className="account-bar-text">
        <strong>{fullName(c)}</strong>
        <small>{email}</small>
      </span>
      <button type="button" onClick={onSwitch} title="Trocar de personagem">
        <Users size={14} /> Trocar
      </button>
      {onSignOut && (
        <button type="button" onClick={onSignOut} title="Sair da conta">
          <LogOut size={14} /> Sair
        </button>
      )}
    </div>
  );
}

const lastCharacterKey =(userId: string) => `rpgphone:last-character:${userId}`;

/** Modo real (Supabase): login → personagem → telefone. */
function OnlineApp({ backend }: { backend: DataBackend }) {
  const inDiscord = useMemo(() => isInDiscord(), []);
  const account = backend.account!;
  const circle = backend.circle!;
  const [session, setSession] = useState<AccountSession | null | undefined>(undefined);
  const [character, setCharacter] = useState<CharacterProfile | null>(null);
  const [sessionError, setSessionError] = useState<string | null>(null);

  useEffect(() => {
    account.getSession().then(setSession, (e: unknown) => {
      setSessionError(e instanceof Error ? e.message : 'Erro ao verificar a sessão.');
      setSession(null);
    });
    return account.onSessionChange((s) => {
      setSession(s);
      if (!s) setCharacter(null);
    });
  }, [account]);

  const remembered = session ? readJson<{ id: string | null }>(lastCharacterKey(session.userId), { id: null }).id : null;

  const select = useCallback(
    (c: CharacterProfile) => {
      if (session) writeJson(lastCharacterKey(session.userId), { id: c.id });
      setCharacter(c);
    },
    [session],
  );

  const accountActions = useMemo<AccountActions | null>(() => {
    if (!session) return null;
    return {
      switchCharacter: () => {
        writeJson(lastCharacterKey(session.userId), { id: null });
        setCharacter(null);
      },
      signOut: () => void account.signOut(),
    };
  }, [session, account]);

  if (session === undefined) {
    return (
      <main className="app-root">
        <div className="stage-area">
          <CenteredSpinner />
        </div>
      </main>
    );
  }

  if (!session || !character) {
    return (
      <main className="app-root">
        <div className="stage-area">
          <SetupScreen>
            {!session ? (
              <>
                {sessionError && <p className="form-error">{sessionError}</p>}
                <AuthScreen account={account} />
              </>
            ) : (
              <CharacterGate
                key={session.userId}
                account={account}
                circle={circle}
                directory={backend.directory}
                rememberedId={remembered}
                onSelect={select}
              />
            )}
          </SetupScreen>
        </div>
      </main>
    );
  }

  return (
    <SessionProvider key={character.id} backend={backend} initialCharacterId={character.id} accountActions={accountActions}>
      <main className="app-root app-root--online">
        {/* No Discord, trocar personagem fica em Ajustes (dentro do telefone). */}
        {!inDiscord && accountActions && (
          <AccountBar
            fallback={character}
            email={session.email}
            onSwitch={accountActions.switchCharacter}
            onSignOut={accountActions.signOut}
          />
        )}
        <div className="stage-area">
          <Stage />
        </div>
      </main>
    </SessionProvider>
  );
}

export function App() {
  const app = useMemo(() => createBackend(), []);
  return app.kind === 'demo' ? <DemoApp backend={app.backend} /> : <OnlineApp backend={app.backend} />;
}
