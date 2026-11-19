import { defineConfig } from 'vite';
import { resolve } from 'node:path';

export default defineConfig({
  base: './',
  build: {
    outDir: resolve(process.cwd(), '../../assets/tajweedformer_web'),
    emptyOutDir: true,
    assetsInlineLimit: 0,
    rollupOptions: {
      input: resolve(process.cwd(), 'bridge.js'),
      external: [/^node:/],
      output: { entryFileNames: 'bridge.js' },
    },
  },
});
