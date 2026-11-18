const VERSION = 'taller-v1'
const SHELL = ['/', '/manifest.webmanifest', '/icons/icon-192.png', '/icons/icon-512.png']

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(VERSION).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((claves) => Promise.all(claves.filter((clave) => clave !== VERSION).map((clave) => caches.delete(clave))))
      .then(() => self.clients.claim()),
  )
})

async function guardar(request, response) {
  if (response.ok && response.type === 'basic') {
    const cache = await caches.open(VERSION)
    await cache.put(request, response.clone())
  }
  return response
}

async function navegacion(request) {
  try {
    return await guardar(request, await fetch(request))
  } catch {
    return (await caches.match(request)) || (await caches.match('/')) || Response.error()
  }
}

async function activo(request) {
  const guardado = await caches.match(request)
  if (guardado) return guardado
  return guardar(request, await fetch(request))
}

async function revalidar(request) {
  const guardado = await caches.match(request)
  const red = fetch(request).then((respuesta) => guardar(request, respuesta)).catch(() => guardado)
  return guardado || red
}

self.addEventListener('fetch', (event) => {
  const { request } = event
  if (request.method !== 'GET') return

  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return
  if (url.pathname.startsWith('/api') || url.pathname.startsWith('/cable') || url.pathname === '/sw.js') return

  if (request.mode === 'navigate') {
    event.respondWith(navegacion(request))
  } else if (url.pathname.startsWith('/assets/')) {
    event.respondWith(activo(request))
  } else {
    event.respondWith(revalidar(request))
  }
})
