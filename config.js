// Supabase 接続設定
// この2つは「公開してよい値」です。実際のアクセス制御は DB 側の RLS が行います。
window.TW_CONFIG = {
  SUPABASE_URL: 'https://stojpxqjozcwtheffgsv.supabase.co',
  SUPABASE_KEY: 'sb_publishable_y9kkbv9FooxQ89EfX2BsBg_gBTVJuyJ',

  // 建物画像（assets/*.webp のキー）
  BUILDINGS: [
    { key: 'shop_flower', label: '花のドーム（Flower）' },
    { key: 'shop_store',  label: '青ストライプ＋王冠（Store）' },
    { key: 'shop_shop',   label: '石づくり緑屋根（Shop）' },
    { key: 'shop_sea',    label: '青ストライプ＋ヒトデ（SEA MARETT）' },
  ],

  // 店長（オーナー）キャラクター
  NPCS: [
    { key: 'npc5', label: '村人（女性・赤ずきん）' },
    { key: 'npc6', label: '町娘（緑ボンネット）' },
    { key: 'npc3', label: '行商の老人（緑ベレー）' },
    { key: 'npc2', label: '商人（赤ターバン）' },
    { key: 'npc1', label: '錬金術師（赤髪ゴーグル）' },
    { key: 'npc4', label: '鍛冶屋（赤バンダナ）' },
  ],
};
