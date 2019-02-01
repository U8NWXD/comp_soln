#!/bin/bash

# comp_soln.sh: Compare Output of Executables Under Test
# Copyright (c) 2019 U8N WXD (github.com/U8NWXD) <cs.temporary@icloud.com>
# Licensed under the BSD 3-Clause License in `LICENSE.txt`

set -e

black="$(tput setaf 0)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
blue="$(tput setaf 4)"
magenta="$(tput setaf 5)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
gray="$(tput setaf 245)"

endColor="$(tput sgr0)"

# Usage: print_color color text
print_color() {
    color="$1"
    text="$2"
    echo "${color}$text${endColor}"
}

# Usage: comp_out test_exec soln_exec args
# Variables `actual` and `expected` will hold testing and solution outputs
comp_out() {
    test_exec=$1
    soln_exec=$2
    args=$3
    actual=$(eval "$test_exec $args" 2>&1) || true
    expected=$(eval "$soln_exec $args" 2>&1) || true

    if diff -q <(echo "$actual") <(echo "$expected") > /dev/null; then {
        return 0
    } else {
        return 1
    }; fi
}

# Usage: test_exec args
# Errors stored in `valgrind_errors`
test_valgrind() {
    test_exec=$1
    args=$2
    valgrind_errors=$(valgrind -q --leak-check=full --show-leak-kinds=all "$test_exec" "$args" 2>&1 > /dev/null)
    if [[ -z "$valgrind_errors" ]]; then {
        return 0;
    } else {
        return 1;
    }; fi
}

# Usage: test_exec soln_exec args
# Output stored in test_time, soln_time, and factor (test / soln)
test_runtime() {
    test_exec=$1
    soln_exec=$2
    args=$3

    test_start="$(date +%s)"
    eval "$test_exec $args" 2>&1 > /dev/null
    test_end="$(date +%s)"

    soln_start="$(date +%s)"
    eval "$soln_exec $args" 2>&1 > /dev/null
    soln_end="$(date +%s)"

    test_time=$((test_end - test_start))
    soln_time=$((soln_end - soln_start))

    if [[ soln_time -eq 0 ]]; then {
        soln_time=1
    }; fi

    factor=$((test_time / soln_time))

    if [[ $factor -gt 3 ]]; then {
        return 1;
    } else {
        return 0;
    } fi;
}


run_valgrind_tests=false
check_runtime=false

# Parse arguments
# SOURCE: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":vth" opt; do
  case $opt in
    v)
      run_valgrind_tests=true
      ;;
    t)
      check_runtime=true
      ;;
    h)
      echo "Usage: ./comp_soln.sh [-vt] to_test solution tests"
      echo "       ./comp_soln.sh [-v] tests"
      echo "-v checks that valgrind finds no errors"
      echo "-t checks that test runs at most 3x slower than solution"
      echo "-h displays this help text"
      exit 0
      ;;
    \?)
      echo "Invalid Option: -$OPTARG"
      echo "Run ./comp_soln.sh -h for help"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      echo "Run ./comp_soln.sh -h for help"
      exit 1
      ;;
  esac
done

num_failed=0
total=0

shift $(($OPTIND-1))

if (($# != 3 && $# != 1)); then {
    echo "Usage: ./comp_soln.sh [-v] to_test solution tests"
    echo "       ./comp_soln.sh [-v] tests"
    echo "-v checks that valgrind finds no errors"
    echo "-h displays this help text"
    exit 1
}
fi

if (($# == 1))
then tests="$1"
else tests="$3"
fi

# HELP FROM: https://stackoverflow.com/a/20295018
# HELP FROM:
# https://peniwize.wordpress.com/2011/04/09/how-to-read-all-lines-of-a-file-into-a-bash-array/
# HELP FROM: https://www.linuxjournal.com/content/bash-arrays
test_lines=()
i=0
while IFS= read -r p; do
    if [[ ${p:0:1} == "#" ]]; then continue; fi
    if [[ -z "$p" ]]; then continue; fi
    test_lines[i]="$p"
    ((++i))
done < "$tests"

num_tests=${#test_lines[*]}
test_num=0

for p in "${test_lines[@]}"; do {
    ((++test_num))
    if [[ ${p:0:1} == "#" ]]; then continue; fi
    if [[ -z "$p" ]]; then continue; fi
    if (($# == 1))
    then {
        arr=($p)
        to_test="./${arr[0]}"
        solution="samples/${arr[0]}_soln"
        args="${arr[@]:1}"
    } else {
        to_test="$1"
        solution="$2"
        args="$p"
    }
    fi

    failed=false

    echo -n "[$test_num of $num_tests] Comparing Output: $to_test $args ... "

    if comp_out "$to_test" "$solution" "$args"
    then {
        print_color "$green" "OK"
    } else {
        failed=true
        print_color "$red" "FAILED"
        echo "Expected:"
        print_color "$gray" "$expected"
        echo "Actual:"
        print_color "$gray" "$actual"
    }
    fi

    if $run_valgrind_tests; then {
        echo -n "[$test_num of $num_tests] Running Valgrind: $to_test $args ... "

        if test_valgrind "$to_test" "$args"; then {
            print_color "$green" "OK"
        } else {
            failed=true
            print_color "$red" "FAILED"
            echo "Valgrind Errors:"
            print_color "$gray" "$valgrind_errors"
        }; fi
    }; fi

    if $check_runtime; then {
        echo -n "[$test_num of $num_tests] Checking Runtime: $to_test $args ... "
        if test_runtime "$to_test" "$solution" "$args"; then {
            print_color "$green" "OK"
        } else {
            failed=true
            print_color "$red" "FAILED"
            print_color "$gray" "Test Time: $test_time"
            print_color "$gray" "Solution Tiime: $soln_time"
            print_color "$gray" "Factor (test/soln): $factor"
        }; fi
    }; fi

    if $failed; then {
        num_failed=$((num_failed+1))
    }; fi
}; done
echo "Failed $num_failed tests of $num_tests"
if (($num_failed == 0)); then echo "ALL TESTS PASSED"; fi

exit 0

