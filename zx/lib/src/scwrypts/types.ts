export type ScwryptsOptions = {
  name: string | undefined;
  group: string | undefined;
  type: string | undefined;
  patterns: string[] | undefined;
  log_level: ScwryptsLogLevel | undefined;
  args: string | string[] | undefined;
};

export enum ScwryptsLogLevel {
  SILENT = 0,
  QUIET = 1,
  NORMAL = 2,
  WARNING = 3,
  DEBUG = 4,
}
