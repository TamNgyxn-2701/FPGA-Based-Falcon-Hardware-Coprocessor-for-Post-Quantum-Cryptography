#!/bin/bash

mkdir -p build_fpc

vcs -debug +v2k -sverilog \
    -f list_fpc.f \
    ../tb/tb_fpc.v \
    -l build_fpc/compile_fpc.log \
    -o build_fpc/simv_fpc

./build_fpc/simv_fpc \
    -l build_fpc/run_fpc.log
