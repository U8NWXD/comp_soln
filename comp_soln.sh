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
    echo -n "Testing $to_test $args ... "
    actual=$(eval "$to_test $args" 2>&1) || true
    expected=$(eval "$solution $args" 2>&1) || true

    if diff <(echo "$actual") <(echo "$expected")
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
