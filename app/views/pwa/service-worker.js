const CACHE_VERSION = "encar-stays-v1"
const APP_SHELL = [
  "/offline.html",
  "/icon-192.png",
  "/icon.png",
  "/apple-touch-icon.png"
]

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(key => key !== CACHE_VERSION).map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", event => {
  const request = event.request
  const url = new URL(request.url)

  if (request.method !== "GET" || url.origin !== self.location.origin) return

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(() => caches.match("/offline.html"))
    )
    return
  }

  if (url.pathname.startsWith("/assets/") || APP_SHELL.includes(url.pathname)) {
    event.respondWith(cacheStaticAsset(request))
  }
})

async function cacheStaticAsset(request) {
  const cachedResponse = await caches.match(request)
  if (cachedResponse) return cachedResponse

  const response = await fetch(request)

  if (response.ok) {
    const cache = await caches.open(CACHE_VERSION)
    await cache.put(request, response.clone())
  }

  return response
}
