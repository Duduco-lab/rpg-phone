import { X } from 'lucide-react';
import { useId, useMemo, useRef, useState, type KeyboardEvent } from 'react';
import { fullName } from '../../../domain/character';
import { isValidAddress, normalizeAddress, type EmailAddress } from '../../../domain/email';
import { useSession } from '../../../session/SessionContext';
import { Avatar } from '../../../ui/Avatar';

interface Props {
  value: EmailAddress[];
  onChange: (next: EmailAddress[]) => void;
  pending: string;
  onPendingChange: (text: string) => void;
  autoFocus?: boolean;
}

const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

/**
 * Campo "Para" com chips. Aceita endereço digitado ou seleção a partir dos
 * personagens cadastrados (sugestões por nome ou e-mail).
 */
export function RecipientField({ value, onChange, pending, onPendingChange, autoFocus }: Props) {
  const { characters, identityOf } = useSession();
  const [focused, setFocused] = useState(false);
  const [highlight, setHighlight] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listId = useId();

  const suggestions = useMemo(() => {
    const q = fold(pending.trim());
    return characters
      .filter((c) => !value.includes(c.email))
      .filter((c) => !q || fold(`${fullName(c)} ${c.email}`).includes(q))
      .slice(0, 6);
  }, [characters, pending, value]);

  const add = (raw: string) => {
    const address = normalizeAddress(raw.replace(/[,;]+$/, ''));
    if (!address) return;
    if (!value.includes(address)) onChange([...value, address]);
    onPendingChange('');
    setHighlight(0);
  };

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    const open = focused && suggestions.length > 0;
    if (open && e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlight((h) => (h + 1) % suggestions.length);
    } else if (open && e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlight((h) => (h - 1 + suggestions.length) % suggestions.length);
    } else if (e.key === 'Enter' || e.key === ',' || e.key === ';' || e.key === 'Tab') {
      const pick = pending.trim() && open ? suggestions[highlight] : undefined;
      if (pick && !isValidAddress(pending)) {
        e.preventDefault();
        add(pick.email);
      } else if (pending.trim()) {
        e.preventDefault();
        add(pending);
      }
    } else if (e.key === 'Backspace' && !pending && value.length) {
      onChange(value.slice(0, -1));
    }
  };

  return (
    <div className="recipient-field" onClick={() => inputRef.current?.focus()}>
      {value.map((address) => {
        const id = identityOf(address);
        const known = !!id.character;
        return (
          <span
            key={address}
            className={`chip ${known ? '' : 'chip--invalid'}`}
            title={known ? address : 'Endereço não encontrado no RPG Phone'}
          >
            <Avatar name={id.name} color={id.color} imageUrl={id.avatarUrl} size={22} />
            <span className="chip-label">{known ? id.name : address}</span>
            <button
              type="button"
              className="chip-remove"
              aria-label={`Remover ${id.name}`}
              onClick={(e) => {
                e.stopPropagation();
                onChange(value.filter((a) => a !== address));
              }}
            >
              <X size={13} />
            </button>
          </span>
        );
      })}
      <input
        ref={inputRef}
        className="recipient-input"
        value={pending}
        autoFocus={autoFocus}
        inputMode="email"
        autoComplete="off"
        spellCheck={false}
        aria-label="Destinatários"
        aria-autocomplete="list"
        aria-controls={listId}
        placeholder={value.length ? '' : 'Nome ou endereço'}
        onChange={(e) => {
          onPendingChange(e.target.value);
          setHighlight(0);
        }}
        onKeyDown={onKeyDown}
        onFocus={() => setFocused(true)}
        onBlur={() => {
          // Pequeno atraso para permitir o clique numa sugestão.
          window.setTimeout(() => setFocused(false), 120);
          if (pending.trim() && isValidAddress(pending)) add(pending);
        }}
      />
      {focused && suggestions.length > 0 && (
        <ul className="suggestions" id={listId} role="listbox">
          <li className="suggestions-head">Personagens</li>
          {suggestions.map((c, i) => (
            <li key={c.id} role="option" aria-selected={i === highlight}>
              <button
                type="button"
                className={i === highlight ? 'is-hl' : ''}
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => add(c.email)}
              >
                <Avatar name={fullName(c)} color={c.avatarColor} imageUrl={c.avatarUrl} size={30} />
                <span>
                  <strong>{fullName(c)}</strong>
                  <small>{c.email}</small>
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
