# `comp_soln`: Compare Output of Executables Under Test

`comp_soln` runs provided tests on an executable to test. The test is considered
passing if it matches the output of a specified solution executable.

## Usage

* `./run_tests.sh to_test solution tests`
    * `to_test`: The executable to test
    * `solution`: The solution executable whose output is considered correct
    * `tests`: File that contains one test per line. Each test should consist of
      space-separated arguments to provide to the executable.
* `./run_tests.sh tests`
    * `tests`: File that contains one test per line. Each test should be in the
      following format: `<test_executable> <arg1> <arg2> ...`. The solution
      executable is expected to be found at `samples/<test_executable>_soln`.

In files containing tests, lines beginning with `#` and blank lines are ignored.

## Legal

Copyright (c) 2019 [U8N WXD](https://github.com/U8NWXD)
<cs.temporary@icloud.com>

Use of this source code is governed by the BSD 3-Clause License in `LICENSE.txt`
