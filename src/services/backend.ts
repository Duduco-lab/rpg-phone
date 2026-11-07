import type { CharacterId, CharacterProfile, Gender } from '../domain/character';
import type { CircleMember, NewCircleMemberInput } from '../domain/circle';
import type {
  ConversationId,
  DraftInput,
  EmailDraft,
  EmailMessage,
  MailboxEntryPatch,
  MailboxEvent,
  MailboxSnapshot,
  SendEmailInput,
} from '../domain/email';

/**
 * Contratos da camada de acesso a dados.
 *
 * A interface (componentes) nunca fala diretamente com o armazenamento:
 * ela usa estes contratos. Na Fase 1 existe apenas a implementação em
 * memória (`services/demo`). Na Fase 2 uma implementação Supabase cumprirá
 * os mesmos contratos — e o personagem será derivado da sessão autenticada
 * no backend, nunca de um ID enviado livremente pelo frontend.
 */

export interface MailboxClient {
  readonly characterId: CharacterId;
  load(): Promise<MailboxSnapshot>;
  send(input: SendEmailInput): Promise<EmailMessage>;
  saveDraft(input: DraftInput): Promise<EmailDraft>;
  deleteDraft(draftId: string): Promise<void>;
  /** Aplica o patch a todas as mensagens da conversa na caixa deste personagem. */
  updateConversation(conversationId: ConversationId, patch: MailboxEntryPatch): Promise<void>;
  /** Remove definitivamente da caixa deste personagem (apenas itens na lixeira). */
  deleteConversationForever(conversationId: ConversationId): Promise<void>;
  subscribe(listener: (event: MailboxEvent) => void): () => void;
}

export interface DirectoryClient {
  listCharacters(): Promise<CharacterProfile[]>;
}

export interface AccountSession {
  userId: string;
  email: string;
}

export interface NewCharacterInput {
  firstName: string;
  lastName: string;
  description: string;
  avatarColor: string | null;
  /** E-mail do personagem escolhido pelo jogador. Vazio = gerado pelo sistema. */
  email: string;
  gender: Gender;
  countryCode: string | null;
  title: string;
}

export type FeedTab = 'para_voce' | 'sobre' | 'noticias';

export interface SocialPost {
  id: string;
  authorName: string;
  authorHandle: string;
  authorKind: 'pessoa' | 'fa' | 'fofoca' | 'imprensa';
  body: string;
  likes: number;
  reposts: number;
  replies: number;
  createdAt: string;
  category: string;
  aboutMe: boolean;
}

export interface SocialFeed {
  countryCode: string | null;
  posts: SocialPost[];
}

/** Rumor: rede social fictícia (posts gerados a partir do perfil e do círculo). */
export interface SocialClient {
  feed(characterId: CharacterId, tab: FeedTab): Promise<SocialFeed>;
}

/** Conta do jogador e personagens que ele controla (só existe com backend real). */
export interface AccountClient {
  getSession(): Promise<AccountSession | null>;
  onSessionChange(listener: (session: AccountSession | null) => void): () => void;
  signIn(email: string, password: string): Promise<void>;
  /** Retorna `true` se a conta já está ativa; `false` se exige confirmação por e-mail. */
  signUp(email: string, password: string, displayName: string): Promise<boolean>;
  signOut(): Promise<void>;
  myCharacters(): Promise<CharacterProfile[]>;
  createCharacter(input: NewCharacterInput): Promise<CharacterProfile>;
  /** Edita o perfil (e-mail vazio = mantém o atual). */
  updateCharacter(id: CharacterId, input: NewCharacterInput): Promise<CharacterProfile>;
  /** Assume um NPC a partir do código de convite. */
  claimNpc(code: string): Promise<CharacterProfile>;
}

/** Círculo social do personagem (família, amigos…) com NPCs simulados. */
export interface CircleClient {
  list(characterId: CharacterId): Promise<CircleMember[]>;
  add(characterId: CharacterId, input: NewCircleMemberInput): Promise<void>;
  remove(characterId: CharacterId, memberId: string): Promise<void>;
}

export interface DataBackend {
  kind: 'demo' | 'supabase';
  /** Descrição curta exibida na interface (ex.: "Demonstração — dados em memória"). */
  label: string;
  directory: DirectoryClient;
  mailboxFor(characterId: CharacterId): MailboxClient;
  /** Ausente no modo demonstração. */
  account?: AccountClient;
  /** Ausente no modo demonstração. */
  circle?: CircleClient;
  /** Ausente no modo demonstração. */
  social?: SocialClient;
}

export class BackendError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.name = 'BackendError';
    this.code = code;
  }
}

export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return 'Ocorreu um erro inesperado.';
}
