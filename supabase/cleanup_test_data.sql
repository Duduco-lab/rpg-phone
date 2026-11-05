-- =====================================================================
-- LIMPEZA DE DADOS DE TESTE — apaga TODOS os personagens, e-mails,
-- círculos e contas de jogadores. Mantém a estrutura, os modelos de NPC
-- e as configurações. Use só em ambiente de teste!
-- =====================================================================

begin;

truncate table
  public.npc_outbox,
  public.email_attachments,
  public.email_drafts,
  public.mailbox_entries,
  public.email_recipients,
  public.emails,
  public.email_conversation_members,
  public.email_conversations,
  public.character_relationships,
  public.characters,
  public.audit_logs
restart identity cascade;

-- Contas de login (os perfis são apagados em cascata).
delete from auth.users;

-- Volta os tempos dos NPCs ao padrão (caso tenham sido acelerados para teste).
update public.server_settings set value = '{"min": 2, "max": 12}' where key = 'npc_reply_delay_minutes';
update public.server_settings set value = '{"min": 10, "max": 36}' where key = 'npc_spontaneous_interval_hours';

commit;
