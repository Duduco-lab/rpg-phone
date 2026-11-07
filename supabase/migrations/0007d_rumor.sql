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
