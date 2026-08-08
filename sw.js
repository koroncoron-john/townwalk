/* TownWalk Service Worker
   - assets/ は変わらない前提でキャッシュ優先（表示が速い）
   - HTML と config.js はネット優先（更新をすぐ反映）
   - Supabase など別ドメインへの通信には触らない
*/
const VERSION = 'v1';
const CACHE   = `townwalk-${VERSION}`;

const SHELL = [
  './',
  './index.html',
  './config.js?v=2',
  './manifest.webmanifest',
  './assets/mp1.woff2',
  './assets/bg.webp',
  './assets/ground.webp',
  './assets/platform.webp',
  './assets/ladder.webp',
  './assets/shop_shop.webp',
  './assets/shop_flower.webp',
  './assets/shop_store.webp',
  './assets/shop_sea.webp',
  './assets/npc1.webp', './assets/npc2.webp', './assets/npc3.webp',
  './assets/npc4.webp', './assets/npc5.webp', './assets/npc6.webp',
  './assets/p_l.webp', './assets/p_r.webp', './assets/p_up.webp',
  './assets/icon-192.png', './assets/icon-512.png',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      // 1つでも失敗すると全部入らないので個別に入れる
      .then(c => Promise.allSettled(SHELL.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;   // Supabase / CDN は素通し

  const isAsset = url.pathname.includes('/assets/');

  if (isAsset) {
    // キャッシュ優先。無ければ取りにいって保存
    e.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
        return res;
      }))
    );
    return;
  }

  // HTML・config.js など：ネット優先、失敗したらキャッシュ
  e.respondWith(
    fetch(req)
      .then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
        return res;
      })
      .catch(() => caches.match(req).then(hit => hit || caches.match('./index.html')))
  );
});
