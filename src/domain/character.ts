export type CharacterId = string;

/** `player` = controlado por um jogador; `npc` = simulado pelo sistema. */
export type CharacterKind = 'player' | 'npc';

/** Usado para concordância nos textos ("ela", "a esposa", filhos chamando de "mãe"). */
export type Gender = 'm' | 'f' | 'n';

export const GENDER_LABELS: Record<Gender, string> = {
  m: 'Masculino',
  f: 'Feminino',
  n: 'Neutro / não informar',
};

/** Perfil público de um personagem (o que outros personagens podem ver). */
export interface CharacterProfile {
  id: CharacterId;
  kind: CharacterKind;
  firstName: string;
  lastName: string;
  /** Endereço do personagem dentro do jogo (escolhido pelo jogador ou gerado). */
  email: string;
  /** Número telefônico fictício. */
  phoneNumber: string;
  description: string;
  avatarUrl: string | null;
  /** Cor de fundo do avatar quando não há imagem. */
  avatarColor: string;
  active: boolean;
  gender: Gender;
  /** Nacionalidade (código de `domain/countries`). Define as notícias do Twixer. */
  countryCode: string | null;
  /** Título ou posição social (ex.: "Imperador germânico"). */
  title: string;
}

export function fullName(c: Pick<CharacterProfile, 'firstName' | 'lastName'>): string {
  return `${c.firstName} ${c.lastName}`.trim();
}
