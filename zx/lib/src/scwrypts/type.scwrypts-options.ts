import type { ScwryptsLogLevel } from './type.scwrypts-log-level.js';

export type ScwryptsOptions = {
  name?: string | undefined;
  group?: string | undefined;
  type?: string | undefined;
  patterns?: string[] | undefined;
  log_level?: ScwryptsLogLevel | undefined;
  args?: string | string[] | undefined;
};
