-- =====================================================================
--  現在ゲームにハードコードされている4店舗を DB に移す（掲載中として投入）
--  ※ owner_id は未設定。出店者アカウントができたら紐づける
-- =====================================================================

insert into public.shops
  (name, sign_text, category, description, ec_url,
   floor, pos_x, display_w, display_h, building_key, npc_key, npc_offset_x,
   status, approved_at)
values
  ('フラワーショップ', 'Flower', '花・ガーデニング',
   '季節のお花をあつめた、いいかおりのお店。ちいさなブーケから記念日の花束までそろいます。',
   null, 'upper',   700, 226, 225, 'shop_flower', 'npc4', -180, 'published', now()),

  ('よろずや ストア', 'Store', '雑貨・日用品',
   '町のくらしに必要なものが、なんでもそろうお店。旅の道具から台所の小物まで。',
   null, 'upper',  1150, 189, 225, 'shop_store',  'npc3', -170, 'published', now()),

  ('ショップ こみち', 'Shop', 'おみやげ・食品',
   'つたのからまる石づくりのお店。町のおみやげと、できたてのお惣菜をならべています。',
   null, 'ground',  900, 287, 250, 'shop_shop',   'npc2', -210, 'published', now()),

  ('シーマーケット', 'SEA MARETT', '海の幸・鮮魚',
   '港からとどいたばかりの魚がならぶ市場。ひものや缶づめのおみやげも人気です。',
   null, 'ground', 2300, 231, 245, 'shop_sea',    'npc1', -200, 'published', now())
on conflict do nothing;

-- 店長のセリフ（5.6）
insert into public.shop_messages (shop_id, body, sort_order)
select s.id, m.body, m.ord
from public.shops s
join (values
  ('フラワーショップ', 'お花はいかがですか〜？',        0),
  ('フラワーショップ', '新しい寄せ植えが入ったよ！',    1),
  ('よろずや ストア',  'いらっしゃい、ゆっくり見ておくれ', 0),
  ('よろずや ストア',  '掘り出しものがあるかもしれんぞ',  1),
  ('ショップ こみち',  'よってらっしゃい！',            0),
  ('ショップ こみち',  '今日のおすすめ、あるよ〜',        1),
  ('シーマーケット',   'とれたての魚があるよ！',         0),
  ('シーマーケット',   'ヒトデもかざってみたんだ',        1)
) as m(shop_name, body, ord) on m.shop_name = s.name
where not exists (
  select 1 from public.shop_messages x where x.shop_id = s.id and x.body = m.body
);
