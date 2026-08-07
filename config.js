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

  // フィールドの座標定数（ゲーム本体と管理画面プレビューで共有）
  // 支給画像の実測値から算出：ground(1814x230)の芝面=高さの32% / platform(1213x166)=23%
  LAYOUT: {
    W: 2600, SH: 864,
    GROUND_Y: 700, UPPER_Y: 372,
    GROUND_H: 330, GROUND_TOP: 595,
    PLAT_X: 330, PLAT_W: 1213, PLAT_H: 166, PLAT_TOP: 334,
    LADDER_X: 430, LADDER_W: 135, LADDER_TOP: 356, LADDER_H: 352,
    SINK_SHOP: 8, SINK_CHAR: 4,
    NPC_H: 130,
    // 配置できる X の範囲
    RANGE: { ground: [90, 2510], upper: [380, 1510] },
  },

  // 店長キャラの実寸比（トリミング後の 横/縦）— 表示幅の算出用
  NPC_AR: { npc1:106/122, npc2:124/133, npc3:101/131, npc4:105/128, npc5:94/130, npc6:90/121 },

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
