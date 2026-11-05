import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Caminhos relativos: o mesmo build funciona em usuario.github.io/rpg-phone/ e dentro do Discord.
  base: './',
  server: {
    port: 5173,
    strictPort: true,
    // O projeto fica no OneDrive, que às vezes não avisa o Vite sobre arquivos alterados.
    watch: { usePolling: true, interval: 300 },
  },
});
