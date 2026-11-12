import { eveChannel } from 'eve/channels/eve';
import { localDev } from 'eve/channels/auth';

// Solo eve dev admite sesiones locales; eve start sigue rechazando accesos.
export default eveChannel({ auth: [localDev()] });
