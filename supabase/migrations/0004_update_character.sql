-- =====================================================================
-- Edição do perfil do personagem (nome, descrição, cor e, opcionalmente,
-- um novo e-mail gerado a partir do nome).
-- =====================================================================

-- Gera um e-mail único ignorando o próprio personagem (para não "colidir" consigo mesmo).
create or replace function private.generate_email_for(p_first text, p_last text, p_self uuid) returns text
language plpgsql volatile security definer set search_path = public as $$
declare
  base text := left(coalesce(nullif(private.slugify(p_first || ' ' || p_last), ''), 'personagem'), 40);
  candidate text := base || '@rpgphone.app';
  n integer := 1;
begin
  while exists (select 1 from public.characters where email = candidate and id <> p_self) loop
    n := n + 1;
    candidate := base || n || '@rpgphone.app';
  end loop;
  return candidate;
end $$;

create or replace function public.update_character(
  p_character uuid,
  p_first_name text,
  p_last_name text,
  p_description text,
  p_avatar_color text,
  p_regenerate_email boolean default false
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v public.characters;
  v_old_email text;
begin
  perform private.require_owner(p_character);
  if char_length(btrim(coalesce(p_first_name, ''))) = 0 then
    raise exception 'Informe o nome do personagem.' using errcode = '22023';
  end if;
  if p_avatar_color is not null and p_avatar_color !~ '^#[0-9a-fA-F]{6}$' then
    raise exception 'Cor inválida.' using errcode = '22023';
  end if;

  select email into v_old_email from public.characters where id = p_character;

  update public.characters set
    first_name = btrim(p_first_name),
    last_name = btrim(coalesce(p_last_name, '')),
    description = btrim(coalesce(p_description, '')),
    avatar_color = coalesce(nullif(p_avatar_color, ''), avatar_color),
    email = case when p_regenerate_email
      then private.generate_email_for(p_first_name, coalesce(p_last_name, ''), p_character)
      else email end
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

revoke all on function private.generate_email_for(text, text, uuid) from public, anon, authenticated;
revoke all on function public.update_character(uuid, text, text, text, text, boolean) from public, anon;
grant execute on function public.update_character(uuid, text, text, text, text, boolean) to authenticated;
