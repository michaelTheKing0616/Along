import { handleStagingOtpDefault } from './handler.ts';

Deno.serve((req) => handleStagingOtpDefault(req));
