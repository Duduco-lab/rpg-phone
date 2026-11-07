-- Regimes (império/reino/república) + Império Germânico (Alemanha + Áustria). Junta 0009 + 0010.

-- =====================================================================
-- Regime de governo por país (império, reino ou república) e notícias
-- políticas coerentes: monarquias não têm eleições; usam soberano,
-- conselho, assembleia, corte e tesouro próprios.
-- Para mudar um país, basta editar a linha dele em public.countries.
-- =====================================================================

alter table public.countries
  add column if not exists regime text not null default 'reino',
  add column if not exists ruler text not null default 'o Rei',
  add column if not exists court text not null default 'a corte real',
  add column if not exists council text not null default 'o Conselho Real',
  add column if not exists assembly text not null default 'as Cortes do Reino',
  add column if not exists treasury text not null default 'o Tesouro Real';

do $$ begin
  alter table public.countries add constraint countries_regime_chk check (regime in ('imperio', 'reino', 'republica'));
exception when duplicate_object then null; end $$;

update public.countries c set
  regime = v.regime, ruler = v.ruler, court = v.court, council = v.council, assembly = v.assembly, treasury = v.treasury
from (values
  ('DE', 'imperio',   'o Imperador',  'a corte imperial', 'o Conselho Imperial',   'a Dieta Imperial',      'o Tesouro Imperial'),
  ('AT', 'imperio',   'o Imperador',  'a corte imperial', 'o Conselho da Coroa',   'o Conselho do Império', 'o Tesouro Imperial'),
  ('RU', 'imperio',   'o Czar',       'a corte imperial', 'o Conselho de Estado',  'a Duma',                'o Tesouro Imperial'),
  ('BR', 'imperio',   'o Imperador',  'a corte imperial', 'o Conselho de Estado',  'a Assembleia Geral',    'o Tesouro Imperial'),
  ('IT', 'reino',     'o Rei',        'a corte real',     'o Conselho da Coroa',   'o Senado do Reino',     'o Tesouro Real'),
  ('GB', 'reino',     'o Rei',        'a corte real',     'o Conselho Privado',    'a Câmara dos Lordes',   'o Tesouro Real'),
  ('ES', 'reino',     'o Rei',        'a corte real',     'o Conselho Real',       'as Cortes',             'o Tesouro Real'),
  ('PT', 'reino',     'o Rei',        'a corte real',     'o Conselho de Estado',  'as Cortes Gerais',      'o Tesouro Real'),
  ('FR', 'reino',     'o Rei',        'a corte real',     'o Conselho do Rei',     'os Estados Gerais',     'o Tesouro Real'),
  ('US', 'republica', 'o Presidente', 'o governo',        'o Gabinete',            'o Congresso',           'o Tesouro Nacional')
) as v(code, regime, ruler, court, council, assembly, treasury)
where c.code = v.code;

-- Modelos podem ser restritos a regimes (null = qualquer regime).
alter table public.social_templates add column if not exists regimes text[];

-- "o Imperador" → {soberano}, {Soberano}, {de_soberano} ("do Imperador"), {ao_soberano} ("ao Imperador")
create or replace function private.inst_forms(p_key text, p_value text) returns jsonb
language sql immutable as $$
  select jsonb_build_object(
    p_key, p_value,
    upper(left(p_key, 1)) || substr(p_key, 2), upper(left(p_value, 1)) || substr(p_value, 2),
    'de_' || p_key, case
      when p_value like 'o %' then 'do ' || substr(p_value, 3)
      when p_value like 'a %' then 'da ' || substr(p_value, 3)
      when p_value like 'os %' then 'dos ' || substr(p_value, 4)
      when p_value like 'as %' then 'das ' || substr(p_value, 4)
      else 'de ' || p_value end,
    'ao_' || p_key, case
      when p_value like 'o %' then 'ao ' || substr(p_value, 3)
      when p_value like 'a %' then 'à ' || substr(p_value, 3)
      when p_value like 'os %' then 'aos ' || substr(p_value, 4)
      when p_value like 'as %' then 'às ' || substr(p_value, 4)
      else 'a ' || p_value end
  )
$$;

create or replace function private.social_generate_news(p_country text, p_at timestamptz) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  k public.countries;
  v_cat text;
  r double precision := random();
  v_tpl public.social_templates;
  v_ctx jsonb;
  v_body text;
  v_author text;
  v_eng integer[];
begin
  select * into k from public.countries where code = p_country;
  if k.code is null then return; end if;
  v_cat := case when r < 0.4 then 'politica' when r < 0.75 then 'economia' else 'sociedade' end;

  select t.* into v_tpl from public.social_templates t
  where t.category = v_cat and (t.regimes is null or k.regime = any (t.regimes))
  order by
    (select count(*) from public.social_posts p where p.template_id = t.id and p.country_code = p_country
      and p.subject_character_id is null),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_ctx := jsonb_build_object(
      'pais', k.name, 'de_pais', k.name_de, 'em_pais', k.name_em,
      'capital', k.capital, 'moeda', k.currency, 'gentilicos', k.demonym_pl)
    || private.inst_forms('soberano', k.ruler)
    || private.inst_forms('corte', k.court)
    || private.inst_forms('conselho', k.council)
    || private.inst_forms('assembleia', k.assembly)
    || private.inst_forms('tesouro', k.treasury);

  v_body := private.social_fill(v_tpl.body, v_ctx, k.cities, null, null);
  v_author := private.pick(k.outlets);
  v_eng := private.social_engagement(2500);

  insert into public.social_posts (country_code, subject_character_id, category, template_id,
    author_name, author_handle, author_kind, body, likes, reposts, replies, created_at)
  values (k.code, null, v_cat, v_tpl.id, v_author, left(replace(private.slugify(v_author), '.', ''), 30),
    'imprensa', v_body, v_eng[1], v_eng[2], v_eng[3], p_at);
end $$;

revoke all on function private.inst_forms(text, text) from public, anon, authenticated;
revoke all on function private.social_generate_news(text, timestamptz) from public, anon, authenticated;

-- ------------------------------------------------ notícias políticas novas
delete from public.social_templates where category = 'politica';

insert into public.social_templates (category, regimes, body) values
-- monarquias (impérios e reinos)
('politica', '{imperio,reino}', 'URGENTE: {Soberano} assina decreto que reforma os impostos sobre as terras. Nobres do interior não gostaram.'),
('politica', '{imperio,reino}', '{Conselho} aprova novo pacote de obras para {cidade}. Os trabalhos começam no próximo mês.'),
('politica', '{imperio,reino}', '{Soberano} fará visita oficial a {cidade} na próxima semana. A guarda reforçará a segurança.'),
('politica', '{imperio,reino}', 'Discurso {de_soberano} na abertura {de_assembleia} pede união entre as grandes famílias {de_pais}.'),
('politica', '{imperio,reino}', 'Escândalo em {cidade}: governador da província é afastado por ordem {de_soberano} após desvio de verbas.'),
('politica', '{imperio,reino}', 'Sessão {de_assembleia} termina em bate-boca entre duas casas nobres. Votação adiada.'),
('politica', '{imperio,reino}', 'A lei de sucessão volta à pauta {de_conselho}. Nobres divididos.'),
('politica', '{imperio,reino}', 'Delegação estrangeira chega a {capital} para negociações delicadas com {soberano}.'),
('politica', '{imperio,reino}', 'Comerciantes de {cidade} pedem audiência {ao_soberano} para reclamar das taxas portuárias.'),
('politica', '{imperio,reino}', '{Soberano} concede títulos de nobreza a {num} famílias por serviços prestados à Coroa.'),
('politica', '{imperio,reino}', 'Bastidores: cresce a disputa entre as grandes casas por uma cadeira vaga {de_conselho}.'),
('politica', '{imperio,reino}', '{Assembleia} aprova por {num} votos o novo código de conduta para a nobreza.'),
('politica', '{imperio,reino}', 'Decreto {de_soberano} proíbe duelos em {capital}. Jovens nobres prometem desobedecer.'),
('politica', '{imperio,reino}', 'Fontes do palácio: {conselho} estaria dividido sobre a política com os países vizinhos.'),
('politica', '{imperio,reino}', '{Corte} anuncia luto oficial de três dias pela morte de um velho duque de {cidade}.'),
('politica', '{imperio,reino}', 'Opinião: nunca a nobreza {de_pais} esteve tão dividida. E isso tem um preço.'),
('politica', '{imperio,reino}', 'Camponeses de {cidade} enviam petição {ao_soberano} contra a cobrança de novos tributos.'),
('politica', '{imperio,reino}', '{Soberano} recebe embaixadores estrangeiros em {capital}. Banquete durou até a madrugada.'),
-- só impérios
('politica', '{imperio}', 'Manobras do exército imperial perto da fronteira deixam países vizinhos em alerta.'),
('politica', '{imperio}', 'Governadores das províncias do império são convocados a {capital} para prestar contas {ao_soberano}.'),
('politica', '{imperio}', 'Aniversário de coroação {de_soberano}: desfile militar reúne milhares em {capital}.'),
-- só reinos
('politica', '{reino}', 'Casamento arranjado entre duas casas nobres {de_pais} deve selar a paz entre famílias rivais.'),
('politica', '{reino}', 'Jubileu do reinado: {soberano} percorre {cidade} em carruagem aberta e é aplaudido pelo povo.'),
-- monarquias e repúblicas
('politica', null, 'Tensão diplomática: embaixador {de_pais} é chamado de volta após incidente no exterior.'),
('politica', null, 'Ministro da Guerra nega movimentação de tropas na fronteira, mas não descarta manobras militares.'),
('politica', null, 'Protesto reúne centenas em {capital} contra o novo imposto sobre o sal.'),
('politica', null, '{pais} assina tratado de aliança e comércio com países vizinhos.'),
-- repúblicas
('politica', '{republica}', 'Eleições em {cidade}: candidato da oposição lidera as pesquisas a {num} dias da votação.'),
('politica', '{republica}', '{Assembleia} aprova reforma tributária por margem apertada. Oposição promete recorrer.'),
('politica', '{republica}', 'Pesquisa: {num}% dos {gentilicos} aprovam o trabalho {de_soberano}.'),
('politica', '{republica}', 'Debate entre candidatos em {capital} termina em troca de acusações.');

-- Economia: "Banco Central" e "Tesouro do país" passam a usar o tesouro do regime.
update public.social_templates set body = '{Tesouro} mantém os juros e sinaliza cautela para os próximos meses.'
  where category = 'economia' and body like 'Banco Central mantém juros%';
update public.social_templates set body = '{Tesouro} anuncia emissão de títulos para financiar obras de infraestrutura.'
  where category = 'economia' and body like 'Tesouro {de_pais} anuncia emissão%';

-- =====================================================================
-- Reinos/impérios compartilhados: vários países sob a mesma coroa.
-- Alemanha + Áustria = Império Germânico (mesmo Imperador).
-- Notícias e fofocas circulam no império inteiro; o personagem continua
-- escolhendo seu país de origem (Alemanha ou Áustria).
-- =====================================================================

alter table public.countries
  add column if not exists realm text references public.countries (code),
  add column if not exists realm_name text,
  add column if not exists realm_de text,
  add column if not exists realm_em text;

update public.countries set
  realm = 'DE', realm_name = 'Império Germânico', realm_de = 'do Império Germânico', realm_em = 'no Império Germânico',
  regime = 'imperio', ruler = 'o Imperador', court = 'a corte imperial',
  council = 'o Conselho Imperial', assembly = 'a Dieta Imperial', treasury = 'o Tesouro Imperial'
where code in ('DE', 'AT');

-- País → código do reino/império a que pertence (ele mesmo, se não fizer parte de nenhum).
create or replace function private.realm_of(p_code text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce(realm, code) from public.countries where code = p_code
$$;

-- Nome, cidades e instituições usados pelas notícias do reino.
create or replace function private.realm_context(p_realm text) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
      'pais', coalesce(k.realm_name, k.name), 'de_pais', coalesce(k.realm_de, k.name_de),
      'em_pais', coalesce(k.realm_em, k.name_em),
      'capital', k.capital, 'moeda', k.currency, 'gentilicos', k.demonym_pl)
    || private.inst_forms('soberano', k.ruler)
    || private.inst_forms('corte', k.court)
    || private.inst_forms('conselho', k.council)
    || private.inst_forms('assembleia', k.assembly)
    || private.inst_forms('tesouro', k.treasury)
  from public.countries k where k.code = p_realm
$$;

create or replace function private.realm_cities(p_realm text) returns text[]
language sql stable security definer set search_path = public as $$
  select array_agg(city) from (
    select unnest(array_prepend(capital, cities)) as city
    from public.countries where coalesce(realm, code) = p_realm
  ) s
$$;

-- --------------------------------------------- notícias do reino inteiro
create or replace function private.social_generate_news(p_country text, p_at timestamptz) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  v_realm text := private.realm_of(p_country);
  k public.countries;
  v_cat text;
  r double precision := random();
  v_tpl public.social_templates;
  v_body text;
  v_author text;
  v_eng integer[];
begin
  select * into k from public.countries where code = v_realm;
  if k.code is null then return; end if;
  v_cat := case when r < 0.4 then 'politica' when r < 0.75 then 'economia' else 'sociedade' end;

  select t.* into v_tpl from public.social_templates t
  where t.category = v_cat and (t.regimes is null or k.regime = any (t.regimes))
  order by
    (select count(*) from public.social_posts p where p.template_id = t.id and p.country_code = v_realm
      and p.subject_character_id is null),
    random()
  limit 1;
  if v_tpl.id is null then return; end if;

  v_body := private.social_fill(v_tpl.body, private.realm_context(v_realm), private.realm_cities(v_realm), null, null);
  -- Jornais de qualquer país do reino.
  select private.pick(array_agg(o)) into v_author
  from public.countries c, unnest(c.outlets) o where coalesce(c.realm, c.code) = v_realm;
  v_eng := private.social_engagement(2500);

  insert into public.social_posts (country_code, subject_character_id, category, template_id,
    author_name, author_handle, author_kind, body, likes, reposts, replies, created_at)
  values (v_realm, null, v_cat, v_tpl.id, v_author, left(replace(private.slugify(v_author), '.', ''), 30),
    'imprensa', v_body, v_eng[1], v_eng[2], v_eng[3], p_at);
end $$;

-- ------------------------------------- fofocas usam o nome do reino
create or replace function private.social_generate_post(p_subject uuid, p_at timestamptz) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
  k public.countries;
  v_realm text;
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
  v_realm := private.realm_of(c.country_code);

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

  v_ctx := private.realm_context(v_realm) || jsonb_build_object(
    'nome', btrim(c.first_name || ' ' || c.last_name),
    'pnome', c.first_name,
    'sobrenome', coalesce(nullif(c.last_name, ''), c.first_name),
    'titulo', coalesce(nullif(lower(left(c.title, 1)) || substr(c.title, 2), ''), 'figura pública'),
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
  v_body := private.social_fill(v_tpl.body, v_ctx, private.realm_cities(v_realm), v_kids, v_family);
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

-- ------------------------------------------ relógio por reino
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
    select distinct private.realm_of(country_code) as realm from public.characters
    where kind = 'player' and active and country_code is not null
  loop
    insert into public.social_country_state (country_code) values (r.realm) on conflict do nothing;
    if (select coalesce(next_news_at <= now(), true) from public.social_country_state where country_code = r.realm) then
      perform private.social_generate_news(r.realm, now());
      update public.social_country_state
        set next_news_at = now() + private.random_interval('social_news_interval_hours', 'hours')
        where country_code = r.realm;
    end if;
  end loop;
end $$;

create or replace function private.social_backfill(p_character uuid) returns void
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
  v_realm text;
  i integer;
begin
  select * into c from public.characters where id = p_character;
  if c.country_code is null then return; end if;
  v_realm := private.realm_of(c.country_code);
  if (select count(*) from public.social_posts where subject_character_id = p_character) < 5 then
    for i in 1..12 loop
      perform private.social_generate_post(p_character, now() - random() * interval '48 hours');
    end loop;
    update public.characters
      set next_social_at = now() + private.random_interval('social_post_interval_hours', 'hours')
      where id = p_character;
  end if;
  if (select count(*) from public.social_posts where country_code = v_realm and subject_character_id is null) < 5 then
    for i in 1..10 loop
      perform private.social_generate_news(v_realm, now() - random() * interval '48 hours');
    end loop;
  end if;
end $$;

-- ------------------------------------------ feed: o reino inteiro
create or replace function public.get_feed(p_character uuid, p_tab text default 'para_voce') returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  c public.characters;
  v_realm text;
  v_realm_countries text[];
begin
  perform private.require_owner(p_character);
  perform public.npc_tick();
  perform private.social_backfill(p_character);
  select * into c from public.characters where id = p_character;
  v_realm := private.realm_of(c.country_code);
  select array_agg(code) into v_realm_countries from public.countries where coalesce(realm, code) = v_realm;

  return jsonb_build_object(
    'countryCode', c.country_code,
    'realmName', (select coalesce(realm_name, name) from public.countries where code = v_realm),
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
          or (p_tab = 'noticias' and p.subject_character_id is null and p.country_code = v_realm)
          or (p_tab not in ('sobre', 'noticias') and (
            p.subject_character_id = p_character
            or p.subject_character_id in (select related_character_id from public.character_relationships
                                          where character_id = p_character)
            or p.country_code = any (v_realm_countries)))
        )
        order by p.created_at desc
        limit 80
      ) s), '[]')
  );
end $$;

revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.owns_character(uuid) to authenticated;
revoke all on function public.get_feed(uuid, text) from public, anon;
grant execute on function public.get_feed(uuid, text) to authenticated;
