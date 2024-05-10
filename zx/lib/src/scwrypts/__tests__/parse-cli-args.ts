/* eslint-disable  @typescript-eslint/no-explicit-any */
import { describe, expect, test, beforeEach } from '@jest/globals';
import { v4 as uuid } from 'uuid';

import { parseCLIArgs } from '../parse-cli-args.js';

let sample: any;
beforeEach(() => {
  sample = {
    args: [uuid(), uuid(), uuid()],
  };

  sample.argstring = sample.args.join(' ');
});

describe('undefined input', () => {
  test('produces a string[]', () => {
    expect(parseCLIArgs(undefined)).toEqual([]);
  });
});

describe('string input', () => {
  test('produces a string[]', () => {
    expect(parseCLIArgs(sample.argstring)).toEqual(sample.args);
  });
});

describe('string[] input', () => {
  test('produces a string[]', () => {
    expect(parseCLIArgs(sample.args)).toEqual(sample.args);
  });
});
