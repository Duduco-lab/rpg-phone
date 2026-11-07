import { createClient, type AuthError, type PostgrestError, type SupabaseClient } from '@supabase/supabase-js';
import type { CharacterId, CharacterProfile } from '../../domain/character';
import type { CircleMember } from '../../domain/circle';
import type { EmailDraft, MailboxSnapshot } from '../../domain/email';
import {
  BackendError,
  type AccountClient,
  type AccountSession,
  type CircleClient,
  type DataBackend,
  type MailboxClient,
  type SocialClient,
  type SocialFeed,
} from '../backend';

/**
 * Implementação real do contrato de dados sobre o Supabase.
 *
 * Usa SOMENTE a chave pública (anon). Todas as escritas passam por funções
 * RPC que validam, no banco, se o usuário autenticado controla o personagem
 * (ver supabase/migrations/0001_schema.sql). O ID do personagem enviado aqui
 * é apenas uma indicação — o servidor confere a posse antes de agir.
 */

const NPC_TICK_INTERVAL_MS = 60_000;

const AUTH_MESSAGES: [RegExp, string][] = [
  [/invalid login credentials/i, 'E-mail ou senha incorretos.'],
  [/already registered|already exists/i, 'Este e-mail já está cadastrado.'],
  [/password should be at least/i, 'A senha precisa ter pelo menos 6 caracteres.'],
  [/email not confirmed/i, 'Confirme seu e-mail antes de entrar (veja sua caixa de entrada).'],
  [/unable to validate email|invalid email/i, 'E-mail inválido.'],
  [/rate limit|too many/i, 'Muitas tentativas. Aguarde um pouco e tente de novo.'],
  [/failed to fetch|network/i, 'Sem conexão com o servidor.'],
];

function authError(error: AuthError): BackendError {
  const hit = AUTH_MESSAGES.find(([re]) => re.test(error.message));
  return new BackendError(error.code ?? 'auth_error', hit ? hit[1] : error.message);
}

function dbError(error: PostgrestError): BackendError {
  if (/failed to fetch|network/i.test(error.message)) return new BackendError('network', 'Sem conexão com o servidor.');
  if (error.code === '42501' && /permission denied/i.test(error.message)) {
    return new BackendError('forbidden', 'Sessão expirada. Entre novamente.');
  }
  return new BackendError(error.code || 'db_error', error.message);
}

const iso = (value: string) => new Date(value).toISOString();

function normalizeSnapshot(raw: MailboxSnapshot): MailboxSnapshot {
  return {
    ...raw,
    messages: raw.messages.map((m) => ({ ...m, sentAt: iso(m.sentAt) })),
    drafts: raw.drafts.map((d) => ({ ...d, updatedAt: iso(d.updatedAt) })),
  };
}

export function createSupabaseBackend(url: string, anonKey: string): DataBackend {
  const sb: SupabaseClient = createClient(url, anonKey, {
    auth: { persistSession: true, autoRefreshToken: true },
  });

  async function rpc<T>(fn: string, args?: Record<string, unknown>): Promise<T> {
    const { data, error } = await sb.rpc(fn, args);
    if (error) throw dbError(error);
    return data as T;
  }

  const toSession = (s: { user: { id: string; email?: string } } | null): AccountSession | null =>
    s ? { userId: s.user.id, email: s.user.email ?? '' } : null;

  const account: AccountClient = {
    async getSession() {
      const { data, error } = await sb.auth.getSession();
      if (error) throw authError(error);
      return toSession(data.session);
    },
    onSessionChange(listener) {
      const { data } = sb.auth.onAuthStateChange((_event, session) => listener(toSession(session)));
      return () => data.subscription.unsubscribe();
    },
    async signIn(email, password) {
      const { error } = await sb.auth.signInWithPassword({ email: email.trim(), password });
      if (error) throw authError(error);
    },
    async signUp(email, password, displayName) {
      const { data, error } = await sb.auth.signUp({
        email: email.trim(),
        password,
        options: { data: { display_name: displayName.trim() } },
      });
      if (error) throw authError(error);
      return data.session !== null;
    },
    async signOut() {
      const { error } = await sb.auth.signOut();
      if (error) throw authError(error);
    },
    myCharacters: () => rpc<CharacterProfile[]>('my_characters'),
    createCharacter: (input) =>
      rpc<CharacterProfile>('create_character', {
        p_first_name: input.firstName,
        p_last_name: input.lastName,
        p_description: input.description,
        p_avatar_color: input.avatarColor,
        p_email: input.email.trim() || null,
        p_gender: input.gender,
        p_country: input.countryCode,
        p_title: input.title.trim(),
      }),
    updateCharacter: (id, input) =>
      rpc<CharacterProfile>('update_character', {
        p_character: id,
        p_first_name: input.firstName,
        p_last_name: input.lastName,
        p_description: input.description,
        p_avatar_color: input.avatarColor,
        p_email: input.email.trim() || null,
        p_gender: input.gender,
        p_country: input.countryCode,
        p_title: input.title.trim(),
      }),
    claimNpc: (code) => rpc<CharacterProfile>('claim_npc', { p_code: code }),
  };

  const circle: CircleClient = {
    list: (characterId) => rpc<CircleMember[]>('get_circle', { p_character: characterId }),
    async add(characterId, input) {
      await rpc('add_circle_member', {
        p_character: characterId,
        p_relation_label: input.relationLabel,
        p_relation_kind: input.relationKind,
        p_existing_character: input.existingCharacterId,
        p_first_name: input.firstName,
        p_last_name: input.lastName,
        p_description: input.description,
        p_gender: input.gender,
      });
    },
    async remove(characterId, memberId) {
      await rpc('remove_circle_member', { p_character: characterId, p_relationship: memberId });
    },
  };

  const social: SocialClient = {
    async feed(characterId, tab) {
      const data = await rpc<SocialFeed>('get_feed', { p_character: characterId, p_tab: tab });
      return { ...data, posts: data.posts.map((p) => ({ ...p, createdAt: iso(p.createdAt) })) };
    },
  };

  const mailboxes = new Map<CharacterId, MailboxClient>();

  const mailboxFor = (characterId: CharacterId): MailboxClient => {
    const cached = mailboxes.get(characterId);
    if (cached) return cached;
    const client: MailboxClient = {
      characterId,
      load: async () => normalizeSnapshot(await rpc<MailboxSnapshot>('get_mailbox', { p_character: characterId })),
      send: async (input) => {
        await rpc<string>('send_email', {
          p_sender: characterId,
          p_to: input.to,
          p_subject: input.subject,
          p_body: input.body,
          p_conversation: input.conversationId,
          p_in_reply_to: input.inReplyToId,
          p_draft: input.draftId,
        });
        // O Realtime avisa a interface; o retorno detalhado não é necessário.
        return {
          id: '',
          conversationId: input.conversationId ?? '',
          from: '',
          to: input.to,
          subject: input.subject,
          body: input.body,
          sentAt: new Date().toISOString(),
          inReplyToId: input.inReplyToId,
        };
      },
      saveDraft: async (input) => {
        const d = await rpc<EmailDraft>('save_draft', {
          p_character: characterId,
          p_id: input.id,
          p_to: input.to,
          p_subject: input.subject,
          p_body: input.body,
          p_conversation: input.conversationId,
          p_in_reply_to: input.inReplyToId,
        });
        return { ...d, updatedAt: iso(d.updatedAt) };
      },
      deleteDraft: async (id) => {
        await rpc('delete_draft', { p_character: characterId, p_id: id });
      },
      updateConversation: async (conversationId, patch) => {
        await rpc('update_conversation_state', {
          p_character: characterId,
          p_conversation: conversationId,
          p_is_read: patch.isRead ?? null,
          p_is_important: patch.isImportant ?? null,
          p_is_archived: patch.isArchived ?? null,
          p_is_trashed: patch.isTrashed ?? null,
        });
      },
      deleteConversationForever: async (conversationId) => {
        await rpc('delete_conversation_forever', { p_character: characterId, p_conversation: conversationId });
      },
      subscribe(listener) {
        // Mudanças na caixa deste personagem (RLS garante que só chegam as dele).
        const channel = sb
          .channel(`mailbox:${characterId}`)
          .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'mailbox_entries', filter: `character_id=eq.${characterId}` },
            (payload) => {
              const row = payload.new as { email_id?: string; is_read?: boolean } | undefined;
              if (payload.eventType === 'INSERT' && row?.email_id && row.is_read === false) {
                listener({ type: 'received', messageId: row.email_id });
              } else {
                listener({ type: 'changed' });
              }
            },
          )
          .subscribe();

        // Relógio dos NPCs para quando o pg_cron não estiver habilitado (idempotente no servidor).
        const tick = window.setInterval(() => {
          void sb.rpc('npc_tick');
        }, NPC_TICK_INTERVAL_MS);

        return () => {
          window.clearInterval(tick);
          void sb.removeChannel(channel);
        };
      },
    };
    mailboxes.set(characterId, client);
    return client;
  };

  return {
    kind: 'supabase',
    label: 'Supabase — dados persistentes',
    directory: { listCharacters: () => rpc<CharacterProfile[]>('list_directory') },
    mailboxFor,
    account,
    circle,
    social,
  };
}
