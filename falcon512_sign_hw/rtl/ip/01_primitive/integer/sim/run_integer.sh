#!/bin/bash

mkdir -p build_integer

vcs -debug +v2k \
    -f list_integer.f \
    ../tb/tb_integer.v \
    -l build_integer/compile_integer.log \
    -o build_integer/simv_integer

./build_integer/simv_integer \
    -l build_integer/run_integer.log
