import type { CharacterProfile, Gender } from './character';

/** O que a pessoa do círculo É para o personagem (define o tom dos e-mails simulados). */
export type RelationKind =
  | 'pai_mae'
  | 'filho'
  | 'irmao'
  | 'parceiro'
  | 'romance'
  | 'ex'
  | 'amigo'
  | 'colega'
  | 'chefe'
  | 'rival'
  | 'parente'
  | 'outro';

export const RELATION_KIND_LABELS: Record<RelationKind, string> = {
  pai_mae: 'Pai / mãe',
  filho: 'Filho(a)',
  irmao: 'Irmão(ã)',
  parceiro: 'Cônjuge / namorado(a)',
  romance: 'Romance / caso secreto',
  ex: 'Ex',
  amigo: 'Amigo(a)',
  colega: 'Colega de trabalho',
  chefe: 'Chefe',
  rival: 'Rival / inimigo(a)',
  parente: 'Outro parente',
  outro: 'Outro',
};

export const RELATION_KINDS = Object.keys(RELATION_KIND_LABELS) as RelationKind[];

export interface CircleMember {
  /** ID do vínculo. */
  id: string;
  /** Como o jogador descreveu (ex.: "irmão", "marido"). */
  relationLabel: string;
  relationKind: RelationKind;
  character: CharacterProfile;
  isNpc: boolean;
  /** Código para um jogador assumir este NPC (só para NPCs criados por este personagem). */
  claimCode: string | null;
}

export interface NewCircleMemberInput {
  relationLabel: string;
  relationKind: RelationKind;
  /** Vincular um personagem já cadastrado… */
  existingCharacterId: string | null;
  /** …ou criar um NPC novo. */
  firstName: string;
  lastName: string;
  description: string;
  /** Gênero do NPC novo (concordância nos textos: "o marido" / "a esposa"). */
  gender: Gender;
}

const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();

const GUESSES: [RegExp, RelationKind][] = [
  [/^(pai|mae|padrasto|madrasta)\b/, 'pai_mae'],
  [/^(filh|enteado|enteada)/, 'filho'],
  [/^(irma|meio[- ]irma)/, 'irmao'],
  [/^(marido|esposa|esposo|mulher|namorad|noiv|conjuge|companheir|parceir)/, 'parceiro'],
  [/^(amante|caso|affair|romance|crush|paquera)/, 'romance'],
  [/^ex\b|^ex-/, 'ex'],
  [/^(amig|melhor amig|parceiro de)/, 'amigo'],
  [/^(colega|socio|socia|funcionari|assistente|parceiro de trabalho)/, 'colega'],
  [/^(chefe|patrao|patroa|gerente|diretor|supervisor|capitao|comandante)/, 'chefe'],
  [/^(rival|inimig|nemesis)/, 'rival'],
  [/^(tio|tia|primo|prima|avo|avô|sobrinh|cunhad|sogr|neto|neta|parente)/, 'parente'],
];

/** Sugere o tipo de vínculo a partir do texto livre ("irmão" → irmao). */
export function guessRelationKind(label: string): RelationKind | null {
  const f = fold(label);
  if (!f) return null;
  return GUESSES.find(([re]) => re.test(f))?.[1] ?? null;
}
