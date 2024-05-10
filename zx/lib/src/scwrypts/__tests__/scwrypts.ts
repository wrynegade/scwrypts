/* eslint-disable  @typescript-eslint/no-explicit-any */
import { describe, expect, test, beforeEach, jest } from '@jest/globals';
import { v4 as uuid } from 'uuid';

import { execa } from 'execa';
import * as Module_getScwryptsLookup from '../get-scwrypts-lookup.js';
import * as Module_parseCLIArgs from '../parse-cli-args.js';
import { ScwryptsLogLevel } from '../type.scwrypts-log-level.js';

import { scwrypts } from '../scwrypts.js';

jest.mock('execa', () => ({
  execa: jest.fn(() => Promise.resolve()),
}));

const env = process.env;
beforeEach(() => {});

let sample: any;
beforeEach(() => {
  sample = {
    options: {
      name: uuid(),
      group: uuid(),
      type: uuid(),
      patterns: [uuid(), uuid(), uuid()],
      log_level: Math.floor(Math.random() * Object.keys(ScwryptsLogLevel).length),
      args: uuid(),
    },
    lookup: {
      exact: {
        method: 'exact',
        name: uuid(),
        group: uuid(),
        type: uuid(),
      },
      patterns: {
        method: 'patterns',
        patterns: [uuid(), uuid(), uuid()],
      },
    },
    env: {
      SCWRYPTS_EXECUTABLE: uuid(),
    },
    parsedCLIArgs: [uuid(), uuid(), uuid()],
    spy: {},
  };

  sample.spy.getScwryptsLookup = jest.spyOn(Module_getScwryptsLookup, 'getScwryptsLookup');
  sample.spy.getScwryptsLookup.mockReturnValue(sample.lookup.exact);

  sample.spy.parseCLIArgs = jest.spyOn(Module_parseCLIArgs, 'parseCLIArgs');
  sample.spy.parseCLIArgs.mockReturnValue(sample.parsedCLIArgs);

  jest.resetModules();
  process.env = {
    ...env,
    ...sample.env,
  };
});

afterEach(() => {
  process.env = { ...env };
});

describe('exact lookup', () => {
  beforeEach(async () => {
    sample.spy.getScwryptsLookup.mockReturnValue(sample.lookup.exact);
    await scwrypts(sample.options);
  });

  test('gets the correct lookup', () => {
    expect(sample.spy.getScwryptsLookup).toHaveBeenCalledWith(sample.options);
  });

  test('parses arguments correctly', () => {
    expect(sample.spy.parseCLIArgs).toHaveBeenCalledWith(sample.options.args);
  });

  test('calls the correct scwrypt', () => {
    expect(execa).toHaveBeenCalledWith(sample.env.SCWRYPTS_EXECUTABLE, [
      '--name',
      sample.lookup.exact.name,
      '--group',
      sample.lookup.exact.group,
      '--type',
      sample.lookup.exact.type,
      '--log-level',
      sample.options.log_level.toString(),
      '--',
      ...sample.parsedCLIArgs,
    ]);
  });
});

describe('patterns lookup', () => {
  beforeEach(async () => {
    sample.spy.getScwryptsLookup.mockReturnValue(sample.lookup.patterns);
    await scwrypts(sample.options);
  });

  test('gets the correct lookup', () => {
    expect(sample.spy.getScwryptsLookup).toHaveBeenCalledWith(sample.options);
  });

  test('parses arguments correctly', () => {
    expect(sample.spy.parseCLIArgs).toHaveBeenCalledWith(sample.options.args);
  });

  test('calls the correct scwrypt', () => {
    expect(execa).toHaveBeenCalledWith(sample.env.SCWRYPTS_EXECUTABLE, [
      ...sample.lookup.patterns.patterns,
      '--log-level',
      sample.options.log_level.toString(),
      '--',
      ...sample.parsedCLIArgs,
    ]);
  });
});

test('omits --log-level arguments if not provided', async () => {
  delete sample.options.log_level;

  await scwrypts(sample.options);

  expect(execa).toHaveBeenCalledWith(sample.env.SCWRYPTS_EXECUTABLE, [
    '--name',
    sample.lookup.exact.name,
    '--group',
    sample.lookup.exact.group,
    '--type',
    sample.lookup.exact.type,
    '--',
    ...sample.parsedCLIArgs,
  ]);
});

test('uses default scwrypts executable SCWRYPTS_EXECUTABLE is not provided', async () => {
  delete process.env.SCWRYPTS_EXECUTABLE;

  await scwrypts(sample.options);

  expect(execa).toHaveBeenCalledWith('scwrypts', [
    '--name',
    sample.lookup.exact.name,
    '--group',
    sample.lookup.exact.group,
    '--type',
    sample.lookup.exact.type,
    '--log-level',
    sample.options.log_level.toString(),
    '--',
    ...sample.parsedCLIArgs,
  ]);
});
