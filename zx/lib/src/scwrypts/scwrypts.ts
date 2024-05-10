import { execa } from 'execa';

import { getScwryptsLookup } from './get-scwrypts-lookup.js';
import { parseCLIArgs } from './parse-cli-args.js';

import type { ScwryptsOptions } from './type.scwrypts-options.js';

export const scwrypts = async (options: ScwryptsOptions) => {
  const lookup = getScwryptsLookup(options);

  const scwryptsExecutableArgs: string[] = [];

  switch (lookup.method) {
    case 'exact':
      scwryptsExecutableArgs.push('--name', lookup.name, '--group', lookup.group, '--type', lookup.type);
      break;
    case 'patterns':
      scwryptsExecutableArgs.push(...lookup.patterns);
      break;
  }

  if (options.log_level !== undefined) {
    scwryptsExecutableArgs.push('--log-level', options.log_level.toString());
  }

  return await execa(process.env.SCWRYPTS_EXECUTABLE || 'scwrypts', [
    ...scwryptsExecutableArgs,
    '--',
    ...parseCLIArgs(options.args),
  ]);
};
