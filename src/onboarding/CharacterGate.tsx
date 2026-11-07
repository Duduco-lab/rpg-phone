import { ChevronRight, KeyRound, LogOut, UserPlus } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';
import { CircleEditor } from '../circle/CircleEditor';
import { fullName, type CharacterProfile } from '../domain/character';
import { isValidAddress } from '../domain/email';
import { ProfileFields, type ProfileExtras } from './ProfileFields';
import { errorMessage, type AccountClient, type CircleClient, type DirectoryClient } from '../services/backend';
import { Avatar } from '../ui/Avatar';
import { Spinner } from '../ui/Spinner';
import '../circle/circle.css';

const COLORS = ['#7b5cd6', '#d1683c', '#1f9b8a', '#3a78c9', '#c2457a', '#5f6b7a', '#c47f1a', '#2e9e8f'];

type Step =
  | { name: 'list' }
  | { name: 'create' }
  | { name: 'claim' }
  | { name: 'circle'; character: CharacterProfile };

interface Props {
  account: AccountClient;
  circle: CircleClient;
  directory: DirectoryClient;
  /** Último personagem usado: selecionado automaticamente se ainda for do jogador. */
  rememberedId: string | null;
  onSelect: (character: CharacterProfile) => void;
}

function CreateForm({ account, onCreated, onCancel }: { account: AccountClient; onCreated: (c: CharacterProfile) => void; onCancel?: () => void }) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [description, setDescription] = useState('');
  const [color, setColor] = useState(COLORS[0]!);
  const [email, setEmail] = useState('');
  const [extras, setExtras] = useState<ProfileExtras>({ gender: 'n', countryCode: null, title: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setError(null);
    if (!firstName.trim()) return setError('Informe o nome do personagem.');
    if (email.trim() && !isValidAddress(email)) return setError('E-mail inválido.');
    setBusy(true);
    try {
      onCreated(await account.createCharacter({ firstName, lastName, description, avatarColor: color, email, ...extras }));
    } catch (e) {
      setError(errorMessage(e));
      setBusy(false);
    }
  };

  return (
    <form
      className="setup-form"
      onSubmit={(e) => {
        e.preventDefault();
        void submit();
      }}
    >
      <Avatar name={`${firstName || '?'} ${lastName}`} color={color} size={64} className="setup-avatar" />
      <h1>Novo personagem</h1>
      <p className="setup-sub">O número de telefone é gerado automaticamente.</p>
      <div className="field-row">
        <label className="field">
          <span>Nome</span>
          <input value={firstName} onChange={(e) => setFirstName(e.target.value)} maxLength={40} autoFocus />
        </label>
        <label className="field">
          <span>Sobrenome</span>
          <input value={lastName} onChange={(e) => setLastName(e.target.value)} maxLength={60} />
        </label>
      </div>
      <label className="field">
        <span>E-mail do personagem (no jogo)</span>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          maxLength={120}
          placeholder="ex.: mark@hotmail.com — vazio = gerar automático"
          autoComplete="off"
        />
      </label>
      <ProfileFields value={extras} onChange={setExtras} />
      <label className="field">
        <span>Descrição</span>
        <textarea value={description} onChange={(e) => setDescription(e.target.value)} maxLength={600} rows={3} placeholder="Quem é, o que faz…" />
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
      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      <button type="submit" className="btn-primary setup-submit" disabled={busy}>
        {busy && <Spinner size={16} />} Criar personagem
      </button>
      {onCancel && (
        <button type="button" className="btn-ghost" onClick={onCancel} disabled={busy}>
          Voltar
        </button>
      )}
    </form>
  );
}

function ClaimForm({ account, onClaimed, onCancel }: { account: AccountClient; onClaimed: (c: CharacterProfile) => void; onCancel: () => void }) {
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  return (
    <form
      className="setup-form"
      onSubmit={async (e) => {
        e.preventDefault();
        setError(null);
        if (!code.trim()) return setError('Digite o código.');
        setBusy(true);
        try {
          onClaimed(await account.claimNpc(code));
        } catch (err) {
          setError(errorMessage(err));
          setBusy(false);
        }
      }}
    >
      <div className="setup-logo">
        <KeyRound size={26} />
      </div>
      <h1>Código de convite</h1>
      <p className="setup-sub">
        Outro jogador colocou você no círculo dele? Use o código que ele te enviou para assumir o personagem, com todo o
        histórico de e-mails.
      </p>
      <label className="field">
        <span>Código</span>
        <input
          className="code-input"
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          placeholder="ABCD-1234"
          maxLength={12}
          autoFocus
        />
      </label>
      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      <button type="submit" className="btn-primary setup-submit" disabled={busy}>
        {busy && <Spinner size={16} />} Assumir personagem
      </button>
      <button type="button" className="btn-ghost" onClick={onCancel} disabled={busy}>
        Voltar
      </button>
    </form>
  );
}

function CircleStep({
  character,
  circle,
  directory,
  onDone,
}: {
  character: CharacterProfile;
  circle: CircleClient;
  directory: DirectoryClient;
  onDone: () => void;
}) {
  const [people, setPeople] = useState<CharacterProfile[]>([]);
  useEffect(() => {
    directory.listCharacters().then(setPeople, () => setPeople([]));
  }, [directory]);

  return (
    <div className="setup-form setup-form--wide">
      <h1>Círculo de {character.firstName}</h1>
      <p className="setup-sub">
        Família, amigos, colegas… Quem ainda não for jogador vira um <b>NPC</b> que manda e-mails de acordo com o vínculo.
        Você pode mudar isso depois em Contatos.
      </p>
      <CircleEditor client={circle} characterId={character.id} directory={people} />
      <button type="button" className="btn-primary setup-submit" onClick={onDone}>
        Ligar o telefone <ChevronRight size={16} />
      </button>
    </div>
  );
}

/** Escolha, criação ou resgate de personagem antes de abrir o telefone. */
export function CharacterGate({ account, circle, directory, rememberedId, onSelect }: Props) {
  const [characters, setCharacters] = useState<CharacterProfile[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [step, setStep] = useState<Step>({ name: 'list' });

  const load = useCallback(async () => {
    setError(null);
    try {
      const list = await account.myCharacters();
      const remembered = list.find((c) => c.id === rememberedId);
      if (remembered) onSelect(remembered);
      else setCharacters(list);
    } catch (e) {
      setError(errorMessage(e));
    }
  }, [account, rememberedId, onSelect]);

  useEffect(() => {
    void load();
  }, [load]);

  if (error) {
    return (
      <div className="setup-form">
        <h1>Ops</h1>
        <p className="form-error">{error}</p>
        <button type="button" className="btn-primary setup-submit" onClick={() => void load()}>
          Tentar novamente
        </button>
        <button type="button" className="btn-ghost" onClick={() => void account.signOut()}>
          Sair
        </button>
      </div>
    );
  }
  if (!characters) {
    return (
      <div className="setup-loading">
        <Spinner />
      </div>
    );
  }

  if (step.name === 'circle') {
    return <CircleStep character={step.character} circle={circle} directory={directory} onDone={() => onSelect(step.character)} />;
  }
  if (step.name === 'claim') {
    return <ClaimForm account={account} onCancel={() => setStep({ name: 'list' })} onClaimed={(c) => onSelect(c)} />;
  }
  if (step.name === 'create' || characters.length === 0) {
    return (
      <>
        <CreateForm
          account={account}
          onCancel={characters.length ? () => setStep({ name: 'list' }) : undefined}
          onCreated={(c) => setStep({ name: 'circle', character: c })}
        />
        {characters.length === 0 && (
          <div className="setup-alt">
            <button type="button" className="btn-ghost" onClick={() => setStep({ name: 'claim' })}>
              <KeyRound size={15} /> Tenho um código de convite
            </button>
            <button type="button" className="btn-ghost" onClick={() => void account.signOut()}>
              <LogOut size={15} /> Sair
            </button>
          </div>
        )}
      </>
    );
  }

  return (
    <div className="setup-form">
      <h1>Quem vai usar o telefone?</h1>
      <ul className="setup-list">
        {characters.map((c) => (
          <li key={c.id}>
            <button type="button" onClick={() => onSelect(c)}>
              <Avatar name={fullName(c)} color={c.avatarColor} imageUrl={c.avatarUrl} size={42} />
              <span>
                <strong>{fullName(c)}</strong>
                <small>{c.email}</small>
              </span>
              <ChevronRight size={18} />
            </button>
          </li>
        ))}
      </ul>
      <button type="button" className="btn-ghost" onClick={() => setStep({ name: 'create' })}>
        <UserPlus size={15} /> Novo personagem
      </button>
      <button type="button" className="btn-ghost" onClick={() => setStep({ name: 'claim' })}>
        <KeyRound size={15} /> Tenho um código de convite
      </button>
      <button type="button" className="btn-ghost" onClick={() => void account.signOut()}>
        <LogOut size={15} /> Sair
      </button>
    </div>
  );
}
