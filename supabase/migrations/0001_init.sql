-- =====================================================================
--  TownWalk 初期スキーマ
--  仕様書 7章（データモデル）/ 5.4（出店審査）/ 5.8（スタンプ）に対応
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- 列挙型 ----------
do $$ begin
  create type public.user_role   as enum ('user','owner','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  -- pending=審査中 / published=掲載中 / rejected=差し戻し / closed=掲載終了
  create type public.shop_status as enum ('draft','pending','published','rejected','closed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.shop_floor  as enum ('ground','upper');
exception when duplicate_object then null; end $$;


-- =====================================================================
--  profiles : auth.users の付随情報
-- =====================================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text        not null default 'プレイヤー',
  role          public.user_role not null default 'user',
  avatar_key    text        not null default 'p_r',
  coins         integer     not null default 0 check (coins >= 0),
  exp           integer     not null default 0 check (exp   >= 0),
  walked_px     bigint      not null default 0 check (walked_px >= 0),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- =====================================================================
--  shops : 店舗（掲載ステータスと配置情報を持つ）
--  ※ 配置系カラムは 5.4「管理者が承認画面で自由に編集できる」ための項目
-- =====================================================================
create table if not exists public.shops (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid references auth.users(id) on delete set null,

  -- 掲載内容
  name            text        not null,
  sign_text       text,                      -- 建物看板の文字（Flower / Store …）
  category        text        not null default '',
  description     text        not null default '',
  ec_url          text,                      -- 外部ECサイト（5.5：リンクのみ）

  -- フィールド配置
  floor           public.shop_floor not null default 'ground',
  pos_x           integer     not null default 0,
  display_w       integer     not null default 250,
  display_h       integer     not null default 250,
  building_key    text,                      -- 画像アセットのキー
  npc_key         text,
  npc_offset_x    integer     not null default -180,

  -- 審査 / 掲載
  status          public.shop_status not null default 'pending',
  listing_fee_yen integer,                   -- 一律プラン（金額は運用で確定）
  applied_at      timestamptz not null default now(),
  sla_due_at      timestamptz,               -- 3営業日後（営業日計算はアプリ側）
  approved_at     timestamptz,
  reject_reason   text,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists shops_status_idx on public.shops(status);
create index if not exists shops_owner_idx  on public.shops(owner_id);
create index if not exists shops_place_idx  on public.shops(floor, pos_x);

-- =====================================================================
--  shop_photos : 店内写真（5.3）
-- =====================================================================
create table if not exists public.shop_photos (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references public.shops(id) on delete cascade,
  storage_path text not null,                -- Supabase Storage 上のパス
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists shop_photos_shop_idx on public.shop_photos(shop_id, sort_order);

-- =====================================================================
--  shop_messages : 店長の吹き出しセリフ（5.6）
-- =====================================================================
create table if not exists public.shop_messages (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references public.shops(id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 60),
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists shop_messages_shop_idx on public.shop_messages(shop_id, sort_order);

-- =====================================================================
--  stamps : スタンプラリー（5.8）初回入店のみ記録
-- =====================================================================
create table if not exists public.stamps (
  user_id    uuid not null references auth.users(id) on delete cascade,
  shop_id    uuid not null references public.shops(id) on delete cascade,
  visited_at timestamptz not null default now(),
  primary key (user_id, shop_id)
);

-- =====================================================================
--  ec_clicks : EC送客の計測（5.5）
-- =====================================================================
create table if not exists public.ec_clicks (
  id         bigserial primary key,
  shop_id    uuid not null references public.shops(id) on delete cascade,
  user_id    uuid references auth.users(id) on delete set null,
  clicked_at timestamptz not null default now()
);
create index if not exists ec_clicks_shop_idx on public.ec_clicks(shop_id, clicked_at desc);

-- ※ 挨拶リアクション（5.7）は揮発データなので DB に保存せず Realtime broadcast で送る


-- =====================================================================
--  共通トリガ : updated_at
-- =====================================================================
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists shops_touch on public.shops;
create trigger shops_touch before update on public.shops
  for each row execute function public.touch_updated_at();

-- =====================================================================
--  サインアップ時に profiles を自動作成
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'プレイヤー'))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
--  管理者判定（RLS の再帰を避けるため security definer）
-- =====================================================================
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- =====================================================================
--  role 昇格の防止（管理者以外は role を変更できない）
-- =====================================================================
create or replace function public.guard_profile_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> old.role and not public.is_admin() then
    raise exception 'role は変更できません';
  end if;
  return new;
end $$;

drop trigger if exists profiles_role_guard on public.profiles;
create trigger profiles_role_guard before update on public.profiles
  for each row execute function public.guard_profile_role();


-- =====================================================================
--  RLS
-- =====================================================================
alter table public.profiles      enable row level security;
alter table public.shops         enable row level security;
alter table public.shop_photos   enable row level security;
alter table public.shop_messages enable row level security;
alter table public.stamps        enable row level security;
alter table public.ec_clicks     enable row level security;

-- ---------- profiles ----------
drop policy if exists profiles_read      on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;

-- 他プレイヤーの表示名を出すため読み取りは公開
create policy profiles_read on public.profiles
  for select using (true);
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid() or public.is_admin());

-- ---------- shops ----------
drop policy if exists shops_read_published on public.shops;
drop policy if exists shops_insert_own     on public.shops;
drop policy if exists shops_update_own     on public.shops;
drop policy if exists shops_admin_all      on public.shops;

-- 掲載中はだれでも閲覧（ゲーム画面用）
create policy shops_read_published on public.shops
  for select using (
    status = 'published' or owner_id = auth.uid() or public.is_admin()
  );
-- 出店申請：必ず自分名義・審査中で作成させる
create policy shops_insert_own on public.shops
  for insert to authenticated
  with check (owner_id = auth.uid() and status = 'pending');
-- 差し戻し／審査中のあいだは出店者が修正できる
create policy shops_update_own on public.shops
  for update to authenticated
  using (owner_id = auth.uid() and status in ('draft','pending','rejected'))
  with check (owner_id = auth.uid() and status in ('draft','pending','rejected'));
-- 管理者は承認・編集・掲載終了まで全権（5.4）
create policy shops_admin_all on public.shops
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- shop_photos / shop_messages : 親店舗の可視性に従う ----------
drop policy if exists shop_photos_read on public.shop_photos;
drop policy if exists shop_photos_write on public.shop_photos;
create policy shop_photos_read on public.shop_photos
  for select using (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.status = 'published' or s.owner_id = auth.uid() or public.is_admin())
  ));
create policy shop_photos_write on public.shop_photos
  for all to authenticated using (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.owner_id = auth.uid() or public.is_admin())
  )) with check (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.owner_id = auth.uid() or public.is_admin())
  ));

drop policy if exists shop_messages_read on public.shop_messages;
drop policy if exists shop_messages_write on public.shop_messages;
create policy shop_messages_read on public.shop_messages
  for select using (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.status = 'published' or s.owner_id = auth.uid() or public.is_admin())
  ));
create policy shop_messages_write on public.shop_messages
  for all to authenticated using (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.owner_id = auth.uid() or public.is_admin())
  )) with check (exists (
    select 1 from public.shops s where s.id = shop_id
      and (s.owner_id = auth.uid() or public.is_admin())
  ));

-- ---------- stamps : 本人のみ ----------
drop policy if exists stamps_own on public.stamps;
create policy stamps_own on public.stamps
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- ec_clicks : 記録は誰でも / 閲覧は管理者と店舗オーナー ----------
drop policy if exists ec_clicks_insert on public.ec_clicks;
drop policy if exists ec_clicks_read   on public.ec_clicks;
create policy ec_clicks_insert on public.ec_clicks
  for insert to anon, authenticated with check (true);
create policy ec_clicks_read on public.ec_clicks
  for select to authenticated using (
    public.is_admin() or exists (
      select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid()
    )
  );

-- =====================================================================
--  ゲーム画面が読む公開ビュー（掲載中の店舗のみ・機密カラムを除外）
-- =====================================================================
create or replace view public.published_shops
with (security_invoker = true) as
select id, name, sign_text, category, description, ec_url,
       floor, pos_x, display_w, display_h, building_key, npc_key, npc_offset_x
from public.shops
where status = 'published'
order by floor, pos_x;

-- =====================================================================
--  権限（RLS が実際のアクセス制御を行う）
-- =====================================================================
grant usage on schema public to anon, authenticated;

grant select                         on public.profiles      to anon, authenticated;
grant insert, update                 on public.profiles      to authenticated;

grant select                         on public.shops         to anon, authenticated;
grant insert, update                 on public.shops         to authenticated;
grant delete                         on public.shops         to authenticated; -- RLS で管理者のみ

grant select                         on public.shop_photos   to anon, authenticated;
grant insert, update, delete         on public.shop_photos   to authenticated;

grant select                         on public.shop_messages to anon, authenticated;
grant insert, update, delete         on public.shop_messages to authenticated;

grant select, insert, delete         on public.stamps        to authenticated;

grant insert                         on public.ec_clicks     to anon, authenticated;
grant select                         on public.ec_clicks     to authenticated;
grant usage, select on sequence public.ec_clicks_id_seq to anon, authenticated;

grant select on public.published_shops to anon, authenticated;
