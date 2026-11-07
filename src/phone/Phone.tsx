import { useEffect, useState, type ComponentType } from 'react';
import { ContactsApp } from '../apps/contacts/ContactsApp';
import { EmailApp } from '../apps/email/EmailApp';
import { PlannedApp } from '../apps/placeholder/PlannedApp';
import { SettingsApp } from '../apps/settings/SettingsApp';
import { RumorApp } from '../apps/social/RumorApp';
import type { CharacterProfile } from '../domain/character';
import { MailboxProvider } from '../features/email/MailboxProvider';
import { useSession } from '../session/SessionContext';
import { APPS, type AppId } from './apps';
import { DeviceFrame } from './DeviceFrame';
import { HomeScreen } from './HomeScreen';
import { EmailNotifier, NotificationStack } from './Notifications';
import { PhoneProvider, usePhone } from './PhoneContext';
import { PreferencesProvider, usePreferences } from './preferences';
import { StatusBar } from './StatusBar';

const CLOSE_ANIMATION_MS = 220;

const AVAILABLE_APPS: Partial<Record<AppId, ComponentType>> = {
  email: EmailApp,
  contacts: ContactsApp,
  settings: SettingsApp,
  social: RumorApp,
};

function AppHost() {
  const { currentApp } = usePhone();
  const { backend } = useSession();
  const [rendered, setRendered] = useState<AppId | null>(currentApp);
  const [closing, setClosing] = useState(false);

  useEffect(() => {
    if (currentApp) {
      setRendered(currentApp);
      setClosing(false);
      return;
    }
    if (!rendered) return;
    setClosing(true);
    const t = window.setTimeout(() => {
      setRendered(null);
      setClosing(false);
    }, CLOSE_ANIMATION_MS);
    return () => window.clearTimeout(t);
  }, [currentApp, rendered]);

  if (!rendered) return null;
  // O Twixer depende do banco: no modo demonstração mostra a tela "em desenvolvimento".
  const Component = rendered === 'social' && !backend.social ? undefined : AVAILABLE_APPS[rendered];
  return (
    <div key={rendered} className={`app-layer ${closing ? 'is-closing' : 'is-opening'}`}>
      {Component ? <Component /> : <PlannedApp app={APPS[rendered]} />}
    </div>
  );
}

function HomeIndicator() {
  const { currentApp, goHome } = usePhone();
  return (
    <button
      type="button"
      className={`home-indicator ${currentApp ? 'on-app' : ''}`}
      onClick={goHome}
      aria-label="Ir para a tela inicial"
      title="Tela inicial"
    >
      <span />
    </button>
  );
}

function Screen() {
  const { currentApp } = usePhone();
  const { resolvedTheme, wallpaperCss } = usePreferences();
  const statusTone = currentApp ? (resolvedTheme === 'dark' ? 'light' : 'dark') : 'light';

  return (
    <div className="screen" data-theme={resolvedTheme}>
      <div className="wallpaper" style={{ background: wallpaperCss }} />
      <HomeScreen />
      <AppHost />
      <StatusBar tone={statusTone} />
      <NotificationStack />
      <HomeIndicator />
      <EmailNotifier />
    </div>
  );
}

/** Um aparelho = um personagem. Trocar de personagem remonta o aparelho inteiro. */
export function Phone({ character }: { character: CharacterProfile }) {
  const { backend } = useSession();
  return (
    <DeviceFrame>
      <PreferencesProvider characterId={character.id}>
        <PhoneProvider>
          <MailboxProvider client={backend.mailboxFor(character.id)}>
            <Screen />
          </MailboxProvider>
        </PhoneProvider>
      </PreferencesProvider>
    </DeviceFrame>
  );
}
