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

failed=0
total=0

if (($# != 3 && $# != 1)); then {
    echo "Usage: ./run_tests.sh to_test solution tests"
    echo "       ./run_tests.sh tests"
    exit 1
}
fi

if (($# == 1))
then tests="$1"
else tests="$3"
fi

num_tests=0

while read p; do {
    if [[ ${p:0:1} == "#" ]]; then continue; fi
    if [[ -z "$p" ]]; then continue; fi
    num_tests=$((num_tests + 1))
}; done < "$tests"

while read p
do {
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

    total=$((total+1))
    echo -n "Running Test $total of $num_tests: $to_test $args ... "

    if comp_out "$to_test" "$solution" "$args"
    then {
        print_color "$green" "OK"
    } else {
        failed=$((failed+1))
        print_color "$red" "FAILED"
        echo "Expected:"
        echo "$expected"
        echo "Actual:"
        echo "$actual"
    }
    fi
}
done < "$tests"
echo "Failed $failed tests of $total"
if (($failed == 0)); then echo "ALL TESTS PASSED"; fi
