import { defineAgent } from 'eve';
import { chatgpt } from 'eve/models/openai';
import { loadConfig } from '../lib/config.js';

loadConfig();

// El login y una llamada real se verifican en T05. No hay fallback de pago.
export default defineAgent({
  model: chatgpt(),
  defaultTools: false,
});
