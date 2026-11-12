import { eveChannel } from 'eve/channels/eve';

// T04 solo expone salud. No aceptar sesiones antes de verificar T05.
// La salud publica de Eve no dispara una llamada al modelo.
export default eveChannel({ auth: [] });
