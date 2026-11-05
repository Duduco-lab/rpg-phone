-- =====================================================================
-- RPG Phone — schema inicial
-- Execute no SQL Editor do Supabase (ou via `supabase db push`).
--
-- Princípios:
--  * Toda escrita passa por funções RPC (SECURITY DEFINER) que validam
--    que o usuário autenticado é dono do personagem. Não há políticas de
--    INSERT/UPDATE/DELETE nas tabelas: o frontend não escreve direto.
--  * Leituras diretas são limitadas por RLS ao que o personagem pode ver.
--  * Funções internas ficam no schema `private` (não exposto pela API).
-- =====================================================================

create schema if not exists private;
revoke all on schema private from public;

-- ------------------------------------------------------------- tipos
do $$ begin
  create type public.character_kind as enum ('player', 'npc');
exception when duplicate_object then null; end $$;

-- O que o NPC/personagem relacionado É para o dono do círculo.
do $$ begin
  create type public.relation_kind as enum (
    'pai_mae', 'filho', 'irmao', 'parceiro', 'ex', 'amigo',
    'colega', 'chefe', 'rival', 'parente', 'outro'
  );
exception when duplicate_object then null; end $$;

-- ----------------------------------------------------------- users
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 60),
  is_master boolean not null default false,
  created_at timestamptz not null default now()
);

create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, left(coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), ''), 60))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ------------------------------------------------------ characters
create table public.characters (
  id uuid primary key default gen_random_uuid(),
  kind public.character_kind not null default 'player',
  owner_user_id uuid references public.profiles (id) on delete set null,
  -- Para NPCs: personagem em cujo círculo o NPC foi criado.
  created_by_character_id uuid references public.characters (id) on delete set null,
  first_name text not null check (char_length(btrim(first_name)) between 1 and 40),
  last_name text not null default '' check (char_length(last_name) <= 60),
  description text not null default '' check (char_length(description) <= 600),
  email text not null unique check (email = lower(email)),
  phone_number text not null,
  avatar_url text check (avatar_url is null or char_length(avatar_url) <= 500),
  avatar_color text not null default '#5b6ee1' check (avatar_color ~ '^#[0-9a-fA-F]{6}$'),
  active boolean not null default true,
  -- Código para um jogador assumir este NPC (null para personagens de jogadores).
  claim_code text unique,
  created_at timestamptz not null default now(),
  constraint player_has_owner check (kind = 'npc' or owner_user_id is not null)
);
create index characters_owner_idx on public.characters (owner_user_id);
create index characters_created_by_idx on public.characters (created_by_character_id);

-- Círculo: "related É <relation_label> de character".
create table public.character_relationships (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters (id) on delete cascade,
  related_character_id uuid not null references public.characters (id) on delete cascade,
  relation_label text not null check (char_length(btrim(relation_label)) between 1 and 40),
  relation_kind public.relation_kind not null default 'outro',
  -- Próximo e-mail espontâneo do NPC (null = sem simulação).
  next_spontaneous_at timestamptz,
  created_at timestamptz not null default now(),
  unique (character_id, related_character_id),
  check (character_id <> related_character_id)
);
create index relationships_related_idx on public.character_relationships (related_character_id);
create index relationships_spontaneous_idx on public.character_relationships (next_spontaneous_at)
  where next_spontaneous_at is not null;

-- ----------------------------------------------------------- e-mail
create table public.email_conversations (
  id uuid primary key default gen_random_uuid(),
  subject text not null check (char_length(subject) <= 200),
  created_at timestamptz not null default now()
);

create table public.email_conversation_members (
  conversation_id uuid not null references public.email_conversations (id) on delete cascade,
  character_id uuid not null references public.characters (id) on delete cascade,
  primary key (conversation_id, character_id)
);
create index conversation_members_character_idx on public.email_conversation_members (character_id);

create table public.emails (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.email_conversations (id) on delete cascade,
  sender_character_id uuid not null references public.characters (id) on delete cascade,
  subject text not null check (char_length(subject) <= 200),
  body text not null check (char_length(body) <= 20000),
  sent_at timestamptz not null default now(),
  in_reply_to_id uuid references public.emails (id) on delete set null
);
create index emails_conversation_idx on public.emails (conversation_id, sent_at);
create index emails_sender_idx on public.emails (sender_character_id, sent_at);

create table public.email_recipients (
  email_id uuid not null references public.emails (id) on delete cascade,
  character_id uuid not null references public.characters (id) on delete cascade,
  primary key (email_id, character_id)
);
create index email_recipients_character_idx on public.email_recipients (character_id);

-- Estado de cada mensagem na caixa de cada personagem (o "email_labels").
create table public.mailbox_entries (
  character_id uuid not null references public.characters (id) on delete cascade,
  email_id uuid not null references public.emails (id) on delete cascade,
  is_read boolean not null default false,
  is_important boolean not null default false,
  is_archived boolean not null default false,
  is_trashed boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (character_id, email_id)
);
create index mailbox_entries_email_idx on public.mailbox_entries (email_id);

create table public.email_drafts (
  id uuid primary key default gen_random_uuid(),
  owner_character_id uuid not null references public.characters (id) on delete cascade,
  conversation_id uuid references public.email_conversations (id) on delete set null,
  in_reply_to_id uuid references public.emails (id) on delete set null,
  to_addresses text[] not null default '{}' check (cardinality(to_addresses) <= 20),
  subject text not null default '' check (char_length(subject) <= 200),
  body text not null default '' check (char_length(body) <= 20000),
  updated_at timestamptz not null default now()
);
create index email_drafts_owner_idx on public.email_drafts (owner_character_id);

-- Reservada para anexos (Storage) — ainda sem interface.
create table public.email_attachments (
  id uuid primary key default gen_random_uuid(),
  email_id uuid not null references public.emails (id) on delete cascade,
  storage_path text not null,
  file_name text not null,
  mime_type text not null,
  size_bytes integer not null check (size_bytes >= 0),
  created_at timestamptz not null default now()
);
create index email_attachments_email_idx on public.email_attachments (email_id);

-- --------------------------------------------------------- NPCs
create table public.npc_templates (
  id serial primary key,
  relation_kind public.relation_kind not null,
  purpose text not null check (purpose in ('spontaneous', 'reply')),
  subject text not null default '',
  body text not null
);
create index npc_templates_lookup_idx on public.npc_templates (relation_kind, purpose);

create table public.npc_outbox (
  id uuid primary key default gen_random_uuid(),
  npc_character_id uuid not null references public.characters (id) on delete cascade,
  to_character_id uuid not null references public.characters (id) on delete cascade,
  conversation_id uuid references public.email_conversations (id) on delete cascade,
  in_reply_to_id uuid references public.emails (id) on delete set null,
  template_id integer references public.npc_templates (id) on delete set null,
  purpose text not null check (purpose in ('spontaneous', 'reply')),
  subject text not null,
  body text not null,
  deliver_at timestamptz not null,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);
create index npc_outbox_due_idx on public.npc_outbox (deliver_at) where delivered_at is null;
create index npc_outbox_pair_idx on public.npc_outbox (npc_character_id, to_character_id);

-- ------------------------------------------------- admin / auditoria
create table public.server_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

insert into public.server_settings (key, value) values
  ('npc_reply_delay_minutes', '{"min": 2, "max": 12}'),
  ('npc_spontaneous_interval_hours', '{"min": 10, "max": 36}'),
  ('max_characters_per_user', '5'),
  ('max_circle_size', '30');

create table public.audit_logs (
  id bigserial primary key,
  actor_user_id uuid references public.profiles (id) on delete set null,
  action text not null,
  target_type text,
  target_id uuid,
  details jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index audit_logs_created_idx on public.audit_logs (created_at desc);

-- =====================================================================
-- Funções internas (schema private)
-- =====================================================================

create function private.setting_int(p_key text, p_default integer) returns integer
language sql stable security definer set search_path = public as $$
  select coalesce((select (value #>> '{}')::integer from public.server_settings where key = p_key), p_default)
$$;

-- Intervalo aleatório a partir de uma configuração {"min": x, "max": y}.
create function private.random_interval(p_key text, p_unit text) returns interval
language plpgsql volatile security definer set search_path = public as $$
declare
  v jsonb;
  lo numeric;
  hi numeric;
begin
  select value into v from public.server_settings where key = p_key;
  lo := coalesce((v ->> 'min')::numeric, 1);
  hi := greatest(coalesce((v ->> 'max')::numeric, lo), lo);
  return make_interval(secs => ((lo + random() * (hi - lo)) * case p_unit when 'hours' then 3600 else 60 end)::double precision);
end $$;

create function private.audit(p_action text, p_target_type text, p_target_id uuid, p_details jsonb default '{}')
returns void language sql security definer set search_path = public as $$
  insert into public.audit_logs (actor_user_id, action, target_type, target_id, details)
  values (auth.uid(), p_action, p_target_type, p_target_id, coalesce(p_details, '{}'))
$$;

-- O usuário autenticado controla este personagem de jogador ativo?
create function private.owns_character(p_character uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.characters
    where id = p_character and owner_user_id = auth.uid() and kind = 'player' and active
  )
$$;

create function private.require_owner(p_character uuid) returns void
language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Faça login para continuar.' using errcode = '28000';
  end if;
  if not private.owns_character(p_character) then
    raise exception 'Você não controla este personagem.' using errcode = '42501';
  end if;
end $$;

create function private.slugify(p_text text) returns text
language sql immutable as $$
  select btrim(
    regexp_replace(
      lower(translate(p_text,
        'áàâãäåéèêëíìîïóòôõöúùûüçñýÁÀÂÃÄÅÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑÝ',
        'aaaaaaeeeeiiiiooooouuuucnyaaaaaaeeeeiiiiooooouuuucny')),
      '[^a-z0-9]+', '.', 'g'),
    '.')
$$;

create function private.generate_email(p_first text, p_last text) returns text
language plpgsql volatile security definer set search_path = public as $$
declare
  base text := left(coalesce(nullif(private.slugify(p_first || ' ' || p_last), ''), 'personagem'), 40);
  candidate text := base || '@rpgphone.app';
  n integer := 1;
begin
  while exists (select 1 from public.characters where email = candidate) loop
    n := n + 1;
    candidate := base || n || '@rpgphone.app';
  end loop;
  return candidate;
end $$;

create function private.generate_phone() returns text
language sql volatile as $$
  select '+55 (21) 9' || lpad(floor(random() * 10000)::text, 4, '0') || '-' || lpad(floor(random() * 10000)::text, 4, '0')
$$;

create function private.generate_claim_code() returns text
language sql volatile as $$
  select upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4) || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 4))
$$;

create function private.random_color() returns text
language sql volatile as $$
  select (array['#7b5cd6','#d1683c','#1f9b8a','#3a78c9','#c2457a','#5f6b7a','#2e9e8f','#c47f1a','#8a5cd6','#b8577f'])[1 + floor(random() * 10)::int]
$$;

-- JSON público de um personagem (sem dono, sem código de convite).
create function private.character_json(c public.characters) returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'firstName', c.first_name, 'lastName', c.last_name,
    'email', c.email, 'phoneNumber', c.phone_number, 'description', c.description,
    'avatarUrl', c.avatar_url, 'avatarColor', c.avatar_color, 'active', c.active
  )
$$;

-- Entrega efetiva de um e-mail (já validado por quem chama).
create function private.deliver_email(
  p_sender uuid, p_recipients uuid[], p_subject text, p_body text,
  p_conversation uuid, p_in_reply_to uuid
) returns uuid
language plpgsql volatile security definer set search_path = public as $$
declare
  v_conversation uuid := p_conversation;
  v_email uuid;
  v_sender_kind public.character_kind;
  r uuid;
begin
  if v_conversation is null then
    insert into public.email_conversations (subject) values (p_subject) returning id into v_conversation;
  end if;

  insert into public.emails (conversation_id, sender_character_id, subject, body, in_reply_to_id)
  values (v_conversation, p_sender, p_subject, p_body, p_in_reply_to)
  returning id into v_email;

  insert into public.email_conversation_members (conversation_id, character_id)
  select v_conversation, x from unnest(array_append(p_recipients, p_sender)) as x
  on conflict do nothing;

  insert into public.email_recipients (email_id, character_id)
  select v_email, x from unnest(p_recipients) as x
  on conflict do nothing;

  -- Remetente: aparece em Enviados, já lido.
  insert into public.mailbox_entries (character_id, email_id, is_read)
  values (p_sender, v_email, true)
  on conflict do nothing;

  insert into public.mailbox_entries (character_id, email_id, is_read)
  select x, v_email, false from unnest(p_recipients) as x where x <> p_sender
  on conflict do nothing;

  -- Jogador escrevendo para NPC → agenda resposta simulada.
  select kind into v_sender_kind from public.characters where id = p_sender;
  if v_sender_kind = 'player' then
    foreach r in array p_recipients loop
      if exists (select 1 from public.characters where id = r and kind = 'npc' and active)
         and not exists (
           select 1 from public.npc_outbox
           where npc_character_id = r and to_character_id = p_sender
             and conversation_id = v_conversation and delivered_at is null
         ) then
        perform private.enqueue_npc_message(r, p_sender, 'reply', v_conversation, v_email,
          now() + private.random_interval('npc_reply_delay_minutes', 'minutes'));
      end if;
    end loop;
  end if;

  return v_email;
end $$;

-- Escolhe um modelo (preferindo os menos usados com este jogador), preenche e agenda.
create function private.enqueue_npc_message(
  p_npc uuid, p_player uuid, p_purpose text,
  p_conversation uuid, p_in_reply_to uuid, p_deliver_at timestamptz
) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  v_kind public.relation_kind := 'outro';
  v_label text := 'conhecido(a)';
  v_npc public.characters;
  v_player public.characters;
  v_tpl public.npc_templates;
  v_subject text;
  v_body text;
begin
  select * into v_npc from public.characters where id = p_npc;
  select * into v_player from public.characters where id = p_player;
  if v_npc.id is null or v_player.id is null then return; end if;

  select relation_kind, relation_label into v_kind, v_label
  from public.character_relationships
  where character_id = p_player and related_character_id = p_npc;
  v_kind := coalesce(v_kind, 'outro');
  v_label := coalesce(v_label, 'conhecido(a)');

  select t.* into v_tpl
  from public.npc_templates t
  where t.purpose = p_purpose and t.relation_kind in (v_kind, 'outro')
  order by
    (t.relation_kind = v_kind) desc,
    (select count(*) from public.npc_outbox o
      where o.template_id = t.id and o.npc_character_id = p_npc and o.to_character_id = p_player),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_body := replace(replace(replace(v_tpl.body,
    '{jogador}', v_player.first_name),
    '{npc}', v_npc.first_name),
    '{relacao}', v_label);

  if p_purpose = 'reply' and p_conversation is not null then
    select 'Re: ' || regexp_replace(subject, '^((re|fwd?|enc)\s*:\s*)+', '', 'i') into v_subject
    from public.email_conversations where id = p_conversation;
  else
    v_subject := replace(replace(v_tpl.subject, '{jogador}', v_player.first_name), '{npc}', v_npc.first_name);
  end if;

  insert into public.npc_outbox (npc_character_id, to_character_id, conversation_id, in_reply_to_id,
    template_id, purpose, subject, body, deliver_at)
  values (p_npc, p_player, p_conversation, p_in_reply_to, v_tpl.id, p_purpose,
    left(coalesce(v_subject, '(sem assunto)'), 200), v_body, p_deliver_at);
end $$;

-- =====================================================================
-- RPCs públicas (chamadas pelo frontend)
-- =====================================================================

-- Executa o "relógio" dos NPCs: agenda espontâneos vencidos e entrega o que estiver na hora.
-- Idempotente e seguro de chamar com frequência (pg_cron e/ou clientes abertos).
create function public.npc_tick() returns integer
language plpgsql volatile security definer set search_path = public as $$
declare
  r record;
  delivered integer := 0;
begin
  if not pg_try_advisory_xact_lock(hashtext('rpgphone.npc_tick')) then
    return 0;
  end if;

  for r in
    select cr.id, cr.character_id, cr.related_character_id
    from public.character_relationships cr
    join public.characters npc on npc.id = cr.related_character_id and npc.kind = 'npc' and npc.active
    join public.characters pc on pc.id = cr.character_id and pc.kind = 'player' and pc.active
    where cr.next_spontaneous_at is not null and cr.next_spontaneous_at <= now()
    limit 200
  loop
    -- Não acumula: se o jogador já tem 2+ e-mails não lidos deste NPC, só reagenda.
    if (select count(*) from public.mailbox_entries m
        join public.emails e on e.id = m.email_id
        where m.character_id = r.character_id and not m.is_read and not m.is_trashed
          and e.sender_character_id = r.related_character_id) < 2 then
      perform private.enqueue_npc_message(r.related_character_id, r.character_id, 'spontaneous', null, null, now());
    end if;
    update public.character_relationships
      set next_spontaneous_at = now() + private.random_interval('npc_spontaneous_interval_hours', 'hours')
      where id = r.id;
  end loop;

  for r in
    select o.* from public.npc_outbox o
    where o.delivered_at is null and o.deliver_at <= now()
    order by o.deliver_at
    limit 200
  loop
    if exists (select 1 from public.characters where id = r.npc_character_id and kind = 'npc' and active)
       and exists (select 1 from public.characters where id = r.to_character_id and active) then
      perform private.deliver_email(r.npc_character_id, array[r.to_character_id], r.subject, r.body,
        r.conversation_id, r.in_reply_to_id);
      delivered := delivered + 1;
    end if;
    update public.npc_outbox set delivered_at = now() where id = r.id;
  end loop;

  return delivered;
end $$;

-- Personagens do usuário autenticado.
create function public.my_characters() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(private.character_json(c) order by c.created_at), '[]')
  from public.characters c
  where c.owner_user_id = auth.uid() and c.kind = 'player' and c.active
$$;

-- Diretório público (personagens e NPCs ativos).
create function public.list_directory() returns jsonb
language sql stable security definer set search_path = public as $$
  select case when auth.uid() is null then '[]'::jsonb else
    coalesce((select jsonb_agg(private.character_json(c) order by c.first_name, c.last_name)
              from public.characters c where c.active), '[]') end
$$;

create function public.create_character(
  p_first_name text, p_last_name text, p_description text default '', p_avatar_color text default null
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v public.characters;
begin
  if auth.uid() is null then raise exception 'Faça login para continuar.' using errcode = '28000'; end if;
  if (select count(*) from public.characters where owner_user_id = auth.uid() and kind = 'player' and active)
     >= private.setting_int('max_characters_per_user', 5) then
    raise exception 'Você atingiu o limite de personagens.' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_first_name, ''))) = 0 then
    raise exception 'Informe o nome do personagem.' using errcode = '22023';
  end if;

  insert into public.characters (kind, owner_user_id, first_name, last_name, description, email, phone_number, avatar_color)
  values ('player', auth.uid(), btrim(p_first_name), btrim(coalesce(p_last_name, '')), btrim(coalesce(p_description, '')),
    private.generate_email(p_first_name, coalesce(p_last_name, '')), private.generate_phone(),
    coalesce(nullif(p_avatar_color, ''), private.random_color()))
  returning * into v;

  perform private.audit('character.create', 'character', v.id);
  return private.character_json(v);
end $$;

-- Assume um NPC usando o código de convite (o NPC vira personagem do jogador, mantendo o histórico).
create function public.claim_npc(p_code text) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v public.characters;
begin
  if auth.uid() is null then raise exception 'Faça login para continuar.' using errcode = '28000'; end if;
  if (select count(*) from public.characters where owner_user_id = auth.uid() and kind = 'player' and active)
     >= private.setting_int('max_characters_per_user', 5) then
    raise exception 'Você atingiu o limite de personagens.' using errcode = 'P0001';
  end if;

  update public.characters
    set kind = 'player', owner_user_id = auth.uid(), claim_code = null
    where claim_code = upper(btrim(p_code)) and kind = 'npc' and active
    returning * into v;
  if v.id is null then
    raise exception 'Código inválido ou já utilizado.' using errcode = 'P0002';
  end if;

  -- Para de simular: agora há um jogador de verdade.
  update public.character_relationships set next_spontaneous_at = null where related_character_id = v.id;
  delete from public.npc_outbox where npc_character_id = v.id and delivered_at is null;

  perform private.audit('character.claim_npc', 'character', v.id);
  return private.character_json(v);
end $$;

-- Círculo do personagem (inclui o código de convite dos NPCs que ele criou).
create function public.get_circle(p_character uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  perform private.require_owner(p_character);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', cr.id,
      'relationLabel', cr.relation_label,
      'relationKind', cr.relation_kind,
      'character', private.character_json(c),
      'isNpc', c.kind = 'npc',
      'claimCode', case when c.kind = 'npc' and c.created_by_character_id = p_character then c.claim_code end
    ) order by cr.created_at)
    from public.character_relationships cr
    join public.characters c on c.id = cr.related_character_id
    where cr.character_id = p_character and c.active
  ), '[]');
end $$;

-- Adiciona alguém ao círculo: um personagem existente OU um NPC novo.
create function public.add_circle_member(
  p_character uuid,
  p_relation_label text,
  p_relation_kind public.relation_kind,
  p_existing_character uuid default null,
  p_first_name text default null,
  p_last_name text default null,
  p_description text default ''
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v_related public.characters;
  v_rel uuid;
begin
  perform private.require_owner(p_character);
  if (select count(*) from public.character_relationships where character_id = p_character)
     >= private.setting_int('max_circle_size', 30) then
    raise exception 'O círculo atingiu o limite de pessoas.' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_relation_label, ''))) = 0 then
    raise exception 'Informe a relação (ex.: irmão, marido).' using errcode = '22023';
  end if;

  if p_existing_character is not null then
    select * into v_related from public.characters where id = p_existing_character and active;
    if v_related.id is null then
      raise exception 'Personagem não encontrado.' using errcode = 'P0002';
    end if;
  else
    if char_length(btrim(coalesce(p_first_name, ''))) = 0 then
      raise exception 'Informe o nome da pessoa.' using errcode = '22023';
    end if;
    insert into public.characters (kind, created_by_character_id, first_name, last_name, description,
      email, phone_number, avatar_color, claim_code)
    values ('npc', p_character, btrim(p_first_name), btrim(coalesce(p_last_name, '')), btrim(coalesce(p_description, '')),
      private.generate_email(p_first_name, coalesce(p_last_name, '')), private.generate_phone(),
      private.random_color(), private.generate_claim_code())
    returning * into v_related;
  end if;

  if v_related.id = p_character then
    raise exception 'Um personagem não pode estar no próprio círculo.' using errcode = '22023';
  end if;

  insert into public.character_relationships (character_id, related_character_id, relation_label, relation_kind, next_spontaneous_at)
  values (p_character, v_related.id, btrim(p_relation_label), p_relation_kind,
    case when v_related.kind = 'npc'
      then now() + private.random_interval('npc_spontaneous_interval_hours', 'hours') end)
  on conflict (character_id, related_character_id) do update
    set relation_label = excluded.relation_label, relation_kind = excluded.relation_kind
  returning id into v_rel;

  perform private.audit('circle.add', 'character', v_related.id,
    jsonb_build_object('owner', p_character, 'label', p_relation_label, 'npc', v_related.kind = 'npc'));
  return jsonb_build_object('relationshipId', v_rel, 'character', private.character_json(v_related));
end $$;

create function public.remove_circle_member(p_character uuid, p_relationship uuid) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  v_related uuid;
begin
  perform private.require_owner(p_character);
  delete from public.character_relationships
    where id = p_relationship and character_id = p_character
    returning related_character_id into v_related;
  if v_related is null then
    raise exception 'Pessoa não encontrada no círculo.' using errcode = 'P0002';
  end if;

  -- NPC criado por este personagem e sem outros vínculos: desativa (o histórico permanece).
  update public.characters c set active = false, claim_code = null
    where c.id = v_related and c.kind = 'npc' and c.created_by_character_id = p_character
      and not exists (select 1 from public.character_relationships where related_character_id = c.id);
  delete from public.npc_outbox where npc_character_id = v_related and to_character_id = p_character and delivered_at is null;

  perform private.audit('circle.remove', 'character', v_related, jsonb_build_object('owner', p_character));
end $$;

-- Caixa postal completa do personagem (formato consumido pelo frontend).
create function public.get_mailbox(p_character uuid) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v public.characters;
begin
  perform private.require_owner(p_character);
  perform public.npc_tick();
  select * into v from public.characters where id = p_character;

  return jsonb_build_object(
    'ownerId', v.id,
    'ownerAddress', v.email,
    'messages', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id,
        'conversationId', e.conversation_id,
        'from', s.email,
        'to', (select coalesce(jsonb_agg(rc.email order by rc.email), '[]')
               from public.email_recipients r join public.characters rc on rc.id = r.character_id
               where r.email_id = e.id),
        'subject', e.subject,
        'body', e.body,
        'sentAt', e.sent_at,
        'inReplyToId', e.in_reply_to_id
      ) order by e.sent_at)
      from public.mailbox_entries m
      join public.emails e on e.id = m.email_id
      join public.characters s on s.id = e.sender_character_id
      where m.character_id = p_character), '[]'),
    'entries', coalesce((
      select jsonb_object_agg(m.email_id, jsonb_build_object(
        'messageId', m.email_id, 'isRead', m.is_read, 'isImportant', m.is_important,
        'isArchived', m.is_archived, 'isTrashed', m.is_trashed))
      from public.mailbox_entries m where m.character_id = p_character), '{}'),
    'drafts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', d.id, 'conversationId', d.conversation_id, 'inReplyToId', d.in_reply_to_id,
        'to', to_jsonb(d.to_addresses), 'subject', d.subject, 'body', d.body, 'updatedAt', d.updated_at
      ) order by d.updated_at desc)
      from public.email_drafts d where d.owner_character_id = p_character), '[]')
  );
end $$;

create function public.send_email(
  p_sender uuid, p_to text[], p_subject text, p_body text,
  p_conversation uuid default null, p_in_reply_to uuid default null, p_draft uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = public as $$
declare
  v_addresses text[];
  v_recipients uuid[];
  v_unknown text[];
  v_subject text := btrim(coalesce(p_subject, ''));
  v_body text := rtrim(coalesce(p_body, ''));
  v_in_reply_to uuid := p_in_reply_to;
  v_email uuid;
begin
  perform private.require_owner(p_sender);

  select coalesce(array_agg(distinct lower(btrim(a))), '{}') into v_addresses
  from unnest(coalesce(p_to, '{}')) as a where btrim(a) <> '';

  if cardinality(v_addresses) = 0 then
    raise exception 'Adicione pelo menos um destinatário.' using errcode = '22023';
  end if;
  if cardinality(v_addresses) > 20 then
    raise exception 'Máximo de 20 destinatários por e-mail.' using errcode = '22023';
  end if;
  if v_subject = '' and btrim(v_body) = '' then
    raise exception 'Escreva um assunto ou uma mensagem antes de enviar.' using errcode = '22023';
  end if;

  select array_agg(a) into v_unknown from unnest(v_addresses) as a
  where not exists (select 1 from public.characters c where c.email = a and c.active);
  if v_unknown is not null then
    raise exception 'Endereço não encontrado: %', array_to_string(v_unknown, ', ') using errcode = 'P0002';
  end if;

  select array_agg(c.id) into v_recipients from public.characters c where c.email = any (v_addresses);

  -- Limite simples contra abuso.
  if (select count(*) from public.emails where sender_character_id = p_sender and sent_at > now() - interval '1 minute') >= 20 then
    raise exception 'Muitos e-mails em pouco tempo. Aguarde um instante.' using errcode = 'P0001';
  end if;

  if p_conversation is not null then
    if not exists (select 1 from public.email_conversation_members
                   where conversation_id = p_conversation and character_id = p_sender) then
      raise exception 'Você não participa desta conversa.' using errcode = '42501';
    end if;
    if v_in_reply_to is not null and not exists (
      select 1 from public.emails where id = v_in_reply_to and conversation_id = p_conversation) then
      v_in_reply_to := null;
    end if;
  else
    v_in_reply_to := null;
  end if;

  v_email := private.deliver_email(p_sender, v_recipients, coalesce(nullif(v_subject, ''), '(sem assunto)'),
    v_body, p_conversation, v_in_reply_to);

  if p_draft is not null then
    delete from public.email_drafts where id = p_draft and owner_character_id = p_sender;
  end if;
  return v_email;
end $$;

create function public.save_draft(
  p_character uuid, p_id uuid, p_to text[], p_subject text, p_body text,
  p_conversation uuid default null, p_in_reply_to uuid default null
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  d public.email_drafts;
begin
  perform private.require_owner(p_character);
  if p_conversation is not null and not exists (
    select 1 from public.email_conversation_members where conversation_id = p_conversation and character_id = p_character) then
    p_conversation := null;
    p_in_reply_to := null;
  end if;

  if p_id is null then
    insert into public.email_drafts (owner_character_id, conversation_id, in_reply_to_id, to_addresses, subject, body)
    values (p_character, p_conversation, p_in_reply_to,
      coalesce((select array_agg(lower(btrim(a))) from unnest(p_to) a where btrim(a) <> ''), '{}'),
      coalesce(p_subject, ''), coalesce(p_body, ''))
    returning * into d;
  else
    update public.email_drafts set
      to_addresses = coalesce((select array_agg(lower(btrim(a))) from unnest(p_to) a where btrim(a) <> ''), '{}'),
      subject = coalesce(p_subject, ''), body = coalesce(p_body, ''),
      conversation_id = p_conversation, in_reply_to_id = p_in_reply_to, updated_at = now()
    where id = p_id and owner_character_id = p_character
    returning * into d;
    if d.id is null then raise exception 'Rascunho não encontrado.' using errcode = 'P0002'; end if;
  end if;

  return jsonb_build_object('id', d.id, 'conversationId', d.conversation_id, 'inReplyToId', d.in_reply_to_id,
    'to', to_jsonb(d.to_addresses), 'subject', d.subject, 'body', d.body, 'updatedAt', d.updated_at);
end $$;

create function public.delete_draft(p_character uuid, p_id uuid) returns void
language plpgsql volatile security definer set search_path = public as $$
begin
  perform private.require_owner(p_character);
  delete from public.email_drafts where id = p_id and owner_character_id = p_character;
end $$;

create function public.update_conversation_state(
  p_character uuid, p_conversation uuid,
  p_is_read boolean default null, p_is_important boolean default null,
  p_is_archived boolean default null, p_is_trashed boolean default null
) returns void
language plpgsql volatile security definer set search_path = public as $$
begin
  perform private.require_owner(p_character);
  update public.mailbox_entries m set
    is_read = coalesce(p_is_read, m.is_read),
    is_important = coalesce(p_is_important, m.is_important),
    is_archived = coalesce(p_is_archived, m.is_archived),
    is_trashed = coalesce(p_is_trashed, m.is_trashed)
  where m.character_id = p_character
    and m.email_id in (select id from public.emails where conversation_id = p_conversation);
  if not found then
    raise exception 'Conversa não encontrada.' using errcode = 'P0002';
  end if;
end $$;

create function public.delete_conversation_forever(p_character uuid, p_conversation uuid) returns void
language plpgsql volatile security definer set search_path = public as $$
begin
  perform private.require_owner(p_character);
  delete from public.mailbox_entries m
  where m.character_id = p_character and m.is_trashed
    and m.email_id in (select id from public.emails where conversation_id = p_conversation);
end $$;

-- =====================================================================
-- Permissões e RLS
-- =====================================================================

alter table public.profiles enable row level security;
alter table public.characters enable row level security;
alter table public.character_relationships enable row level security;
alter table public.email_conversations enable row level security;
alter table public.email_conversation_members enable row level security;
alter table public.emails enable row level security;
alter table public.email_recipients enable row level security;
alter table public.mailbox_entries enable row level security;
alter table public.email_drafts enable row level security;
alter table public.email_attachments enable row level security;
alter table public.npc_templates enable row level security;
alter table public.npc_outbox enable row level security;
alter table public.server_settings enable row level security;
alter table public.audit_logs enable row level security;

-- Nada de acesso direto por padrão.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- Leituras diretas permitidas (somente SELECT, filtradas por RLS):
grant select on public.profiles to authenticated;
create policy profiles_self on public.profiles for select to authenticated using (id = auth.uid());

grant select on public.mailbox_entries to authenticated;  -- usado pelo Realtime
create policy mailbox_entries_owner on public.mailbox_entries for select to authenticated
  using (private.owns_character(character_id));

grant select on public.emails to authenticated;
create policy emails_visible on public.emails for select to authenticated
  using (exists (select 1 from public.mailbox_entries m
                 where m.email_id = emails.id and private.owns_character(m.character_id)));

grant select on public.email_drafts to authenticated;
create policy drafts_owner on public.email_drafts for select to authenticated
  using (private.owns_character(owner_character_id));

grant select on public.character_relationships to authenticated;
create policy relationships_owner on public.character_relationships for select to authenticated
  using (private.owns_character(character_id));

-- Funções: internas fechadas; RPCs só para usuários autenticados.
revoke all on all functions in schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.owns_character(uuid) to authenticated;  -- usada nas políticas

revoke all on function
  public.npc_tick(), public.my_characters(), public.list_directory(),
  public.create_character(text, text, text, text), public.claim_npc(text),
  public.get_circle(uuid),
  public.add_circle_member(uuid, text, public.relation_kind, uuid, text, text, text),
  public.remove_circle_member(uuid, uuid), public.get_mailbox(uuid),
  public.send_email(uuid, text[], text, text, uuid, uuid, uuid),
  public.save_draft(uuid, uuid, text[], text, text, uuid, uuid),
  public.delete_draft(uuid, uuid),
  public.update_conversation_state(uuid, uuid, boolean, boolean, boolean, boolean),
  public.delete_conversation_forever(uuid, uuid)
from public, anon;

grant execute on function
  public.npc_tick(), public.my_characters(), public.list_directory(),
  public.create_character(text, text, text, text), public.claim_npc(text),
  public.get_circle(uuid),
  public.add_circle_member(uuid, text, public.relation_kind, uuid, text, text, text),
  public.remove_circle_member(uuid, uuid), public.get_mailbox(uuid),
  public.send_email(uuid, text[], text, text, uuid, uuid, uuid),
  public.save_draft(uuid, uuid, text[], text, text, uuid, uuid),
  public.delete_draft(uuid, uuid),
  public.update_conversation_state(uuid, uuid, boolean, boolean, boolean, boolean),
  public.delete_conversation_forever(uuid, uuid)
to authenticated;

-- Realtime: avisa o cliente quando a caixa muda.
alter publication supabase_realtime add table public.mailbox_entries;
