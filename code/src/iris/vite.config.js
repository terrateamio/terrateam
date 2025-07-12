import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { sveltePreprocess } from 'svelte-preprocess'

export default defineConfig({
  plugins: [
    svelte({
      preprocess: sveltePreprocess({
        typescript: true,
      }),
    }),
  ],
  assetsInclude: ['**/*.svg'],
  resolve: {
    alias: {
      $lib: new URL('./src/lib', import.meta.url).pathname,
    },
  },
  server: {
    // Allow requests from app.terrateam.io (our nginx proxy)
    allowedHosts: ['app.terrateam.io', 'localhost'],
    // Remove the proxy since nginx handles it now
  }
})
