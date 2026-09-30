#!/bin/bash

mkdir -p build_modq

vcs -debug +v2k -sverilog \
    -f list_modq.f \
    ../tb/tb_modq.v \
    -l build_modq/compile_modq.log \
    -o build_modq/simv_modq

./build_modq/simv_modq \
    -l build_modq/run_modq.log
