#!/bin/bash

mkdir -p build_buffer

vcs -debug +v2k -v2005 \
    -f list_buffer.f \
    ../tb/tb_buffer.v \
    -l build_buffer/compile_buffer.log \
    -o build_buffer/simv_buffer

./build_buffer/simv_buffer \
    -l build_buffer/run_buffer.log
