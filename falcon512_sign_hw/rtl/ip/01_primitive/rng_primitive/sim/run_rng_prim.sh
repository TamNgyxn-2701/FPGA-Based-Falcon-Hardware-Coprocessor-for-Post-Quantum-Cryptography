#!/bin/bash

mkdir -p build_rng_prim

vcs -debug +v2k -sverilog \
    -f list_rng_prim.f \
    ../tb/tb_rng_prim.v \
    -l build_rng_prim/compile_rng_prim.log \
    -o build_rng_prim/simv_rng_prim

./build_rng_prim/simv_rng_prim \
    -l build_rng_prim/run_rng_prim.log
