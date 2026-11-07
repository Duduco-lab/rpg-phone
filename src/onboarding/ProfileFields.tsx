import { GENDER_LABELS, type Gender } from '../domain/character';
import { COUNTRIES } from '../domain/countries';

export interface ProfileExtras {
  gender: Gender;
  countryCode: string | null;
  title: string;
}

interface Props {
  value: ProfileExtras;
  onChange: (next: ProfileExtras) => void;
}

/** Gênero, nacionalidade e título — usados nos textos dos NPCs e no Twixer. */
export function ProfileFields({ value, onChange }: Props) {
  return (
    <>
      <div className="field-row">
        <label className="field">
          <span>Gênero</span>
          <select value={value.gender} onChange={(e) => onChange({ ...value, gender: e.target.value as Gender })}>
            {(Object.keys(GENDER_LABELS) as Gender[]).map((g) => (
              <option key={g} value={g}>
                {GENDER_LABELS[g]}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Nacionalidade</span>
          <select
            value={value.countryCode ?? ''}
            onChange={(e) => onChange({ ...value, countryCode: e.target.value || null })}
          >
            <option value="">Escolha…</option>
            {COUNTRIES.map((c) => (
              <option key={c.code} value={c.code}>
                {c.flag} {c.name}
              </option>
            ))}
          </select>
        </label>
      </div>
      <label className="field">
        <span>Título / posição</span>
        <input
          value={value.title}
          onChange={(e) => onChange({ ...value, title: e.target.value })}
          maxLength={80}
          placeholder="ex.: Imperador germânico, Nobre da corte italiana"
        />
      </label>
      <p className="field-hint">
        A nacionalidade e o círculo (cônjuge, filhos, romances…) definem as notícias e fofocas do Twixer sobre você.
      </p>
    </>
  );
}
