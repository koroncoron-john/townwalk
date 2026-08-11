// Supabase 接続設定
// この2つは「公開してよい値」です。実際のアクセス制御は DB 側の RLS が行います。
window.TW_CONFIG = {
  SUPABASE_URL: 'https://stojpxqjozcwtheffgsv.supabase.co',
  SUPABASE_KEY: 'sb_publishable_y9kkbv9FooxQ89EfX2BsBg_gBTVJuyJ',

  // フィールドの座標定数（ゲーム本体と管理画面プレビューで共有）
  // 支給画像の実測値から算出：ground(1814x230)の芝面=高さの32% / platform(1213x166)=23%
  LAYOUT: {
    W: 9600, SH: 864,                 // 横スクロール領域（2600 → 9600 に拡張）
    GROUND_Y: 700, UPPER_Y: 372,
    GROUND_H: 330, GROUND_TOP: 595,
    GROUND_TILE_W: 2583,              // ground_tile.webp(1800px) を高さ330に合わせた表示幅
    PLAT_H: 166, PLAT_TOP: 334,
    LADDER_W: 135, LADDER_TOP: 356, LADDER_H: 352, LADDER_HALF: 58,
    SINK_SHOP: 8, SINK_CHAR: 4,
    NPC_H: 130,

    // 2階の足場（各エリアに1つ）と、そこへ上がる縄ばしご
    PLATFORMS: [
      { x:  330, w: 1213 },
      { x: 2730, w: 1213 },
      { x: 5130, w: 1213 },
      { x: 7530, w: 1213 },
    ],
    LADDERS: [430, 2830, 5230, 7630],

    // 1階の配置可能範囲（2階は PLATFORMS から自動算出）
    GROUND_RANGE: [90, 9510],
    PLAT_MARGIN: 60,                  // 足場の端から内側にこれだけ空ける
  },

  // 季節の背景（実際の月で切り替わる）
  SEASONS: [
    { key: 'bg_spring', label: '春', months: [3, 4, 5] },
    { key: 'bg_summer', label: '夏', months: [6, 7, 8] },
    { key: 'bg_autumn', label: '秋', months: [9, 10, 11] },
    { key: 'bg_winter', label: '冬', months: [12, 1, 2] },
  ],

  // 建物画像（assets/*.webp のキー）
  BUILDINGS: [
    { key: 'shop_flower', label: '花のドーム（Flower）' },
    { key: 'shop_store',  label: '青ストライプ＋王冠（Store）' },
    { key: 'shop_shop',   label: '石づくり緑屋根（Shop）' },
    { key: 'shop_sea',    label: '青ストライプ＋ヒトデ（SEA MARETT）' },
  ],

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

// 今の月から季節を決める（3-5春 / 6-8夏 / 9-11秋 / 12-2冬）
window.TW_CONFIG.currentSeason = function (date) {
  const m = (date || new Date()).getMonth() + 1;
  return this.SEASONS.find(s => s.months.includes(m)) || this.SEASONS[1];
};

// 2階の足場のうち x を含むものを返す
window.TW_CONFIG.platformAt = function (x) {
  return this.LAYOUT.PLATFORMS.find(p => x >= p.x && x <= p.x + p.w) || null;
};
