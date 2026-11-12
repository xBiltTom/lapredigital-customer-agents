import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({plugins:[react()],server:{proxy:{'/api':{target:process.env.API_TARGET??'http://server:3000',changeOrigin:false},'/eve':{target:process.env.API_TARGET??'http://server:3000',changeOrigin:false}}},build:{outDir:'.dist'}});
