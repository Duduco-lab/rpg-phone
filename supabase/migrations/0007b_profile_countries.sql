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
