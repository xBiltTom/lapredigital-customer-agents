import { eveChannel } from 'eve/channels/eve';
import { autenticarDueno, autenticarTerminalLocal } from '../../lib/auth.ts';

// La publicación por Docker no cambia la identidad ni permite acceso anónimo.
export default eveChannel({ auth: [autenticarDueno, autenticarTerminalLocal] });
