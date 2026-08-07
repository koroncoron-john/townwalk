-- role 昇格ガードの修正
--
-- 修正前は auth.uid() が null（＝service_role やSQLエディタからの操作）でも
-- 例外を投げていたため、最初の管理者を作れなかった。
-- エンドユーザーのリクエストでは auth.uid() が必ず入るので、
-- null のときはサーバー側の信頼された操作とみなして許可する。
create or replace function public.guard_profile_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null          -- ユーザー経由のリクエストのときだけ検査
     and not public.is_admin() then
    raise exception 'role は変更できません';
  end if;
  return new;
end $$;

-- 最初の管理者を作るとき（メールアドレスを書き換えて実行）
--   update public.profiles set role='admin'
--    where id = (select id from auth.users where email='you@example.com');
