import { Check, ImagePlus, LogOut, Moon, Pencil, Smartphone, Sun, Users } from 'lucide-react';
import { ProfileEditor } from './ProfileEditor';
import { useRef, useState } from 'react';
import { fullName } from '../../domain/character';
import { usePhone } from '../../phone/PhoneContext';
import { usePreferences, WALLPAPERS, type ThemePreference } from '../../phone/preferences';
import { useSession } from '../../session/SessionContext';
import { Avatar } from '../../ui/Avatar';
import { AppHeader } from '../shared/AppHeader';
import '../shared/system-apps.css';

const MAX_IMAGE_BYTES = 1.5 * 1024 * 1024;

const THEMES: { id: ThemePreference; label: string; icon: typeof Sun }[] = [
  { id: 'light', label: 'Claro', icon: Sun },
  { id: 'dark', label: 'Escuro', icon: Moon },
  { id: 'system', label: 'Automático', icon: Smartphone },
];

export function SettingsApp() {
  const { goHome } = usePhone();
  const { activeCharacter, backend, accountActions } = useSession();
  const { prefs, update, wallpaperCss } = usePreferences();
  const fileRef = useRef<HTMLInputElement>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [editing, setEditing] = useState(false);

  if (editing && activeCharacter && backend.account) {
    return (
      <ProfileEditor
        account={backend.account}
        character={activeCharacter}
        onClose={(message) => {
          setEditing(false);
          if (message) setNotice(message);
        }}
      />
    );
  }

  const onFile = (file: File | undefined) => {
    setNotice(null);
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setNotice('Escolha um arquivo de imagem.');
      return;
    }
    if (file.size > MAX_IMAGE_BYTES) {
      setNotice('Imagem muito grande (máx. 1,5 MB).');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      const ok = update({ customWallpaper: String(reader.result) });
      setNotice(ok ? 'Papel de parede atualizado.' : 'Aplicado, mas não foi possível salvar no navegador.');
    };
    reader.onerror = () => setNotice('Não foi possível ler a imagem.');
    reader.readAsDataURL(file);
  };

  return (
    <div className="sys-app">
      <AppHeader title="Ajustes" onBack={goHome} />
      <div className="sys-scroll">
        {activeCharacter && (
          <div className="sys-group">
            <div className="sys-cell profile-cell">
              <Avatar
                name={fullName(activeCharacter)}
                color={activeCharacter.avatarColor}
                imageUrl={activeCharacter.avatarUrl}
                size={58}
              />
              <span>
                <strong>{fullName(activeCharacter)}</strong>
                <small>{activeCharacter.email}</small>
                <small>{activeCharacter.phoneNumber}</small>
              </span>
            </div>
            {backend.account && (
              <button type="button" className="sys-cell sys-cell--action" onClick={() => setEditing(true)}>
                <Pencil size={17} /> Editar perfil
              </button>
            )}
            {accountActions && (
              <button type="button" className="sys-cell sys-cell--action" onClick={accountActions.switchCharacter}>
                <Users size={17} /> Trocar de personagem
              </button>
            )}
            {accountActions?.signOut && (
              <button type="button" className="sys-cell sys-cell--action sys-cell--danger" onClick={accountActions.signOut}>
                <LogOut size={17} /> Sair da conta
              </button>
            )}
          </div>
        )}
        {notice && !editing && <p className="sys-note sys-note--top">{notice}</p>}

        <div className="sys-group-title sys-group-title--pad">Papel de parede</div>
        <div className="sys-group wallpaper-group">
          <div className="wallpaper-current" style={{ background: wallpaperCss }} aria-hidden="true" />
          <div className="wallpaper-grid" role="radiogroup" aria-label="Papéis de parede">
            {WALLPAPERS.map((w) => {
              const on = !prefs.customWallpaper && prefs.wallpaperId === w.id;
              return (
                <button
                  key={w.id}
                  type="button"
                  role="radio"
                  aria-checked={on}
                  aria-label={w.name}
                  title={w.name}
                  className={`wallpaper-swatch ${on ? 'is-on' : ''}`}
                  style={{ background: w.css }}
                  onClick={() => update({ wallpaperId: w.id, customWallpaper: null })}
                >
                  {on && <Check size={16} />}
                </button>
              );
            })}
          </div>
          <button type="button" className="sys-cell sys-cell--action" onClick={() => fileRef.current?.click()}>
            <ImagePlus size={18} /> Usar imagem própria…
          </button>
          {prefs.customWallpaper && (
            <button
              type="button"
              className="sys-cell sys-cell--action sys-cell--danger"
              onClick={() => update({ customWallpaper: null })}
            >
              Remover imagem própria
            </button>
          )}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            hidden
            onChange={(e) => {
              onFile(e.target.files?.[0]);
              e.target.value = '';
            }}
          />
        </div>
        {notice && <p className="sys-note">{notice}</p>}

        <div className="sys-group-title sys-group-title--pad">Aparência dos apps</div>
        <div className="sys-group theme-group" role="radiogroup" aria-label="Tema">
          {THEMES.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                type="button"
                role="radio"
                aria-checked={prefs.theme === t.id}
                className={`theme-option ${prefs.theme === t.id ? 'is-on' : ''}`}
                onClick={() => update({ theme: t.id })}
              >
                <Icon size={20} />
                {t.label}
              </button>
            );
          })}
        </div>

        <div className="sys-group-title sys-group-title--pad">Sobre</div>
        <div className="sys-group">
          <div className="sys-cell sys-cell--between">
            <span>Sistema</span>
            <small>RPG Phone 0.1 (Fase 1)</small>
          </div>
          <div className="sys-cell sys-cell--between">
            <span>Fonte de dados</span>
            <small>{backend.label}</small>
          </div>
        </div>
        <p className="sys-note">
          As preferências visuais ficam salvas neste navegador, separadas por personagem.
        </p>
      </div>
    </div>
  );
}
