// Minimal service worker: exists purely so Chrome/Android treats this as an
// installable app. Only truly static assets (fonts, icons) are cache-first.
// The HTML shell, manifest, and styles.css are all network-first: anything
// that changes during active development must never be cache-first, or an
// installed copy can get stuck showing an old version indefinitely.

const CACHE_NAME = "off-the-peg-shell-v5";
const STATIC_ASSETS = [
  "./fonts/routed-gothic.woff2",
  "./fonts/routed-gothic-italic.woff2",
  "./fonts/routed-gothic-wide.woff2",
  "./fonts/ibm-plex-sans.woff2",
  "./fonts/ibm-plex-mono.woff2",
  "./fonts/ibm-plex-mono-medium.woff2",
  "./icons/icon-192.png",
  "./icons/icon-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== "GET" || url.origin !== self.location.origin) {
    return; // cross-origin (Supabase, CDN scripts) always goes straight to network
  }

  const isShellDoc = url.pathname.endsWith("/") || url.pathname.endsWith("index.html") || url.pathname.endsWith("manifest.json") || url.pathname.endsWith("styles.css");
  if (isShellDoc) {
    // Network-first: always try to get the latest HTML/manifest. Only fall
    // back to a cached copy if there's genuinely no connection.
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Cache-first for static assets that genuinely don't change often.
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
