-- =====================================================================
-- O jogador escolhe o e-mail do personagem (no cadastro e na edição).
-- Se não informar, o sistema gera um a partir do nome (@rpgphone.app).
-- O endereço é fictício: existe só dentro do jogo e precisa ser único.
-- =====================================================================

create or replace function private.normalize_custom_email(p_email text, p_self uuid) returns text
language plpgsql stable security definer set search_path = public as $$
declare
  e text := lower(btrim(coalesce(p_email, '')));
begin
  if e = '' then return null; end if;
  if char_length(e) > 120 or e !~ '^[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$' then
    raise exception 'E-mail inválido: %', e using errcode = '22023';
  end if;
  if exists (select 1 from public.characters where email = e and id is distinct from p_self) then
    raise exception 'Este e-mail já é usado por outro personagem.' using errcode = '23505';
  end if;
  return e;
end $$;

-- Substitui as versões anteriores (assinaturas novas, com p_email).
drop function if exists public.create_character(text, text, text, text);
drop function if exists public.update_character(uuid, text, text, text, text, boolean);

create function public.create_character(
  p_first_name text, p_last_name text, p_description text default '',
  p_avatar_color text default null, p_email text default null
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
    coalesce(private.normalize_custom_email(p_email, null),
             private.generate_email(p_first_name, coalesce(p_last_name, ''))),
    private.generate_phone(),
    coalesce(nullif(p_avatar_color, ''), private.random_color()))
  returning * into v;

  perform private.audit('character.create', 'character', v.id);
  return private.character_json(v);
end $$;

create function public.update_character(
  p_character uuid,
  p_first_name text,
  p_last_name text,
  p_description text,
  p_avatar_color text,
  p_email text default null
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

  select email into v_old_email from public.characters where id = p_character;
  v_new_email := coalesce(private.normalize_custom_email(p_email, p_character), v_old_email);

  update public.characters set
    first_name = btrim(p_first_name),
    last_name = btrim(coalesce(p_last_name, '')),
    description = btrim(coalesce(p_description, '')),
    avatar_color = coalesce(nullif(p_avatar_color, ''), avatar_color),
    email = v_new_email
  where id = p_character
  returning * into v;

  -- Rascunhos de outros personagens que apontavam para o endereço antigo.
  if v.email <> v_old_email then
    update public.email_drafts set to_addresses = array_replace(to_addresses, v_old_email, v.email)
    where v_old_email = any (to_addresses);
  end if;

  perform private.audit('character.update', 'character', v.id,
    jsonb_build_object('email_changed', v.email <> v_old_email, 'old_email', v_old_email));
  return private.character_json(v);
end $$;

revoke all on function private.normalize_custom_email(text, uuid) from public, anon, authenticated;
revoke all on function public.create_character(text, text, text, text, text) from public, anon;
revoke all on function public.update_character(uuid, text, text, text, text, text) from public, anon;
grant execute on function public.create_character(text, text, text, text, text) to authenticated;
grant execute on function public.update_character(uuid, text, text, text, text, text) to authenticated;
