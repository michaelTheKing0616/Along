import { handleSendSmsDefault } from './handler.ts';

Deno.serve((req) => handleSendSmsDefault(req));

export { handleSendSmsDefault, sendSmsHookSchema } from './handler.ts';
