import { Copy, Plus, Trash2, UserPlus, Users } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { fullName, GENDER_LABELS, type CharacterId, type CharacterProfile, type Gender } from '../domain/character';
import {
  guessRelationKind,
  RELATION_KIND_LABELS,
  RELATION_KINDS,
  type CircleMember,
  type RelationKind,
} from '../domain/circle';
import { errorMessage, type CircleClient } from '../services/backend';
import { Avatar } from '../ui/Avatar';
import { ConfirmSheet } from '../ui/ConfirmSheet';
import { Spinner } from '../ui/Spinner';
import './circle.css';

interface Props {
  client: CircleClient;
  characterId: CharacterId;
  /** Personagens cadastrados (para vincular alguém que já existe). */
  directory: CharacterProfile[];
  onOpenMember?: (member: CircleMember) => void;
  /** Chamado após adicionar/remover (ex.: para atualizar o diretório). */
  onChanged?: () => void;
}

type Mode = 'npc' | 'existing';

/** Sugere o gênero pela relação digitada ("esposa" → feminino). */
function guessGender(label: string): Gender {
  const f = label
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();
  if (/^(esposa|mulher|namorada|noiva|mae|madrasta|filha|enteada|irma|tia|prima|avo$|sogra|cunhada|amiga|chefa|amante|ex-?esposa|ex-?namorada)/.test(f)) return 'f';
  if (/^(marido|esposo|namorado|noivo|pai|padrasto|filho|enteado|irmao|tio|primo|sogro|cunhado|amigo|chefe|ex-?marido|ex-?namorado)/.test(f)) return 'm';
  return 'n';
}

function AddMemberForm({
  client,
  characterId,
  candidates,
  onDone,
  onCancel,
}: {
  client: CircleClient;
  characterId: CharacterId;
  candidates: CharacterProfile[];
  onDone: () => void;
  onCancel: () => void;
}) {
  const [mode, setMode] = useState<Mode>('npc');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [description, setDescription] = useState('');
  const [existingId, setExistingId] = useState('');
  const [label, setLabel] = useState('');
  const [kind, setKind] = useState<RelationKind>('outro');
  const [kindTouched, setKindTouched] = useState(false);
  const [gender, setGender] = useState<Gender>('n');
  const [genderTouched, setGenderTouched] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onLabel = (value: string) => {
    setLabel(value);
    if (!kindTouched) setKind(guessRelationKind(value) ?? 'outro');
    if (!genderTouched) setGender(guessGender(value));
  };

  const submit = async () => {
    setError(null);
    if (mode === 'npc' && !firstName.trim()) return setError('Informe o nome da pessoa.');
    if (mode === 'existing' && !existingId) return setError('Escolha um personagem.');
    if (!label.trim()) return setError('Informe a relação (ex.: irmão, marido).');
    setBusy(true);
    try {
      await client.add(characterId, {
        relationLabel: label.trim(),
        relationKind: kind,
        existingCharacterId: mode === 'existing' ? existingId : null,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        description: description.trim(),
        gender,
      });
      onDone();
    } catch (e) {
      setError(errorMessage(e));
      setBusy(false);
    }
  };

  return (
    <form
      className="circle-form"
      onSubmit={(e) => {
        e.preventDefault();
        void submit();
      }}
    >
      <div className="segmented" role="radiogroup" aria-label="Quem é">
        <button type="button" role="radio" aria-checked={mode === 'npc'} className={mode === 'npc' ? 'is-on' : ''} onClick={() => setMode('npc')}>
          Pessoa nova (NPC)
        </button>
        <button
          type="button"
          role="radio"
          aria-checked={mode === 'existing'}
          className={mode === 'existing' ? 'is-on' : ''}
          onClick={() => setMode('existing')}
          disabled={candidates.length === 0}
        >
          Já cadastrado
        </button>
      </div>

      {mode === 'npc' ? (
        <>
          <div className="field-row">
            <label className="field">
              <span>Nome</span>
              <input value={firstName} onChange={(e) => setFirstName(e.target.value)} maxLength={40} placeholder="Henrique" autoFocus />
            </label>
            <label className="field">
              <span>Sobrenome</span>
              <input value={lastName} onChange={(e) => setLastName(e.target.value)} maxLength={60} />
            </label>
          </div>
          <label className="field">
            <span>Gênero</span>
            <select
              value={gender}
              onChange={(e) => {
                setGender(e.target.value as Gender);
                setGenderTouched(true);
              }}
            >
              {(Object.keys(GENDER_LABELS) as Gender[]).map((g) => (
                <option key={g} value={g}>
                  {GENDER_LABELS[g]}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Sobre (opcional)</span>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} maxLength={600} rows={2} />
          </label>
        </>
      ) : (
        <label className="field">
          <span>Personagem</span>
          <select value={existingId} onChange={(e) => setExistingId(e.target.value)}>
            <option value="">Escolha…</option>
            {candidates.map((c) => (
              <option key={c.id} value={c.id}>
                {fullName(c)} {c.kind === 'npc' ? '(NPC)' : ''}
              </option>
            ))}
          </select>
        </label>
      )}

      <div className="field-row">
        <label className="field">
          <span>É meu/minha…</span>
          <input value={label} onChange={(e) => onLabel(e.target.value)} maxLength={40} placeholder="irmão, marido…" />
        </label>
        <label className="field">
          <span>Tipo de vínculo</span>
          <select
            value={kind}
            onChange={(e) => {
              setKind(e.target.value as RelationKind);
              setKindTouched(true);
            }}
          >
            {RELATION_KINDS.map((k) => (
              <option key={k} value={k}>
                {RELATION_KIND_LABELS[k]}
              </option>
            ))}
          </select>
        </label>
      </div>
      {mode === 'npc' && (
        <p className="field-hint">O tipo de vínculo define o tom dos e-mails que este NPC vai mandar.</p>
      )}

      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      <div className="form-actions">
        <button type="button" className="btn-ghost" onClick={onCancel} disabled={busy}>
          Cancelar
        </button>
        <button type="submit" className="btn-primary" disabled={busy}>
          {busy ? <Spinner size={16} /> : <Plus size={16} />} Adicionar
        </button>
      </div>
    </form>
  );
}

/** Lista e edita o círculo social de um personagem. */
export function CircleEditor({ client, characterId, directory, onOpenMember, onChanged }: Props) {
  const [members, setMembers] = useState<CircleMember[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [removing, setRemoving] = useState<CircleMember | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setMembers(await client.list(characterId));
      setError(null);
    } catch (e) {
      setError(errorMessage(e));
    }
  }, [client, characterId]);

  useEffect(() => {
    void load();
  }, [load]);

  const candidates = useMemo(() => {
    const taken = new Set((members ?? []).map((m) => m.character.id));
    return directory.filter((c) => c.id !== characterId && !taken.has(c.id));
  }, [directory, members, characterId]);

  const copy = async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      setNotice(`Código ${code} copiado.`);
    } catch {
      setNotice(`Código: ${code}`);
    }
  };

  if (error && !members) {
    return (
      <div className="circle-state">
        <p>{error}</p>
        <button type="button" className="btn-ghost" onClick={() => void load()}>
          Tentar novamente
        </button>
      </div>
    );
  }
  if (!members) {
    return (
      <div className="circle-state">
        <Spinner />
      </div>
    );
  }

  return (
    <div className="circle">
      {members.length === 0 && !adding && (
        <div className="circle-empty">
          <Users size={34} strokeWidth={1.5} />
          <p>Ninguém no círculo ainda. Adicione família, amigos, colegas… Quem não for jogador vira um NPC que manda e-mails.</p>
        </div>
      )}

      {members.length > 0 && (
        <ul className="circle-list">
          {members.map((m) => (
            <li key={m.id} className="circle-item">
              <button type="button" className="circle-item-main" onClick={() => onOpenMember?.(m)} disabled={!onOpenMember}>
                <Avatar name={fullName(m.character)} color={m.character.avatarColor} imageUrl={m.character.avatarUrl} size={40} />
                <span className="circle-item-text">
                  <strong>{fullName(m.character)}</strong>
                  <span>
                    <span className="relation-chip">{m.relationLabel}</span>
                    <span className={`kind-badge ${m.isNpc ? 'is-npc' : 'is-player'}`}>{m.isNpc ? 'NPC' : 'Jogador'}</span>
                  </span>
                </span>
              </button>
              {m.claimCode && (
                <button type="button" className="claim-code" title="Copiar código de convite" onClick={() => void copy(m.claimCode!)}>
                  <Copy size={13} /> {m.claimCode}
                </button>
              )}
              <button type="button" className="circle-remove" aria-label={`Remover ${fullName(m.character)}`} title="Remover do círculo" onClick={() => setRemoving(m)}>
                <Trash2 size={17} />
              </button>
            </li>
          ))}
        </ul>
      )}

      {members.some((m) => m.claimCode) && (
        <p className="field-hint circle-hint">
          Se alguém for jogar como um desses NPCs, envie o <b>código de convite</b>: ao usá-lo, a pessoa assume o personagem
          com todo o histórico de e-mails, e a simulação para.
        </p>
      )}
      {notice && <p className="field-hint circle-hint">{notice}</p>}

      {adding ? (
        <AddMemberForm
          client={client}
          characterId={characterId}
          candidates={candidates}
          onCancel={() => setAdding(false)}
          onDone={() => {
            setAdding(false);
            void load();
            onChanged?.();
          }}
        />
      ) : (
        <button type="button" className="circle-add" onClick={() => setAdding(true)}>
          <UserPlus size={18} /> Adicionar pessoa ao círculo
        </button>
      )}

      {removing && (
        <ConfirmSheet
          title={`Remover ${fullName(removing.character)}?`}
          message={
            removing.isNpc
              ? 'O NPC deixa de mandar e-mails. As conversas já trocadas continuam na sua caixa.'
              : 'A pessoa sai do seu círculo. As conversas continuam na sua caixa.'
          }
          onCancel={() => setRemoving(null)}
          actions={[
            {
              label: 'Remover',
              tone: 'danger',
              onSelect: async () => {
                const target = removing;
                setRemoving(null);
                try {
                  await client.remove(characterId, target.id);
                  await load();
                  onChanged?.();
                } catch (e) {
                  setNotice(errorMessage(e));
                }
              },
            },
          ]}
        />
      )}
    </div>
  );
}
