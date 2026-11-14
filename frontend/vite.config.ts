import { readFileSync } from 'node:fs'
import path from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig, type Connect, type Plugin } from 'vite'

const llmsTxt = path.resolve(import.meta.dirname, '../llms.txt')
const publico = path.resolve(import.meta.dirname, 'public')

const rutasSpa = [
  /^\/$/,
  /^\/login$/,
  /^\/mis-tareas$/,
  /^\/ordenes$/,
  /^\/ordenes\/[^/]+$/,
  /^\/repuestos$/,
  /^\/repuestos\/proveedores$/,
  /^\/clientes$/,
  /^\/vehiculos$/,
  /^\/vehiculos\/[^/]+\/historial$/,
  /^\/casos$/,
  /^\/aseguradoras$/,
  /^\/usuarios$/,
  /^\/tareas-frecuentes$/,
  /^\/reportes\/tareas-por-mecanico$/,
  /^\/reportes\/margen-repuestos$/,
  /^\/reportes\/tareas-frecuentes$/,
  /^\/configuracion$/,
]

const paginas: Record<string, string> = {
  '/about': 'about',
  '/contact': 'contact',
  '/privacy': 'privacy',
  '/docs': 'docs',
}

const markdownApp = `# Gestión de Taller

Esta pantalla es de la aplicación y pide sesión. Sin cuenta no se ven clientes, vehículos ni órdenes.

- [Inicio](/)
- [Documentación de la API](/docs)
- [Mapa del sitio](/sitemap.xml)
- [llms.txt](/llms.txt)
`

const servirLlmsTxt: Connect.NextHandleFunction = (req, res, next) => {
  const url = req.url?.split('?')[0]
  const metodo = req.method ?? 'GET'
  if (url !== '/llms.txt' || (metodo !== 'GET' && metodo !== 'HEAD')) {
    next()
    return
  }

  const cuerpo = readFileSync(llmsTxt)
  res.statusCode = 200
  res.setHeader('Content-Type', 'text/plain; charset=utf-8')
  res.setHeader('Cache-Control', 'public, max-age=600')
  res.setHeader('Content-Length', cuerpo.byteLength)
  res.end(metodo === 'HEAD' ? undefined : cuerpo)
}

type Rango = { tipo: string; q: number }

function rutaDe(url: string | undefined) {
  const sola = url?.split('?')[0] || '/'
  if (sola.length > 1 && sola.endsWith('/')) return sola.slice(0, -1)
  return sola
}

function parsearRango(parte: string): Rango | null {
  const trozos = parte.split(';').map((item) => item.trim())
  const tipo = (trozos.shift() ?? '').toLowerCase()
  if (!tipo) return null

  let q = 1
  for (const parametro of trozos) {
    const [clave, valor] = parametro.split('=', 2)
    if (clave?.toLowerCase() === 'q' && valor) q = Number(valor)
  }
  if (!Number.isFinite(q)) q = 1
  return { tipo, q: Math.min(1, Math.max(0, q)) }
}

function especificidad(rango: string, media: string, tipo: string) {
  const [rangoTipo, rangoSubtipo] = rango.split('/')
  if (rango === media) return 3
  if (rangoTipo === tipo && rangoSubtipo === '*') return 2
  if (rango === '*/*') return 1
  return -1
}

function calidad(rangos: Rango[], media: string) {
  const [tipo] = media.split('/')
  let mejorEspecificidad = -1
  let mejorQ = 0
  for (const rango of rangos) {
    const peso = especificidad(rango.tipo, media, tipo)
    if (peso < 0 || peso < mejorEspecificidad) continue
    if (peso > mejorEspecificidad) {
      mejorEspecificidad = peso
      mejorQ = rango.q
    } else if (rango.q > mejorQ) {
      mejorQ = rango.q
    }
  }
  return mejorQ
}

function preferenciaDe(accept: string | undefined) {
  const header = accept?.trim() ?? ''
  if (!header) return 'html' as const

  const rangos = header
    .split(',')
    .map(parsearRango)
    .filter((rango): rango is Rango => rango !== null)
  const qHtml = calidad(rangos, 'text/html')
  const qMarkdown = calidad(rangos, 'text/markdown')
  if (qHtml <= 0 && qMarkdown <= 0) return 'ninguna' as const
  return qMarkdown > qHtml ? ('markdown' as const) : ('html' as const)
}

function esSpa(ruta: string) {
  return rutasSpa.some((patron) => patron.test(ruta))
}

function esInterno(ruta: string) {
  return (
    ruta.startsWith('/@') ||
    ruta.startsWith('/src/') ||
    ruta.startsWith('/node_modules/') ||
    ruta.startsWith('/__vite')
  )
}

function tieneExtension(ruta: string) {
  const base = ruta.split('/').pop() ?? ''
  return base.includes('.')
}

function escaparHtml(valor: string) {
  return valor
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
}

function rutaVisible(ruta: string) {
  return [...ruta].filter((letra) => letra >= ' ' && letra !== '\u007f').join('').slice(0, 200)
}

function markdownNoEncontrado(ruta: string) {
  const visible = rutaVisible(ruta).replaceAll('`', '')
  return `# No encontrado

La ruta \`${visible}\` no existe en Gestión de Taller.

- [Inicio](/)
- [Documentación de la API](/docs)
- [Mapa del sitio](/sitemap.xml)
- [llms.txt](/llms.txt)
`
}

function htmlNoEncontrado(ruta: string) {
  const visible = escaparHtml(rutaVisible(ruta))
  return `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <title>No encontrado · Gestión de Taller</title>
    <link rel="stylesheet" href="/publico.css" />
  </head>
  <body>
    <main class="publico">
      <p class="kicker">Gestión de Taller</p>
      <h1>No encontrado</h1>
      <p>La ruta ${visible} no existe.</p>
      <nav aria-label="Páginas públicas">
        <a href="/">Inicio</a>
        <a href="/docs">Documentación</a>
        <a href="/sitemap.xml">Mapa del sitio</a>
        <a href="/llms.txt">llms.txt</a>
      </nav>
    </main>
  </body>
</html>
`
}

function terminar(
  res: import('node:http').ServerResponse,
  metodo: string,
  status: number,
  contentType: string,
  cuerpo: Buffer | string,
) {
  const bytes = Buffer.isBuffer(cuerpo) ? cuerpo : Buffer.from(cuerpo)
  res.statusCode = status
  res.setHeader('Content-Type', contentType)
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Vary', 'Accept')
  res.setHeader('Content-Length', bytes.byteLength)
  res.end(metodo === 'HEAD' ? undefined : bytes)
}

function cuerpoMarkdown(ruta: string) {
  if (esSpa(ruta) && ruta !== '/') return markdownApp
  const nombre = ruta === '/' ? 'home.md' : `${paginas[ruta]}.md`
  try {
    return readFileSync(path.join(publico, nombre))
  } catch {
    return null
  }
}

const negociar: Connect.NextHandleFunction = (req, res, next) => {
  const metodo = req.method ?? 'GET'
  if (metodo !== 'GET' && metodo !== 'HEAD') {
    next()
    return
  }

  const ruta = rutaDe(req.url)
  if (ruta === '/.well-known/api-catalog') {
    try {
      const cuerpo = readFileSync(path.join(publico, '.well-known/api-catalog'))
      res.statusCode = 200
      res.setHeader(
        'Content-Type',
        'application/linkset+json;profile="https://www.rfc-editor.org/info/rfc9727"',
      )
      res.setHeader('Cache-Control', 'no-cache')
      res.setHeader('Content-Length', cuerpo.byteLength)
      res.end(metodo === 'HEAD' ? undefined : cuerpo)
    } catch {
      terminar(res, metodo, 404, 'text/markdown; charset=utf-8', markdownNoEncontrado(ruta))
    }
    return
  }

  if (esInterno(ruta) || tieneExtension(ruta)) {
    next()
    return
  }

  const preferencia = preferenciaDe(req.headers.accept)
  if (preferencia === 'ninguna') {
    terminar(
      res,
      metodo,
      406,
      'text/plain; charset=utf-8',
      'Esta página se sirve como text/html o text/markdown.\n',
    )
    return
  }

  if (preferencia === 'markdown' && (ruta === '/' || paginas[ruta] || esSpa(ruta))) {
    const cuerpo = cuerpoMarkdown(ruta)
    if (cuerpo) {
      terminar(res, metodo, 200, 'text/markdown; charset=utf-8', cuerpo)
      return
    }
    terminar(res, metodo, 404, 'text/markdown; charset=utf-8', markdownNoEncontrado(ruta))
    return
  }

  if (ruta === '/' || esSpa(ruta)) {
    next()
    return
  }

  if (paginas[ruta]) {
    try {
      const cuerpo = readFileSync(path.join(publico, `${paginas[ruta]}.html`))
      terminar(res, metodo, 200, 'text/html; charset=utf-8', cuerpo)
    } catch {
      terminar(res, metodo, 404, 'text/html; charset=utf-8', htmlNoEncontrado(ruta))
    }
    return
  }

  if (preferencia === 'markdown') {
    terminar(res, metodo, 404, 'text/markdown; charset=utf-8', markdownNoEncontrado(ruta))
    return
  }

  terminar(res, metodo, 404, 'text/html; charset=utf-8', htmlNoEncontrado(ruta))
}

function exponerLlmsTxt(): Plugin {
  return {
    name: 'llms-txt',
    configureServer(server) {
      server.middlewares.use(servirLlmsTxt)
      server.middlewares.use(negociar)
    },
    configurePreviewServer(server) {
      server.middlewares.use(servirLlmsTxt)
      server.middlewares.use(negociar)
    },
    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: 'llms.txt',
        source: readFileSync(llmsTxt),
      })
    },
  }
}

export default defineConfig({
  plugins: [react(), exponerLlmsTxt()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
  },
})
