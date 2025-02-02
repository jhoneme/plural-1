import { defineConfig, mergeConfig } from 'vite'

import react from '@vitejs/plugin-react'
import basicSsl from '@vitejs/plugin-basic-ssl'
import nodePolyfills from 'rollup-plugin-polyfill-node'
import { VitePWA } from 'vite-plugin-pwa'

import vitestConfig from './vitest.config'

// https://vitejs.dev/config/
export default mergeConfig(vitestConfig, defineConfig({
  plugins: [
    basicSsl(),
    react(),
    VitePWA({
      injectRegister: null,
      filename: 'service-worker.ts',
      srcDir: 'src',
      strategies: 'injectManifest',
    }),
  ],
  server: {
    port: 3001,
    https: true,
  },
  define: {
    'process.env': {}, // Needed otherwise production build will fail with Uncaught ReferenceError: process is not defined. See https://github.com/vitejs/vite/issues/1973
  },
  build: {
    outDir: 'build',
    sourcemap: process.env.NODE_ENV !== 'production', // Seems to cause JavaScript heap out of memory errors on build
    rollupOptions: {
      plugins: [
        nodePolyfills,
      ],
    },
  },
  resolve: {
    alias: {
      process: 'process/browser',
      stream: 'stream-browserify',
      zlib: 'browserify-zlib',
      util: 'util',
    },
  },
}))
