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
