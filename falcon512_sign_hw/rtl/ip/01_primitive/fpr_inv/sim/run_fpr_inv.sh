#!/bin/bash

mkdir -p build_fpr_inv

vcs -debug +v2k -sverilog \
    -f list_fpr_inv.f \
    ../tb/tb_fpr_inv.v \
    -l build_fpr_inv/compile_fpr_inv.log \
    -o build_fpr_inv/simv_fpr_inv

./build_fpr_inv/simv_fpr_inv \
    -l build_fpr_inv/run_fpr_inv.log
