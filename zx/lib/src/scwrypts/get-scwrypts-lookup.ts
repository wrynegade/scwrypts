import { parseCLIArgs } from './parse-cli-args.js';

import type { ScwryptsOptions } from './type.scwrypts-options.js';

export type ScwryptsLookupOptions =
  | {
      method: 'exact';
      name: string;
      group: string;
      type: string;
    }
  | {
      method: 'patterns';
      patterns: string[];
    };

export const Errors = {
  NoScwryptsLookupError: {
    name: 'NoScwryptsLookupError',
    message: 'no scwrypts lookup parameters provided',
  },
  MissingScwryptsExactLookupParametersError: {
    name: 'MissingScwryptsExactLookupParametersError',
    message: '"name" option requires "group" and "type" options',
  },
};

export const getScwryptsLookup = (options: ScwryptsOptions): ScwryptsLookupOptions => {
  if (options.name === undefined) {
    if (options.patterns === undefined || options.patterns.length === 0) {
      throw Errors.NoScwryptsLookupError;
    }
    return {
      method: 'patterns',
      patterns: parseCLIArgs(options.patterns),
    };
  }

  if (options.group === undefined || options.type === undefined) {
    throw Errors.MissingScwryptsExactLookupParametersError;
  }

  return {
    method: 'exact',
    name: options.name,
    group: options.group,
    type: options.type,
  };
};
