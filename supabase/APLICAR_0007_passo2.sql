-- PASSO 2 de 2 — rode DEPOIS do passo 1 (0007a). Junta 0007b + 0007c + 0007d.

-- =====================================================================
-- Perfil: gênero, nacionalidade e título. Países do mundo do jogo.
-- =====================================================================

create table if not exists public.countries (
  code text primary key,
  name text not null,
  name_de text not null,   -- "da Itália", "dos Estados Unidos"
  name_em text not null,   -- "na Itália", "nos Estados Unidos"
  demonym_m text not null,
  demonym_f text not null,
  demonym_pl text not null,
  capital text not null,
  cities text[] not null,
  currency text not null,
  first_names text[] not null,
  last_names text[] not null,
  outlets text[] not null  -- veículos de imprensa FICTÍCIOS
);

insert into public.countries values
('IT','Itália','da Itália','na Itália','italiano','italiana','italianos','Roma',
  array['Milão','Florença','Veneza','Nápoles','Turim','Bolonha','Gênova','Palermo','Verona'],'lira',
  array['Giulia','Marco','Alessandro','Francesca','Lorenzo','Chiara','Matteo','Sofia','Luca','Valentina','Giovanni','Elena','Pietro','Bianca','Tommaso','Aurora'],
  array['Rossi','Romano','Colombo','Ricci','Marino','Greco','Bruno','Gallo','Conti','De Luca','Costa','Fontana','Esposito','Barbieri'],
  array['Cronaca di Roma','La Voce Italiana','Il Diario di Corte','Notizie del Regno']),
('DE','Alemanha','da Alemanha','na Alemanha','alemão','alemã','alemães','Berlim',
  array['Munique','Hamburgo','Colônia','Frankfurt','Dresden','Leipzig','Stuttgart','Heidelberg','Potsdam'],'marco',
  array['Lukas','Anna','Maximilian','Sophie','Felix','Marie','Leon','Hannah','Jonas','Emilia','Friedrich','Klara','Wilhelm','Greta'],
  array['Müller','Schmidt','Schneider','Fischer','Weber','Wagner','Becker','Hoffmann','Schäfer','Koch','Richter','Wolf','Neumann','Krüger'],
  array['Berliner Hofblatt','Kaiserliche Rundschau','Die Neue Chronik','Reichsbote Heute']),
('FR','França','da França','na França','francês','francesa','franceses','Paris',
  array['Lyon','Marselha','Bordeaux','Nice','Toulouse','Estrasburgo','Versalhes','Reims'],'franco',
  array['Louis','Camille','Hugo','Chloé','Antoine','Léa','Julien','Manon','Pierre','Inès','Gabriel','Margaux'],
  array['Martin','Bernard','Dubois','Moreau','Laurent','Lefèvre','Girard','Fontaine','Rousseau','Mercier','Blanc','Garnier'],
  array['Le Courrier de Paris','La Gazette de la Cour','L''Écho Royal']),
('GB','Reino Unido','do Reino Unido','no Reino Unido','britânico','britânica','britânicos','Londres',
  array['Manchester','Edimburgo','Liverpool','Oxford','Bath','York','Cambridge','Brighton'],'libra',
  array['Oliver','Charlotte','Henry','Amelia','George','Olivia','Arthur','Isla','William','Grace','Edward','Florence'],
  array['Smith','Jones','Taylor','Brown','Williams','Wilson','Davies','Evans','Thompson','Wright','Hughes','Ashford'],
  array['The Crown Courier','London Herald Daily','The Royal Observer']),
('ES','Espanha','da Espanha','na Espanha','espanhol','espanhola','espanhóis','Madri',
  array['Barcelona','Sevilha','Valência','Granada','Bilbao','Toledo','Salamanca','Málaga'],'peseta',
  array['Alejandro','Lucía','Pablo','María','Javier','Carmen','Diego','Sofía','Álvaro','Elena','Mateo','Paula'],
  array['García','Fernández','López','Martínez','Sánchez','Pérez','Gómez','Ruiz','Díaz','Moreno','Navarro','Torres'],
  array['Crónica de Madrid','La Voz de la Corte','El Heraldo del Reino']),
('PT','Portugal','de Portugal','em Portugal','português','portuguesa','portugueses','Lisboa',
  array['Coimbra','Braga','Évora','Faro','Sintra','Aveiro','Guimarães','Cascais'],'escudo',
  array['João','Inês','Tomás','Beatriz','Rodrigo','Leonor','Afonso','Matilde','Duarte','Carolina','Gonçalo','Mariana'],
  array['Silva','Santos','Ferreira','Pereira','Oliveira','Costa','Rodrigues','Martins','Sousa','Gomes','Lopes','Teixeira'],
  array['Diário da Corte','Gazeta do Reino','Notícias de Lisboa']),
('AT','Áustria','da Áustria','na Áustria','austríaco','austríaca','austríacos','Viena',
  array['Salzburgo','Innsbruck','Graz','Linz','Hallstatt','Klagenfurt'],'xelim',
  array['Elias','Lena','Paul','Johanna','Jakob','Valentina','Moritz','Theresa','Leopold','Katharina'],
  array['Gruber','Huber','Bauer','Wagner','Pichler','Steiner','Moser','Mayer','Hofer','Leitner'],
  array['Wiener Hofzeitung','Der Kaiserliche Bote','Donau Kurier']),
('RU','Rússia','da Rússia','na Rússia','russo','russa','russos','Moscou',
  array['São Petersburgo','Kazan','Novgorod','Sochi','Yekaterinburg','Vladivostok'],'rublo',
  array['Alexei','Anastasia','Dmitri','Natalia','Ivan','Tatiana','Nikolai','Olga','Sergei','Irina','Mikhail','Yelena'],
  array['Ivanov','Petrov','Volkov','Sokolov','Morozov','Popov','Lebedev','Kozlov','Novikov','Orlov'],
  array['Vestnik Imperial','Gazeta de Moscou','Correio do Neva']),
('BR','Brasil','do Brasil','no Brasil','brasileiro','brasileira','brasileiros','Brasília',
  array['São Paulo','Salvador','Recife','Belo Horizonte','Porto Alegre','Manaus','Petrópolis','Curitiba'],'real',
  array['Lucas','Ana','Gabriel','Júlia','Pedro','Mariana','Rafael','Beatriz','Guilherme','Larissa','Thiago','Camila'],
  array['Silva','Souza','Oliveira','Lima','Carvalho','Almeida','Ribeiro','Barbosa','Araújo','Rocha','Cardoso','Moura'],
  array['Correio da Corte','Jornal do Império','Gazeta Imperial']),
('US','Estados Unidos','dos Estados Unidos','nos Estados Unidos','americano','americana','americanos','Washington',
  array['Nova York','Chicago','Boston','Los Angeles','Nova Orleans','Filadélfia','São Francisco'],'dólar',
  array['James','Emily','Michael','Madison','Ethan','Ava','Daniel','Abigail','Jack','Harper','Noah','Grace'],
  array['Johnson','Miller','Davis','Anderson','Clark','Lewis','Walker','Hall','Young','King','Carter','Brooks'],
  array['The Capitol Chronicle','American Daily Ledger','The Liberty Post'])
on conflict (code) do nothing;

alter table public.characters
  add column if not exists gender text not null default 'n',
  add column if not exists country_code text references public.countries (code),
  add column if not exists title text not null default '',
  add column if not exists next_social_at timestamptz;

do $$ begin
  alter table public.characters add constraint characters_gender_chk check (gender in ('m', 'f', 'n'));
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.characters add constraint characters_title_chk check (char_length(title) <= 80);
exception when duplicate_object then null; end $$;

-- JSON público do personagem agora inclui gênero, país e título.
create or replace function private.character_json(c public.characters) returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'firstName', c.first_name, 'lastName', c.last_name,
    'email', c.email, 'phoneNumber', c.phone_number, 'description', c.description,
    'avatarUrl', c.avatar_url, 'avatarColor', c.avatar_color, 'active', c.active,
    'gender', c.gender, 'countryCode', c.country_code, 'title', c.title
  )
$$;

create or replace function private.validate_profile(p_gender text, p_country text, p_title text) returns void
language plpgsql stable security definer set search_path = public as $$
begin
  if coalesce(p_gender, 'n') not in ('m', 'f', 'n') then
    raise exception 'Gênero inválido.' using errcode = '22023';
  end if;
  if p_country is not null and p_country <> '' and not exists (select 1 from public.countries where code = p_country) then
    raise exception 'País inválido.' using errcode = '22023';
  end if;
  if char_length(coalesce(p_title, '')) > 80 then
    raise exception 'Título muito longo (máx. 80 caracteres).' using errcode = '22023';
  end if;
end $$;

-- ------------------------------------------- RPCs com os novos campos
drop function if exists public.create_character(text, text, text, text, text);
drop function if exists public.update_character(uuid, text, text, text, text, text);
drop function if exists public.add_circle_member(uuid, text, public.relation_kind, uuid, text, text, text);

create function public.create_character(
  p_first_name text, p_last_name text, p_description text default '',
  p_avatar_color text default null, p_email text default null,
  p_gender text default 'n', p_country text default null, p_title text default ''
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
  perform private.validate_profile(p_gender, p_country, p_title);

  insert into public.characters (kind, owner_user_id, first_name, last_name, description, email, phone_number,
    avatar_color, gender, country_code, title)
  values ('player', auth.uid(), btrim(p_first_name), btrim(coalesce(p_last_name, '')), btrim(coalesce(p_description, '')),
    coalesce(private.normalize_custom_email(p_email, null),
             private.generate_email(p_first_name, coalesce(p_last_name, ''))),
    private.generate_phone(),
    coalesce(nullif(p_avatar_color, ''), private.random_color()),
    coalesce(p_gender, 'n'), nullif(p_country, ''), btrim(coalesce(p_title, '')))
  returning * into v;

  perform private.audit('character.create', 'character', v.id);
  return private.character_json(v);
end $$;

create function public.update_character(
  p_character uuid, p_first_name text, p_last_name text, p_description text, p_avatar_color text,
  p_email text default null, p_gender text default 'n', p_country text default null, p_title text default ''
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v public.characters;
  v_old_email text;
  v_new_email text;
begin
  perform private.require_owner(p_character);
  if char_length(btrim(coalesce(p_first_name, ''))) = 0 then
    raise exception 'Informe o nome do personagem.' using errcode = '22023';
  end if;
  if p_avatar_color is not null and p_avatar_color !~ '^#[0-9a-fA-F]{6}$' then
    raise exception 'Cor inválida.' using errcode = '22023';
  end if;
  perform private.validate_profile(p_gender, p_country, p_title);

  select email into v_old_email from public.characters where id = p_character;
  v_new_email := coalesce(private.normalize_custom_email(p_email, p_character), v_old_email);

  update public.characters set
    first_name = btrim(p_first_name),
    last_name = btrim(coalesce(p_last_name, '')),
    description = btrim(coalesce(p_description, '')),
    avatar_color = coalesce(nullif(p_avatar_color, ''), avatar_color),
    email = v_new_email,
    gender = coalesce(p_gender, 'n'),
    country_code = nullif(p_country, ''),
    title = btrim(coalesce(p_title, ''))
  where id = p_character
  returning * into v;

  if v.email <> v_old_email then
    update public.email_drafts set to_addresses = array_replace(to_addresses, v_old_email, v.email)
    where v_old_email = any (to_addresses);
  end if;

  perform private.audit('character.update', 'character', v.id,
    jsonb_build_object('email_changed', v.email <> v_old_email, 'old_email', v_old_email));
  return private.character_json(v);
end $$;

create function public.add_circle_member(
  p_character uuid,
  p_relation_label text,
  p_relation_kind public.relation_kind,
  p_existing_character uuid default null,
  p_first_name text default null,
  p_last_name text default null,
  p_description text default '',
  p_gender text default 'n'
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v_related public.characters;
  v_rel uuid;
  v_owner public.characters;
begin
  perform private.require_owner(p_character);
  if (select count(*) from public.character_relationships where character_id = p_character)
     >= private.setting_int('max_circle_size', 30) then
    raise exception 'O círculo atingiu o limite de pessoas.' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_relation_label, ''))) = 0 then
    raise exception 'Informe a relação (ex.: irmão, marido).' using errcode = '22023';
  end if;
  perform private.validate_profile(p_gender, null, '');

  if p_existing_character is not null then
    select * into v_related from public.characters where id = p_existing_character and active;
    if v_related.id is null then
      raise exception 'Personagem não encontrado.' using errcode = 'P0002';
    end if;
  else
    if char_length(btrim(coalesce(p_first_name, ''))) = 0 then
      raise exception 'Informe o nome da pessoa.' using errcode = '22023';
    end if;
    -- NPCs herdam o país de quem os criou (usado nas notícias e fofocas).
    select * into v_owner from public.characters where id = p_character;
    insert into public.characters (kind, created_by_character_id, first_name, last_name, description,
      email, phone_number, avatar_color, claim_code, gender, country_code)
    values ('npc', p_character, btrim(p_first_name), btrim(coalesce(p_last_name, '')), btrim(coalesce(p_description, '')),
      private.generate_email(p_first_name, coalesce(p_last_name, '')), private.generate_phone(),
      private.random_color(), private.generate_claim_code(), coalesce(p_gender, 'n'), v_owner.country_code)
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

alter table public.countries enable row level security;
revoke all on public.countries from anon, authenticated;
revoke all on function private.validate_profile(text, text, text) from public, anon, authenticated;
revoke all on function public.create_character(text, text, text, text, text, text, text, text) from public, anon;
revoke all on function public.update_character(uuid, text, text, text, text, text, text, text, text) from public, anon;
revoke all on function public.add_circle_member(uuid, text, public.relation_kind, uuid, text, text, text, text) from public, anon;
grant execute on function public.create_character(text, text, text, text, text, text, text, text) to authenticated;
grant execute on function public.update_character(uuid, text, text, text, text, text, text, text, text) to authenticated;
grant execute on function public.add_circle_member(uuid, text, public.relation_kind, uuid, text, text, text, text) to authenticated;

-- =====================================================================
-- E-mails de NPC: filhos chamam de pai/mãe, cônjuge expandido, romance.
-- Novos marcadores: {pai_mae} / {Pai_mae} → "pai"/"mãe" conforme o gênero
-- do personagem do jogador (neutro → primeiro nome).
-- =====================================================================

create or replace function private.enqueue_npc_message(
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
  v_topic text := 'geral';
  v_orig_subject text := '';
  v_subject text;
  v_body text;
  v_parent text;
begin
  select * into v_npc from public.characters where id = p_npc;
  select * into v_player from public.characters where id = p_player;
  if v_npc.id is null or v_player.id is null then return; end if;

  select relation_kind, relation_label into v_kind, v_label
  from public.character_relationships
  where character_id = p_player and related_character_id = p_npc;
  v_kind := coalesce(v_kind, 'outro');
  v_label := coalesce(v_label, 'conhecido(a)');

  if p_purpose = 'reply' and p_in_reply_to is not null then
    select private.detect_topic(subject, body), regexp_replace(subject, '^((re|fwd?|enc)\s*:\s*)+', '', 'i')
      into v_topic, v_orig_subject
    from public.emails where id = p_in_reply_to;
    v_topic := coalesce(v_topic, 'geral');
  end if;

  select t.* into v_tpl
  from public.npc_templates t
  where t.purpose = p_purpose
    and t.relation_kind in (v_kind, 'outro')
    and (p_purpose <> 'reply' or t.topic in (v_topic, 'geral'))
  order by
    (t.topic = v_topic) desc,
    (t.relation_kind = v_kind) desc,
    (select count(*) from public.npc_outbox o
      where o.template_id = t.id and o.npc_character_id = p_npc and o.to_character_id = p_player),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_parent := case v_player.gender when 'm' then 'pai' when 'f' then 'mãe' else v_player.first_name end;

  v_body := replace(replace(replace(replace(replace(replace(v_tpl.body,
    '{jogador}', v_player.first_name),
    '{npc}', v_npc.first_name),
    '{relacao}', v_label),
    '{assunto}', coalesce(nullif(v_orig_subject, ''), 'isso')),
    '{Pai_mae}', upper(left(v_parent, 1)) || substr(v_parent, 2)),
    '{pai_mae}', v_parent);

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

revoke all on function private.enqueue_npc_message(uuid, uuid, text, uuid, uuid, timestamptz) from public, anon, authenticated;

-- ------------------------------------------------------------- filhos
delete from public.npc_templates where relation_kind = 'filho';

insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('filho', 'spontaneous', 'geral', 'Saudade', 'Oi, {pai_mae}!

Tô com saudade. Quando a gente vai almoçar junto de novo? Só nós dois, como antigamente.

Te amo,
{npc}'),
('filho', 'spontaneous', 'geral', 'Preciso de uma ajuda', '{Pai_mae}, posso te pedir uma coisa?

Prometo que explico direitinho pessoalmente. Não é nada grave, juro!

{npc}'),
('filho', 'spontaneous', 'geral', 'Novidade!', '{Pai_mae}!! Tenho uma novidade e você vai ser a primeira pessoa a saber.

Me liga quando puder?

{npc}'),
('filho', 'spontaneous', 'geral', 'Posso conversar com você?', 'Oi, {pai_mae}.

Posso conversar com você sobre uma coisa que tá me incomodando? Não queria falar por escrito.

{npc}'),
('filho', 'spontaneous', 'geral', 'Achei uma foto nossa', '{Pai_mae}, achei uma foto nossa de quando eu era pequeno(a)…

Você não mudou nada. Já eu, nem se fala. 😅

{npc}'),
('filho', 'spontaneous', 'geral', 'Obrigado(a)', 'Só queria dizer obrigado(a) por tudo, {pai_mae}.

Às vezes eu esqueço de falar, mas sei o quanto você faz por mim.

{npc}'),
('filho', 'spontaneous', 'geral', 'Você viu o que falaram?', '{Pai_mae}, você viu o que andam falando da nossa família no Twixer?

Não liga pra isso, tá? Eu sei quem você é.

{npc}'),
('filho', 'reply', 'geral', '', 'Valeu, {pai_mae}! Você sempre sabe o que dizer. ❤️

{npc}'),
('filho', 'reply', 'geral', '', 'Tá bom, {pai_mae}, vou fazer do jeito que você falou.

Mas depois não diga que eu não avisei! 😄

{npc}'),
('filho', 'reply', 'geral', '', 'Recebi, {pai_mae}! Depois a gente conversa melhor, tá?

Beijo,
{npc}'),
('filho', 'reply', 'saudacao', '', 'Oi, {pai_mae}! Tô bem sim, e você?

Senti sua falta. Vamos nos ver logo?

{npc}'),
('filho', 'reply', 'pergunta', '', 'Ai, {pai_mae}, que pergunta difícil…

Deixa eu pensar e te respondo direito, tá?

{npc}'),
('filho', 'reply', 'pedido', '', 'Claro, {pai_mae}! Pode deixar comigo.

Pra você eu faço qualquer coisa.

{npc}'),
('filho', 'reply', 'convite', '', 'Óbvio que eu vou, {pai_mae}! Já tô contando os dias. 🥰

{npc}'),
('filho', 'reply', 'agradecimento', '', 'Imagina, {pai_mae}! Você que merece. ❤️

{npc}'),
('filho', 'reply', 'desculpa', '', 'Tá tudo bem, {pai_mae}. Eu também errei.

Te amo mesmo assim.

{npc}'),
('filho', 'reply', 'preocupacao', '', '{Pai_mae}, o que aconteceu?! Tô ficando preocupado(a).

Me liga agora, por favor!

{npc}'),
('filho', 'reply', 'afeto', '', 'Também te amo muito, {pai_mae}.

Você é a melhor pessoa do mundo pra mim. ❤️

{npc}');

-- ------------------------------------------------- cônjuge (expansão)
insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('parceiro', 'spontaneous', 'geral', 'Bom dia, amor', 'Bom dia, meu amor. ☀️

Acordei e você já tinha saído. Fiquei olhando o seu lado da cama vazio. Volta cedo hoje?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Hoje à noite', '{jogador}, reservei uma mesa para nós hoje à noite.

Sem compromissos oficiais, sem ninguém olhando. Só a gente.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Sobre ontem', 'Fiquei pensando na nossa conversa de ontem.

Talvez eu tenha passado do ponto. Podemos conversar com calma hoje?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Ciúme?', 'Quem era aquela pessoa que não saiu do seu lado no evento?

Não é ciúme… é só curiosidade. Tá bom, é um pouco de ciúme.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Saudade', 'Você mal chegou e já foi embora de novo.

Sinto sua falta, {jogador}. Até das suas manias.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Uma surpresa', 'Tenho uma surpresa pra você.

Não adianta perguntar: só conto quando você chegar. 😏

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Nós', 'Pensei muito na gente hoje. Em tudo o que construímos.

Às vezes esqueço de dizer o quanto me orgulho de nós.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Sua agenda', '{jogador}, você está trabalhando demais.

Há quanto tempo a gente não tem um fim de semana só nosso?

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Ouvi umas coisas', 'Andam falando de nós por aí.

Não ligo pra fofoca… mas prefiro ouvir de você se houver algo que eu precise saber.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Lembra?', 'Hoje passei pelo lugar onde a gente se conheceu.

Ainda lembro do que você estava vestindo. Bobagem, eu sei. ❤️

{npc}'),
('parceiro', 'spontaneous', 'geral', 'As crianças', 'As crianças perguntaram de você no jantar.

Eu disse que você estava ocupado(a) salvando o mundo. Volta logo pra provar.

{npc}'),
('parceiro', 'spontaneous', 'geral', 'Uma decisão', 'Precisamos decidir juntos aquele assunto que a gente vem adiando.

Não quero decidir sem você.

{npc}'),
('parceiro', 'reply', 'pergunta', '', 'Você me conhece, {jogador}. Já sabe a resposta.

Mas, se precisa ouvir: sim.

{npc}'),
('parceiro', 'reply', 'pergunta', '', 'Hmm… depende.

Me pergunta de novo hoje à noite, olhando nos meus olhos.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Li sua mensagem três vezes.

Você escreve como fala — e eu adoro isso.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Anotado, meu bem.

A gente resolve isso junto, como sempre.

{npc}'),
('parceiro', 'reply', 'geral', '', 'Às vezes acho que você esquece que eu estou do seu lado, {jogador}.

Estou. Sempre.

{npc}'),
('parceiro', 'reply', 'saudacao', '', 'Estou bem, amor. Com saudade, mas bem.

Que horas você volta pra casa?

{npc}'),
('parceiro', 'reply', 'preocupacao', '', '{jogador}, você está me assustando. Onde você está?

Não faça nada sozinho(a). Estou indo.

{npc}'),
('parceiro', 'reply', 'afeto', '', 'Você ainda me faz sorrir como no primeiro dia.

Te amo, {jogador}. ❤️

{npc}'),
('parceiro', 'reply', 'convite', '', 'Aceito.

Mas só se você prometer desligar o resto do mundo por uma noite.

{npc}'),
('parceiro', 'reply', 'desculpa', '', 'Eu te perdoo, {jogador}.

Só não me faça passar por isso de novo, tá?

{npc}'),
('parceiro', 'reply', 'pedido', '', 'Já está resolvido.

Você nem precisava pedir, meu amor.

{npc}');

-- ------------------------------------------------- romance / caso secreto
insert into public.npc_templates (relation_kind, purpose, topic, subject, body) values
('romance', 'spontaneous', 'geral', 'Não consigo parar de pensar', 'Não consigo parar de pensar naquela noite, {jogador}.

Você também pensa? Seja sincero(a).

{npc}'),
('romance', 'spontaneous', 'geral', 'Cuidado', 'Acho que alguém desconfia de nós.

Precisamos ser mais discretos por um tempo. Isso está me matando.

{npc}'),
('romance', 'spontaneous', 'geral', 'Hoje?', 'Mesmo lugar, mesma hora?

Ninguém precisa saber. 🤫

{npc}'),
('romance', 'spontaneous', 'geral', 'Te vi hoje', 'Te vi hoje de longe.

Fingir que não te conheço está ficando cada vez mais difícil.

{npc}'),
('romance', 'spontaneous', 'geral', 'Até quando?', 'Até quando a gente vai viver escondido, {jogador}?

Não é cobrança. É só cansaço.

{npc}'),
('romance', 'spontaneous', 'geral', 'Apague depois de ler', 'Sonhei com você. Só isso.

Apague este e-mail depois de ler.

{npc}'),
('romance', 'spontaneous', 'geral', 'Você viu o Twixer?', 'Viu o que estão dizendo de nós no Twixer?

Rimos disso juntos… ou devíamos estar com medo?

{npc}'),
('romance', 'reply', 'geral', '', 'Li sua mensagem escondido, com o coração na boca.

Você é perigoso(a) para mim, {jogador}.

{npc}'),
('romance', 'reply', 'geral', '', 'Não diga isso por escrito. Diga pessoalmente. 🤫

{npc}'),
('romance', 'reply', 'geral', '', 'Cada mensagem sua é um risco que eu aceito correr.

{npc}'),
('romance', 'reply', 'saudacao', '', 'Estou bem agora que você escreveu.

Ninguém pode saber o quanto isso me faz bem.

{npc}'),
('romance', 'reply', 'pergunta', '', 'Você sabe a resposta, {jogador}.

Só tem medo de ouvir.

{npc}'),
('romance', 'reply', 'pedido', '', 'Para você, eu arrisco.

Mas que fique só entre nós.

{npc}'),
('romance', 'reply', 'convite', '', 'Eu vou.

Mas chegamos separados e saímos separados. Como sempre.

{npc}'),
('romance', 'reply', 'desculpa', '', 'Não precisa pedir desculpas.

A culpa é da situação, não sua.

{npc}'),
('romance', 'reply', 'preocupacao', '', 'O que houve? Se precisar, eu largo tudo e vou até você.

Que se danem as aparências.

{npc}'),
('romance', 'reply', 'afeto', '', 'Eu também, {jogador}.

Mais do que deveria. Mais do que posso.

{npc}');

-- =====================================================================
-- Rumor — rede social fictícia do mundo do jogo.
--
-- Posts sobre cada personagem (fãs, críticos, fofoca sobre cônjuge,
-- filhos, romances, ex e família, lidos do CÍRCULO) e notícias do PAÍS.
-- Tudo gerado no banco a partir de modelos + nomes/cidades/números
-- aleatórios, evitando repetir o mesmo modelo para a mesma pessoa.
--
-- Marcadores dos modelos:
--   {nome} {pnome} {sobrenome} {titulo}
--   {pais} {de_pais} {em_pais} {capital} {cidade} {moeda} {gentilico} {gentilicos}
--   {ele} {dele} {o} {um}          (concordam com o gênero do personagem)
--   {conjuge} {conjuge_nome} {conjuge_o}   ("o marido" / "a esposa")
--   {filhos} {filho}   {romance} {romance_pnome}   {ex}   {familiar}
--   {num} {pct}
-- Um modelo só é usado se o personagem tiver o que ele menciona
-- (ex.: {conjuge} exige cônjuge no círculo).
-- =====================================================================

create table if not exists public.social_templates (
  id serial primary key,
  category text not null check (category in
    ('fa','critica','conjuge','filhos','romance','ex','familia','politica','economia','sociedade')),
  body text not null
);

create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  country_code text references public.countries (code),
  subject_character_id uuid references public.characters (id) on delete cascade,
  category text not null,
  template_id integer references public.social_templates (id) on delete set null,
  author_name text not null,
  author_handle text not null,
  author_kind text not null check (author_kind in ('pessoa','fa','fofoca','imprensa')),
  body text not null,
  likes integer not null default 0,
  reposts integer not null default 0,
  replies integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists social_posts_subject_idx on public.social_posts (subject_character_id, created_at desc);
create index if not exists social_posts_country_idx on public.social_posts (country_code, created_at desc);

create table if not exists public.social_country_state (
  country_code text primary key references public.countries (code),
  next_news_at timestamptz
);

insert into public.server_settings (key, value) values
  ('social_post_interval_hours', '{"min": 2, "max": 6}'),
  ('social_news_interval_hours', '{"min": 2, "max": 5}')
on conflict (key) do nothing;

-- ------------------------------------------------------------ helpers
create or replace function private.pick(p_items text[]) returns text
language sql volatile as $$
  select p_items[1 + floor(random() * cardinality(p_items))::int]
$$;

create or replace function private.join_names(p_names text[]) returns text
language sql immutable as $$
  select case
    when p_names is null or cardinality(p_names) = 0 then null
    when cardinality(p_names) = 1 then p_names[1]
    else array_to_string(p_names[1:cardinality(p_names) - 1], ', ') || ' e ' || p_names[cardinality(p_names)]
  end
$$;

create or replace function private.social_fill(
  p_body text, p_ctx jsonb, p_cities text[], p_kids text[], p_family text[]
) returns text
language plpgsql volatile as $$
declare
  r text := p_body;
  k text;
begin
  for k in select jsonb_object_keys(p_ctx) loop
    r := replace(r, '{' || k || '}', coalesce(p_ctx ->> k, ''));
  end loop;
  while position('{cidade}' in r) > 0 loop
    r := overlay(r placing coalesce(private.pick(p_cities), 'a capital') from position('{cidade}' in r) for 8);
  end loop;
  while position('{filho}' in r) > 0 loop
    r := overlay(r placing coalesce(private.pick(p_kids), '') from position('{filho}' in r) for 7);
  end loop;
  while position('{familiar}' in r) > 0 loop
    r := overlay(r placing coalesce(private.pick(p_family), '') from position('{familiar}' in r) for 10);
  end loop;
  while position('{num}' in r) > 0 loop
    r := overlay(r placing (3 + floor(random() * 95))::int::text from position('{num}' in r) for 5);
  end loop;
  while position('{pct}' in r) > 0 loop
    r := overlay(r placing replace(round((0.3 + random() * 8.5)::numeric, 1)::text, '.', ',') from position('{pct}' in r) for 5);
  end loop;
  return r;
end $$;

-- Engajamento com cara de rede social (poucos posts "viralizam").
create or replace function private.social_engagement(p_base integer) returns integer[]
language plpgsql volatile as $$
declare
  likes integer := 1 + floor(power(random(), 2.4) * p_base * 3)::int;
begin
  return array[likes, floor(likes * random() * 0.22)::int, floor(likes * random() * 0.07)::int];
end $$;

-- ----------------------------------------------- post sobre um personagem
create or replace function private.social_generate_post(p_subject uuid, p_at timestamptz) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
  k public.countries;
  v_spouse public.characters;
  v_romance public.characters;
  v_ex public.characters;
  v_kids text[];
  v_family text[];
  v_cats text[] := array['fa', 'critica'];
  v_weights integer[] := array[30, 10];
  v_total integer;
  v_roll integer;
  v_acc integer := 0;
  v_cat text;
  i integer;
  v_tpl public.social_templates;
  v_ctx jsonb;
  v_body text;
  v_kind text;
  v_author text;
  v_handle text;
  v_first text;
  v_last text;
  v_eng integer[];
  r double precision;
begin
  select * into c from public.characters where id = p_subject and active;
  if c.id is null or c.country_code is null then return; end if;
  select * into k from public.countries where code = c.country_code;

  select rc.* into v_spouse from public.character_relationships cr
    join public.characters rc on rc.id = cr.related_character_id and rc.active
    where cr.character_id = p_subject and cr.relation_kind = 'parceiro' order by cr.created_at limit 1;
  select rc.* into v_romance from public.character_relationships cr
    join public.characters rc on rc.id = cr.related_character_id and rc.active
    where cr.character_id = p_subject and cr.relation_kind = 'romance' order by random() limit 1;
  select rc.* into v_ex from public.character_relationships cr
    join public.characters rc on rc.id = cr.related_character_id and rc.active
    where cr.character_id = p_subject and cr.relation_kind = 'ex' order by random() limit 1;
  select array_agg(rc.first_name order by cr.created_at) into v_kids from public.character_relationships cr
    join public.characters rc on rc.id = cr.related_character_id and rc.active
    where cr.character_id = p_subject and cr.relation_kind = 'filho';
  select array_agg(rc.first_name) into v_family from public.character_relationships cr
    join public.characters rc on rc.id = cr.related_character_id and rc.active
    where cr.character_id = p_subject and cr.relation_kind in ('pai_mae', 'irmao', 'parente');

  if v_spouse.id is not null then v_cats := array_append(v_cats, 'conjuge'); v_weights := array_append(v_weights, 18); end if;
  if v_kids is not null then v_cats := array_append(v_cats, 'filhos'); v_weights := array_append(v_weights, 14); end if;
  if v_romance.id is not null then v_cats := array_append(v_cats, 'romance'); v_weights := array_append(v_weights, 16); end if;
  if v_ex.id is not null then v_cats := array_append(v_cats, 'ex'); v_weights := array_append(v_weights, 7); end if;
  if v_family is not null then v_cats := array_append(v_cats, 'familia'); v_weights := array_append(v_weights, 6); end if;

  select sum(w) into v_total from unnest(v_weights) as w;
  v_roll := floor(random() * v_total)::int;
  for i in 1..cardinality(v_cats) loop
    v_acc := v_acc + v_weights[i];
    if v_roll < v_acc then v_cat := v_cats[i]; exit; end if;
  end loop;

  select t.* into v_tpl from public.social_templates t
  where t.category = v_cat
    and (v_spouse.id is not null or t.body not like '%{conjuge%')
    and (v_kids is not null or t.body not like '%{filho%')
    and (v_romance.id is not null or t.body not like '%{romance%')
    and (v_ex.id is not null or t.body not like '%{ex}%')
    and (v_family is not null or t.body not like '%{familiar}%')
  order by
    (select count(*) from public.social_posts p where p.template_id = t.id and p.subject_character_id = p_subject),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_ctx := jsonb_build_object(
    'nome', btrim(c.first_name || ' ' || c.last_name),
    'pnome', c.first_name,
    'sobrenome', coalesce(nullif(c.last_name, ''), c.first_name),
    'titulo', coalesce(nullif(lower(left(c.title, 1)) || substr(c.title, 2), ''), 'figura pública'),
    'pais', k.name, 'de_pais', k.name_de, 'em_pais', k.name_em,
    'capital', k.capital, 'moeda', k.currency,
    'gentilico', case c.gender when 'f' then k.demonym_f else k.demonym_m end,
    'gentilicos', k.demonym_pl,
    'ele', case c.gender when 'm' then 'ele' when 'f' then 'ela' else 'ele(a)' end,
    'dele', case c.gender when 'm' then 'dele' when 'f' then 'dela' else 'dele(a)' end,
    'o', case c.gender when 'm' then 'o' when 'f' then 'a' else 'o(a)' end,
    'um', case c.gender when 'm' then 'um' when 'f' then 'uma' else 'um(a)' end,
    'conjuge', v_spouse.first_name,
    'conjuge_nome', btrim(v_spouse.first_name || ' ' || v_spouse.last_name),
    'conjuge_o', case v_spouse.gender when 'm' then 'o marido' when 'f' then 'a esposa' else 'o(a) cônjuge' end,
    'filhos', private.join_names(v_kids),
    'romance', btrim(v_romance.first_name || ' ' || v_romance.last_name),
    'romance_pnome', v_romance.first_name,
    'ex', btrim(v_ex.first_name || ' ' || v_ex.last_name)
  );
  v_body := private.social_fill(v_tpl.body, v_ctx, k.cities, v_kids, v_family);
  if random() < 0.3 then
    v_body := v_body || ' #' || regexp_replace(c.first_name || c.last_name, '[^[:alnum:]]', '', 'g');
  end if;

  r := random();
  if r < 0.55 then
    v_kind := 'pessoa';
    v_first := private.pick(k.first_names);
    v_last := private.pick(k.last_names);
    v_author := v_first || ' ' || v_last;
    v_handle := replace(private.slugify(v_first), '.', '') || private.pick(array['', '_', '.'])
      || replace(private.slugify(v_last), '.', '')
      || case when random() < 0.4 then floor(random() * 99)::int::text else '' end;
  elsif r < 0.8 then
    v_kind := 'fa';
    v_author := private.pick(array[c.first_name || ' Updates', c.first_name || ' Daily', 'Arquivo ' || c.first_name,
      c.first_name || ' Lovers', 'Fã-clube ' || c.first_name]);
    v_handle := replace(private.slugify(c.first_name || c.last_name), '.', '')
      || private.pick(array['updates', 'daily', 'archive', 'lovers', 'fc']);
  else
    v_kind := 'fofoca';
    v_author := private.pick(array['Corte em Off', 'Bastidores Reais', 'Sussurros de ' || k.capital,
      'Royal Watch ' || k.code, 'Fofocas da Corte', 'Olhar Nobre']);
    v_handle := replace(private.slugify(v_author), '.', '');
  end if;

  v_eng := private.social_engagement(case v_kind when 'fofoca' then 9000 when 'fa' then 3500 else 700 end);
  insert into public.social_posts (country_code, subject_character_id, category, template_id,
    author_name, author_handle, author_kind, body, likes, reposts, replies, created_at)
  values (c.country_code, c.id, v_cat, v_tpl.id, v_author, left(v_handle, 30), v_kind, v_body,
    v_eng[1], v_eng[2], v_eng[3], p_at);
end $$;

-- ------------------------------------------------------ notícia do país
create or replace function private.social_generate_news(p_country text, p_at timestamptz) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  k public.countries;
  v_cat text;
  r double precision := random();
  v_tpl public.social_templates;
  v_body text;
  v_author text;
  v_eng integer[];
begin
  select * into k from public.countries where code = p_country;
  if k.code is null then return; end if;
  v_cat := case when r < 0.4 then 'politica' when r < 0.75 then 'economia' else 'sociedade' end;

  select t.* into v_tpl from public.social_templates t
  where t.category = v_cat
  order by
    (select count(*) from public.social_posts p where p.template_id = t.id and p.country_code = p_country
      and p.subject_character_id is null),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_body := private.social_fill(v_tpl.body, jsonb_build_object(
    'pais', k.name, 'de_pais', k.name_de, 'em_pais', k.name_em,
    'capital', k.capital, 'moeda', k.currency, 'gentilicos', k.demonym_pl
  ), k.cities, null, null);
  v_author := private.pick(k.outlets);
  v_eng := private.social_engagement(2500);

  insert into public.social_posts (country_code, subject_character_id, category, template_id,
    author_name, author_handle, author_kind, body, likes, reposts, replies, created_at)
  values (k.code, null, v_cat, v_tpl.id, v_author, left(replace(private.slugify(v_author), '.', ''), 30),
    'imprensa', v_body, v_eng[1], v_eng[2], v_eng[3], p_at);
end $$;

-- ------------------------------------------------------------ relógio
create or replace function private.social_tick() returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  r record;
begin
  for r in
    select id from public.characters
    where kind = 'player' and active and country_code is not null
      and (next_social_at is null or next_social_at <= now())
    limit 50
  loop
    perform private.social_generate_post(r.id, now());
    update public.characters
      set next_social_at = now() + private.random_interval('social_post_interval_hours', 'hours')
      where id = r.id;
  end loop;

  for r in
    select distinct country_code from public.characters
    where kind = 'player' and active and country_code is not null
  loop
    insert into public.social_country_state (country_code) values (r.country_code) on conflict do nothing;
    if (select coalesce(next_news_at <= now(), true) from public.social_country_state where country_code = r.country_code) then
      perform private.social_generate_news(r.country_code, now());
      update public.social_country_state
        set next_news_at = now() + private.random_interval('social_news_interval_hours', 'hours')
        where country_code = r.country_code;
    end if;
  end loop;
end $$;

-- Primeira visita: cria um histórico para o feed não começar vazio.
create or replace function private.social_backfill(p_character uuid) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
  i integer;
begin
  select * into c from public.characters where id = p_character;
  if c.country_code is null then return; end if;
  if (select count(*) from public.social_posts where subject_character_id = p_character) < 5 then
    for i in 1..12 loop
      perform private.social_generate_post(p_character, now() - random() * interval '48 hours');
    end loop;
    update public.characters
      set next_social_at = now() + private.random_interval('social_post_interval_hours', 'hours')
      where id = p_character;
  end if;
  if (select count(*) from public.social_posts where country_code = c.country_code and subject_character_id is null) < 5 then
    for i in 1..10 loop
      perform private.social_generate_news(c.country_code, now() - random() * interval '48 hours');
    end loop;
  end if;
end $$;

-- O relógio dos NPCs passa a mover também o Rumor.
create or replace function public.npc_tick() returns integer
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

  perform private.social_tick();
  return delivered;
end $$;

-- ------------------------------------------------------------ feed
create or replace function public.get_feed(p_character uuid, p_tab text default 'para_voce') returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
begin
  perform private.require_owner(p_character);
  perform public.npc_tick();
  perform private.social_backfill(p_character);
  select * into c from public.characters where id = p_character;

  return jsonb_build_object(
    'countryCode', c.country_code,
    'posts', coalesce((
      select jsonb_agg(x order by x ->> 'createdAt' desc) from (
        select jsonb_build_object(
          'id', p.id, 'authorName', p.author_name, 'authorHandle', p.author_handle,
          'authorKind', p.author_kind, 'body', p.body, 'likes', p.likes, 'reposts', p.reposts,
          'replies', p.replies, 'createdAt', p.created_at, 'category', p.category,
          'aboutMe', p.subject_character_id is not distinct from p_character
        ) as x
        from public.social_posts p
        where p.created_at <= now() and (
          (p_tab = 'sobre' and p.subject_character_id = p_character)
          or (p_tab = 'noticias' and p.subject_character_id is null and p.country_code = c.country_code)
          or (p_tab not in ('sobre', 'noticias') and (
            p.subject_character_id = p_character
            or p.subject_character_id in (select related_character_id from public.character_relationships
                                          where character_id = p_character)
            or p.country_code = c.country_code))
        )
        order by p.created_at desc
        limit 80
      ) s), '[]')
  );
end $$;

-- ------------------------------------------------------------ permissões
alter table public.social_templates enable row level security;
alter table public.social_posts enable row level security;
alter table public.social_country_state enable row level security;
revoke all on public.social_templates, public.social_posts, public.social_country_state from anon, authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.owns_character(uuid) to authenticated;
revoke all on function public.get_feed(uuid, text) from public, anon;
grant execute on function public.get_feed(uuid, text) to authenticated;
revoke all on function public.npc_tick() from public, anon;
grant execute on function public.npc_tick() to authenticated;

-- =====================================================================
-- MODELOS
-- =====================================================================
insert into public.social_templates (category, body) values
-- ------------------------------------------------------------------- fãs
('fa', '{nome} é simplesmente {o} mais elegante {de_pais}. Não aceito discussão. ✨'),
('fa', 'Acordei pensando em {pnome} de novo. Normal, né? 🙃'),
('fa', 'Vi {pnome} de longe hoje em {cidade}. Gente, ao vivo é ainda mais impressionante.'),
('fa', 'Se {pnome} entra na sala, o resto vira figurante. Fato.'),
('fa', 'Toda vez que {nome} aparece em público eu lembro por que acompanho a vida dessa gente.'),
('fa', '{pnome} parou pra conversar com uma senhora na rua em {capital} por dez minutos. Isso ninguém mostra, né?'),
('fa', 'Eu defendo {pnome} até o fim. Podem vir. 🛡️'),
('fa', 'Ranking de quem sabe se portar em público {em_pais}: 1. {nome}. 2. Ninguém chega perto.'),
('fa', 'Alguém tem a foto de {pnome} no evento de ontem? Preciso para fins científicos. 📸'),
('fa', '{nome} fala e o país inteiro para pra ouvir. Isso se chama presença.'),
('fa', 'Não importa o que digam: {pnome} carrega a imagem {de_pais} nas costas.'),
('fa', 'Minha avó diz que não via alguém com a postura de {pnome} desde os velhos tempos. E ela não elogia ninguém.'),
('fa', 'Os {gentilicos} não merecem {pnome}. Eu não mereço {pnome}. Ninguém merece. 😭'),
('fa', 'Mais um dia amando {nome} em silêncio. Bom, não tão em silêncio assim.'),
('fa', 'Quem disse que {titulo} não pode ter carisma claramente nunca viu {pnome} rindo.'),
('fa', '{pnome} usou verde ontem e hoje metade de {cidade} está de verde. Influência é isso.'),
('fa', 'Se um dia eu encontrar {nome} pessoalmente, vou fingir costume. Mentira, vou chorar.'),
('fa', 'Thread com os melhores momentos de {pnome} este ano 🧵 (spoiler: são todos)'),
('fa', '{pnome} tem aquele olhar de quem sabe exatamente o que todo mundo está pensando. Medo e admiração.'),
('fa', 'Fui a {capital} só pra tentar ver {pnome} passando. Valeu cada minuto de espera.'),
('fa', 'Não sigo política, não sigo esporte. Sigo {nome}. Prioridades.'),
('fa', '{nome} merecia um retrato em cada sala {de_pais}.'),
('fa', 'A elegância de {pnome} deveria ser matéria obrigatória nas escolas.'),
('fa', 'Alguém me explica como {pnome} consegue estar impecável até em dia de chuva?'),
('fa', 'Hoje faz {num} dias que eu não paro de falar de {nome}. Meus amigos já desistiram de mim.'),
('fa', 'O discurso de {pnome} ontem em {cidade} me deu arrepio. Que voz, que firmeza.'),
('fa', '{nome}: {titulo}, ícone, lenda. Nessa ordem.'),
('fa', 'Gente, {pnome} piscou para a câmera no fim do evento?? Eu vi. Eu VI. 😳'),
('fa', 'Vocês reclamam da nobreza, mas aí {pnome} aparece e todo mundo fica quieto, né?'),
('fa', 'Ninguém carrega um título como {pnome}. Isso sim é {titulo} de verdade.'),
('fa', 'Se {pnome} lançar um perfume, eu compro dez.'),
('fa', '{num} mil pessoas esperando {pnome} na praça de {cidade}. E ainda dizem que o povo não ama.'),
-- --------------------------------------------------------------- críticos
('critica', 'Mais um evento e {pnome} com aquela cara de quem preferia estar em qualquer outro lugar. Pelo menos disfarça.'),
('critica', 'Opinião impopular: o fascínio por {nome} é exagerado.'),
('critica', 'Quanto custou a festa de {pnome} semana passada? Pergunto pelo povo {de_pais}.'),
('critica', '{pnome} sumiu dos compromissos oficiais de novo. Alguém sabe onde {ele} anda?'),
('critica', 'Gosto de {pnome}, mas aquele discurso de ontem foi decorado demais.'),
('critica', 'Toda semana uma polêmica nova envolvendo {nome}. Cansei.'),
('critica', 'Quero ver {pnome} visitar {cidade} sem comitiva e sem fotógrafo.'),
('critica', 'Ninguém vai comentar que as doações da casa de {pnome} caíram {num}% este ano? Ok.'),
('critica', 'Me chamem de chato, mas quem é {titulo} deveria dar mais exemplo.'),
('critica', '{nome} posando de humilde é a minha piada favorita da semana.'),
('critica', 'Sinceramente? Metade do charme de {pnome} é assessoria de imagem.'),
('critica', 'O silêncio de {nome} sobre o que aconteceu em {cidade} diz muita coisa.'),
('critica', 'Fila de três horas em {cidade} pra ver {pnome} passar de carro por dez segundos. Povo {de_pais}, valorizem-se.'),
('critica', '{pnome} chegou {num} minutos atrasado no evento beneficente. Em qualquer emprego normal isso dava advertência.'),
-- --------------------------------------------------------------- cônjuge
('conjuge', 'Alguém mais acha que {conjuge} parece mais um figurante da corte do que {conjuge_o} de {pnome}? 👀'),
('conjuge', 'Faz quanto tempo que ninguém vê {pnome} e {conjuge} juntos num evento? Pergunta sincera.'),
('conjuge', '{pnome} e {conjuge} chegaram no mesmo carro e saíram em carros separados. Só observando. 🍿'),
('conjuge', 'O sorriso de {conjuge_nome} ao lado de {pnome} é o sorriso mais ensaiado {de_pais}.'),
('conjuge', 'Eu shippo {pnome} e {conjuge} sim, e daí? Casal lindo demais. 💍'),
('conjuge', 'Dizem que {pnome} e {conjuge} dormem em alas diferentes do palácio. Eu só repito o que ouvi.'),
('conjuge', '{conjuge} olhando para {pnome} no baile de ontem… aquilo foi amor ou estratégia?'),
('conjuge', 'Casamento de {pnome} com {conjuge}: aliança política ou romance de verdade? Respondam com sinceridade.'),
('conjuge', 'Já repararam que {conjuge} quase nunca fala em público? Parece que só existe nas fotos oficiais.'),
('conjuge', 'Aniversário de casamento de {pnome} e {conjuge} chegando e nenhuma comemoração anunciada. Estranho, né?'),
('conjuge', '{pnome} riu de uma piada de {conjuge}. Primeira vez em anos. Anotem a data.'),
('conjuge', 'Os {gentilicos} amam {pnome}, mas ninguém sabe dizer uma única coisa sobre {conjuge_nome}.'),
('conjuge', 'Vi {pnome} e {conjuge} de mãos dadas em {cidade}. Morreram as teorias de crise? 🤔'),
('conjuge', '{conjuge} perdeu a abertura do jantar oficial e {pnome} nem olhou para trás. Recado dado.'),
('conjuge', 'Fonte próxima da família diz que {pnome} e {conjuge} discutiram feio essa semana. Será?'),
('conjuge', 'Por mais que falem, {pnome} e {conjuge} sempre aparecem unidos quando importa. Respeito.'),
('conjuge', 'Ninguém se casa com {um} {titulo} achando que vai ter vida tranquila. Força, {conjuge}.'),
('conjuge', '{conjuge_nome} no cantinho da foto oficial de novo. Casou com {pnome} e virou papel de parede.'),
('conjuge', 'Mal vejo {pnome} com {conjuge_o}. Esse casamento existe mesmo ou é lenda urbana {de_pais}?'),
('conjuge', '{conjuge} dançou a noite inteira com outra pessoa no baile e {pnome} fingiu que não viu. Elegância ou cansaço?'),
('conjuge', 'Hot take: {conjuge} é o maior acessório de {pnome}. Bonito, caro e decorativo.'),
-- ---------------------------------------------------------------- filhos
('filhos', '{filhos}: cada dia mais lindos. A genética de {pnome} não brinca em serviço. 😍'),
('filhos', 'Gente, vocês viram {filho} no evento de ontem? A cara de {pnome}!'),
('filhos', '{pnome} com {filhos} no parque de {cidade}. A coisa mais fofa da semana.'),
('filhos', 'Os herdeiros de {pnome} já têm mais fãs que muita celebridade {de_pais}.'),
('filhos', '{filho} acenando pra multidão como se tivesse nascido pra isso. E nasceu, né?'),
('filhos', 'Quem vai herdar o charme de {pnome}? Minha aposta é em {filho}.'),
('filhos', 'Dizem que {pnome} faz questão de buscar {filhos} pessoalmente. Aprendam, pais e mães {de_pais}.'),
('filhos', 'Primeira aparição pública de {filho} em meses e já é o assunto do dia em {capital}.'),
('filhos', 'As crianças de {pnome} são educadas demais. Cumprimentaram até os seguranças. Criação é tudo.'),
('filhos', '{filho} fazendo careta na foto oficial é o conteúdo que eu precisava hoje. 😂'),
('filhos', 'Já tem gente especulando casamento arranjado para {filho}. Deixem a criança crescer, pelo amor.'),
('filhos', '{filhos}: a próxima geração {de_pais} está em boas mãos.'),
('filhos', '{pnome} olhando para {filho} durante o desfile: o único momento em que {ele} baixa a guarda.'),
('filhos', 'Alguém mais acha que {filho} tem o mesmo olhar de {pnome}? Dá até arrepio.'),
('filhos', 'Se {filho} herdar metade da elegância de {pnome}, o futuro {de_pais} está garantido.'),
-- --------------------------------------------------------------- romance
('romance', 'Até hoje não superei {pnome} e {romance}. A química dos dois era outra coisa. 😭'),
('romance', 'Tenho raiva de {pnome} e {romance_pnome} por nunca terem se assumido. A gente ia ser tão feliz.'),
('romance', 'Alguém mais viu {pnome} e {romance_pnome} conversando sozinhos no jardim do baile? Ou fui só eu?'),
('romance', '{pnome} e {romance}: o casal que o povo {de_pais} merecia e nunca teve.'),
('romance', 'O olhar de {romance_pnome} quando {pnome} entrou no salão… não me digam que não é nada.'),
('romance', 'Juro que vi {pnome} e {romance_pnome} saindo pela porta lateral no mesmo minuto. Coincidência? 👀'),
('romance', 'Se {pnome} tivesse coragem, hoje a história com {romance} seria outra. Fica a reflexão.'),
('romance', 'Dizem que {pnome} ainda guarda uma carta de {romance}. Meu coração não aguenta.'),
('romance', 'Shippar {pnome} e {romance_pnome} é sofrer em silêncio todos os dias.'),
('romance', '{romance} na mesma festa que {pnome} e {conjuge}?? Alguém tem detalhes desse climão?'),
('romance', '{pnome} e {romance_pnome} nunca confirmaram nada. Mas também nunca negaram. 🤫'),
('romance', 'O jeito que {romance_pnome} defende {pnome} em público fala mais que mil palavras.'),
('romance', 'Eu aceito qualquer final pra essa história, menos {pnome} longe de {romance}.'),
('romance', '{pnome} e {romance}: amor proibido ou amizade intensa demais? Opinem.'),
('romance', 'Toda vez que alguém cita {romance_pnome} perto de {pnome}, {ele} muda de assunto. Interessante.'),
('romance', 'Se {pnome} e {romance_pnome} se assumissem, metade {de_pais} faria festa e a outra metade, escândalo.'),
('romance', 'Os dois no mesmo camarote em {cidade} e fingindo que não se conhecem. {pnome} e {romance_pnome}, a gente não é bobo.'),
('romance', 'Ainda dói lembrar que {pnome} escolheu {conjuge} e não {romance}. Pronto, falei.'),
-- -------------------------------------------------------------------- ex
('ex', 'Lembram quando {pnome} e {ex} eram o casal do momento? Que fim levou isso?'),
('ex', '{ex} postou uma indireta e todo mundo sabe que é pra {pnome}. Drama servido. 🍿'),
('ex', 'Vi {ex} no mesmo restaurante que {pnome} em {cidade}. Nenhum dos dois olhou pro outro. Tensão no ar.'),
('ex', 'Ainda acho que {pnome} merecia mais do que {ex}. Pronto, falei.'),
('ex', '{pnome} superou {ex}? A cara de ontem dizia que não.'),
('ex', 'Dizem que {ex} ainda guarda mágoa de {pnome}. Faz sentido, depois de tudo.'),
('ex', '{ex} e {pnome} se cumprimentando com toda a frieza do mundo no evento de hoje. Amei.'),
('ex', 'Até hoje ninguém sabe direito por que {pnome} e {ex} terminaram. E eu não durmo enquanto não descobrir.'),
-- --------------------------------------------------------------- família
('familia', 'A família {sobrenome} reunida no almoço de domingo em {cidade}. {familiar} roubou a cena.'),
('familia', '{familiar} defendendo {pnome} publicamente. Família é isso.'),
('familia', 'Dizem que {familiar} não aprova certas escolhas de {pnome}. Clima tenso nos bastidores.'),
('familia', '{pnome} e {familiar} rindo juntos no camarote. Raro e bonito.'),
('familia', 'Ninguém fala de {familiar}, mas é quem segura a família {sobrenome} de pé.'),
('familia', 'Foto antiga de {pnome} com {familiar} circulando hoje. Que fofura.'),
('familia', 'Alguém sabe por que {familiar} não apareceu no último evento de {pnome}? Briga de família?'),
-- -------------------------------------------------------------- política
('politica', 'URGENTE: Parlamento {de_pais} aprova reforma tributária por margem apertada. Oposição promete recorrer.'),
('politica', 'Conselho de {capital} anuncia novo pacote de obras públicas para {cidade}.'),
('politica', 'Tensão diplomática: embaixador {de_pais} é convocado após declarações polêmicas no exterior.'),
('politica', 'A corte {de_pais} confirma visita oficial a {cidade} na próxima semana. Esquema de segurança será reforçado.'),
('politica', 'Pesquisa: {num}% dos {gentilicos} aprovam o atual governo, aponta levantamento divulgado hoje.'),
('politica', 'Ministro da Defesa nega aumento de tropas na fronteira, mas não descarta exercícios militares.'),
('politica', 'Protesto reúne milhares em {capital} contra novo imposto sobre importações.'),
('politica', 'Escândalo em {cidade}: três conselheiros são afastados após investigação de desvio de verbas.'),
('politica', '{pais} e países vizinhos assinam acordo de cooperação comercial e de defesa.'),
('politica', 'Debate acalorado no Parlamento termina com sessão suspensa. Votação adiada para a próxima semana.'),
('politica', 'Governo anuncia eleições antecipadas em {cidade} após renúncia do prefeito.'),
('politica', 'Nova lei de sucessão volta a ser discutida na corte {de_pais}. Nobres divididos.'),
('politica', 'Delegação estrangeira chega a {capital} para negociações delicadas. Clima é de cautela.'),
('politica', 'Opinião: a política {de_pais} nunca esteve tão polarizada. E isso tem um preço.'),
('politica', 'Oposição acusa o governo de usar a corte como vitrine e cobra transparência nos gastos oficiais.'),
('politica', 'Ministério do Interior reforça segurança em {capital} após ameaças anônimas.'),
('politica', 'Câmara aprova por {num} votos o projeto que muda as regras para títulos de nobreza.'),
('politica', 'Bastidores: aliados do governo já discutem nomes para a próxima eleição em {cidade}.'),
-- -------------------------------------------------------------- economia
('economia', 'O {moeda} fecha em alta de {pct}% frente às principais moedas estrangeiras.'),
('economia', 'Bolsa de {capital} recua {pct}% com incertezas sobre o novo orçamento.'),
('economia', 'Inflação {em_pais} chega a {pct}% no acumulado do ano, acima da meta.'),
('economia', 'Banco Central mantém juros e sinaliza cautela para os próximos meses.'),
('economia', 'Exportações batem recorde e somam {num} bilhões de {moeda} no trimestre.'),
('economia', 'Fábrica histórica de {cidade} anuncia demissões. Sindicatos convocam greve.'),
('economia', 'Preço do pão sobe {pct}% em {capital} e consumidores reclamam.'),
('economia', 'Novo porto de {cidade} promete gerar {num} mil empregos até o fim da década.'),
('economia', 'Desemprego {em_pais} cai para {pct}%, menor nível em cinco anos.'),
('economia', 'Família de banqueiros de {capital} anuncia fusão bilionária.'),
('economia', 'Turismo cresce {num}% e {cidade} lidera como destino mais procurado {de_pais}.'),
('economia', 'Agricultores protestam em {cidade} contra corte de subsídios.'),
('economia', 'Analistas alertam para bolha imobiliária em {capital}: aluguel subiu {num}% em um ano.'),
('economia', 'Tesouro {de_pais} anuncia emissão de títulos para financiar obras de infraestrutura.'),
('economia', 'Vinícolas e indústria têxtil {de_pais} pedem proteção contra concorrência estrangeira.'),
-- ------------------------------------------------------------- sociedade
('sociedade', 'Festival de verão de {cidade} reúne mais de {num} mil pessoas no primeiro dia.'),
('sociedade', 'Ópera de {capital} esgota ingressos da nova temporada em menos de uma hora.'),
('sociedade', 'Chuvas fortes causam alagamentos em {cidade}. Defesa civil pede cautela.'),
('sociedade', 'Museu Nacional {de_pais} reabre após reforma com exposição inédita.'),
('sociedade', 'Baile de gala anual da corte já tem data marcada. Lista de convidados é segredo absoluto.'),
('sociedade', 'Time de {cidade} conquista o título nacional pela primeira vez em {num} anos.'),
('sociedade', 'Moda: a nobreza {de_pais} aposta em tons escuros nesta temporada.'),
('sociedade', 'Universidade de {capital} completa {num} anos com cerimônia solene.'),
('sociedade', 'Greve dos transportes deixa {capital} parada nesta manhã.'),
('sociedade', 'Chef de {cidade} ganha prêmio internacional e coloca a cozinha {de_pais} no mapa.'),
('sociedade', 'Leilão beneficente em {capital} arrecada {num} milhões de {moeda} para hospitais infantis.');
