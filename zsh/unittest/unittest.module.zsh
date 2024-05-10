#
# (beta) module for performing unit tests on scwrypts zsh modules
#

# provides function and environment variable mocking (+ some assertions)
use unittest/mock

# provides common logic used in testing
use unittest/test

#
# create a test file to match your module name
#   ├── my-thing.module.zsh
#   └── my-thing.test.zsh
#
# add the import line 'use unittest'
#
# define tests by creating functions called 'test.your-test-name()'
#   - the test "passes" on successful return code (e.g. 'return 0')
#   - the test "fails" on any other return code
#
# some other testing features implemented:
#   - defining 'beforeall()'  < executed before the test suite runs
#   - defining 'beforeeach()' < executed before each test function
#   - defining 'aftereach()'  < executed after  each test function
#   - defining 'afterall()'   < executed after  the test suite completes
#
# using 'scwrypts unittest run' will run each test suite in an isolated
# subshell, so configurations are not persisted between test files
#
