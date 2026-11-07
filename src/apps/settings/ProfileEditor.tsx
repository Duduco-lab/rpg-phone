import { ChevronLeft } from 'lucide-react';
import { useState } from 'react';
import { fullName, type CharacterProfile } from '../../domain/character';
import { isValidAddress } from '../../domain/email';
import { ProfileFields, type ProfileExtras } from '../../onboarding/ProfileFields';
import { useMailbox } from '../../features/email/MailboxProvider';
import { errorMessage, type AccountClient } from '../../services/backend';
import { useSession } from '../../session/SessionContext';
import { Avatar } from '../../ui/Avatar';
import { Spinner } from '../../ui/Spinner';
import '../../circle/circle.css';

const COLORS = ['#7b5cd6', '#d1683c', '#1f9b8a', '#3a78c9', '#c2457a', '#5f6b7a', '#c47f1a', '#2e9e8f'];

interface Props {
  account: AccountClient;
  character: CharacterProfile;
  onClose: (message?: string) => void;
}

/** Edição do perfil do personagem (nome, descrição, cor e e-mail). */
export function ProfileEditor({ account, character, onClose }: Props) {
  const { reload } = useSession();
  const mailbox = useMailbox();
  const [firstName, setFirstName] = useState(character.firstName);
  const [lastName, setLastName] = useState(character.lastName);
  const [description, setDescription] = useState(character.description);
  const [color, setColor] = useState(character.avatarColor);
  const [email, setEmail] = useState(character.email);
  const [extras, setExtras] = useState<ProfileExtras>({
    gender: character.gender ?? 'n',
    countryCode: character.countryCode ?? null,
    title: character.title ?? '',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const emailChanged = email.trim().toLowerCase() !== character.email;

  const save = async () => {
    setError(null);
    if (!firstName.trim()) return setError('Informe o nome do personagem.');
    if (!email.trim() || !isValidAddress(email)) return setError('E-mail inválido.');
    setBusy(true);
    try {
      const updated = await account.updateCharacter(character.id, {
        firstName,
        lastName,
        description,
        avatarColor: color,
        email: emailChanged ? email : '',
        ...extras,
      });
      reload();
      await mailbox.reload();
      onClose(updated.email !== character.email ? `Novo e-mail: ${updated.email}` : 'Perfil atualizado.');
    } catch (e) {
      setError(errorMessage(e));
      setBusy(false);
    }
  };

  return (
    <div className="sys-app">
      <div className="sys-header">
        <div className="sys-header-bar">
          <button type="button" className="sys-back" onClick={() => onClose()} disabled={busy}>
            <ChevronLeft size={22} />
            Ajustes
          </button>
        </div>
        <h1 className="sys-title">Editar perfil</h1>
      </div>
      <form
        className="sys-scroll sys-pad profile-form"
        onSubmit={(e) => {
          e.preventDefault();
          void save();
        }}
      >
        <Avatar name={`${firstName || '?'} ${lastName}`} color={color} size={72} className="profile-form-avatar" />
        <div className="field-row">
          <label className="field">
            <span>Nome</span>
            <input value={firstName} onChange={(e) => setFirstName(e.target.value)} maxLength={40} />
          </label>
          <label className="field">
            <span>Sobrenome</span>
            <input value={lastName} onChange={(e) => setLastName(e.target.value)} maxLength={60} />
          </label>
        </div>
        <ProfileFields value={extras} onChange={setExtras} />
        <label className="field">
          <span>Descrição</span>
          <textarea value={description} onChange={(e) => setDescription(e.target.value)} maxLength={600} rows={3} />
        </label>
        <div className="field">
          <span>Cor do avatar</span>
          <div className="color-row" role="radiogroup" aria-label="Cor do avatar">
            {COLORS.map((c) => (
              <button
                key={c}
                type="button"
                role="radio"
                aria-checked={c === color}
                aria-label={c}
                className={`color-dot ${c === color ? 'is-on' : ''}`}
                style={{ background: c }}
                onClick={() => setColor(c)}
              />
            ))}
          </div>
        </div>

        <label className="field">
          <span>E-mail do personagem (no jogo)</span>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} maxLength={120} autoComplete="off" />
        </label>
        {emailChanged && (
          <p className="field-hint">Os outros personagens passarão a ver e a escrever para o novo endereço.</p>
        )}

        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <div className="form-actions">
          <button type="button" className="btn-ghost" onClick={() => onClose()} disabled={busy}>
            Cancelar
          </button>
          <button type="submit" className="btn-primary" disabled={busy}>
            {busy && <Spinner size={16} />} Salvar
          </button>
        </div>
        <p className="field-hint">Visualização: {fullName({ firstName: firstName.trim(), lastName: lastName.trim() })}</p>
      </form>
    </div>
  );
}
