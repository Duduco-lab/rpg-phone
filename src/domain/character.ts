export type CharacterId = string;

/** `player` = controlado por um jogador; `npc` = simulado pelo sistema. */
export type CharacterKind = 'player' | 'npc';

/** Perfil público de um personagem (o que outros personagens podem ver). */
export interface CharacterProfile {
  id: CharacterId;
  kind: CharacterKind;
  firstName: string;
  lastName: string;
  /** Endereço único gerado e administrado pelo sistema (ex.: nome@rpgphone.app). */
  email: string;
  /** Número telefônico fictício. */
  phoneNumber: string;
  description: string;
  avatarUrl: string | null;
  /** Cor de fundo do avatar quando não há imagem. */
  avatarColor: string;
  active: boolean;
}

export function fullName(c: Pick<CharacterProfile, 'firstName' | 'lastName'>): string {
  return `${c.firstName} ${c.lastName}`.trim();
}
