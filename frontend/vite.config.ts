import { readFileSync } from 'node:fs'
import path from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig, type Connect, type Plugin } from 'vite'

const llmsTxt = path.resolve(import.meta.dirname, '../llms.txt')

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

function exponerLlmsTxt(): Plugin {
  return {
    name: 'llms-txt',
    configureServer(server) {
      server.middlewares.use(servirLlmsTxt)
    },
    configurePreviewServer(server) {
      server.middlewares.use(servirLlmsTxt)
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

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), exponerLlmsTxt()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
  },
})
