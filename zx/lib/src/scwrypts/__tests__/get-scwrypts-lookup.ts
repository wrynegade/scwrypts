/* eslint-disable  @typescript-eslint/no-explicit-any */
import { describe, expect, test, beforeEach, jest } from '@jest/globals';
import { v4 as uuid } from 'uuid';

import * as Module_parseCLIArgs from '../parse-cli-args.js';

import { getScwryptsLookup, Errors } from '../get-scwrypts-lookup.js';

import type { ScwryptsOptions } from '../type.scwrypts-options.js';

let sample: any;
beforeEach(() => {
  sample = {
    parsedCLIArgs: [uuid(), uuid(), uuid()],
    spy: {},
  };

  sample.spy.parseCLIArgs = jest.spyOn(Module_parseCLIArgs, 'parseCLIArgs');
  sample.spy.parseCLIArgs.mockReturnValue(sample.parsedCLIArgs);
});

describe('exact', () => {
  beforeEach(() => {
    sample.exact = {
      name: uuid(),
      group: uuid(),
      type: uuid(),
    };
  });

  test('provides correct lookup', () => {
    const lookup = getScwryptsLookup(sample.exact as ScwryptsOptions);

    expect(lookup).toEqual({
      method: 'exact',
      ...sample.exact,
    });
  });

  describe('throws error', () => {
    test('when missing group', () => {
      delete sample.exact.group;
      try {
        getScwryptsLookup(sample.exact as ScwryptsOptions);
        expect(true).toBeFalsy();
      } catch (error) {
        expect(error).toEqual(Errors.MissingScwryptsExactLookupParametersError);
      }
    });

    test('when missing type', () => {
      delete sample.exact.type;
      try {
        getScwryptsLookup(sample.exact as ScwryptsOptions);
        expect(true).toBeFalsy();
      } catch (error) {
        expect(error).toEqual(Errors.MissingScwryptsExactLookupParametersError);
      }
    });
  });
});

describe('patterns', () => {
  describe('list', () => {
    let lookup: any;
    beforeEach(() => {
      sample.patterns = {
        patterns: [uuid(), uuid(), uuid()],
      };

      lookup = getScwryptsLookup(sample.patterns as ScwryptsOptions);
    });

    test('provides correct lookup', () => {
      expect(lookup).toEqual({
        method: 'patterns',
        patterns: sample.parsedCLIArgs,
      });
    });

    test('parses patterns', () => {
      expect(sample.spy.parseCLIArgs).toHaveBeenCalledWith(sample.patterns.patterns);
    });
  });

  describe('string', () => {
    let lookup: any;
    beforeEach(() => {
      sample.patterns = {
        patterns: uuid(),
      };

      lookup = getScwryptsLookup(sample.patterns as ScwryptsOptions);
    });

    test('provides correct lookup', () => {
      expect(lookup).toEqual({
        method: 'patterns',
        patterns: sample.parsedCLIArgs,
      });
    });

    test('parses patterns', () => {
      expect(sample.spy.parseCLIArgs).toHaveBeenCalledWith(sample.patterns.patterns);
    });
  });
});

test('throws error when missing name and patterns', () => {
  try {
    getScwryptsLookup({} as ScwryptsOptions);
    expect(true).toBeFalsy();
  } catch (error) {
    expect(error).toEqual(Errors.NoScwryptsLookupError);
  }
});
