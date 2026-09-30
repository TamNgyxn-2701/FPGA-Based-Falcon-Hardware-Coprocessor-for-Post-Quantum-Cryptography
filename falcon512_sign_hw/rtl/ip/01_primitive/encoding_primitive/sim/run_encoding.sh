#!/bin/bash

mkdir -p build_encoding

vcs -debug +v2k -sverilog \
    -f list_encoding.f \
    ../tb/tb_encoding.v \
    -l build_encoding/compile_encoding.log \
    -o build_encoding/simv_encoding

./build_encoding/simv_encoding \
    -l build_encoding/run_encoding.log
