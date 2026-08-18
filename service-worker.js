// Minimal service worker — exists purely so Chrome/Android treats this as an
// installable app. It only caches the static shell (HTML, fonts, icons).
// Supabase API calls and CDN scripts are cross-origin and always go straight
// to the network, so your wardrobe data is never served from a stale cache.

const CACHE_NAME = "off-the-peg-shell-v1";
const SHELL_FILES = [
  "./",
  "./index.html",
  "./manifest.json",
  "./fonts/routed-gothic.woff2",
  "./fonts/routed-gothic-italic.woff2",
  "./fonts/routed-gothic-wide.woff2",
  "./icons/icon-192.png",
  "./icons/icon-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(SHELL_FILES))
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
  // Only intervene for same-origin GET requests (the app shell).
  // Everything else — Supabase, Google Fonts, the supabase-js CDN script — passes straight through.
  if (event.request.method !== "GET" || url.origin !== self.location.origin) {
    return;
  }
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
