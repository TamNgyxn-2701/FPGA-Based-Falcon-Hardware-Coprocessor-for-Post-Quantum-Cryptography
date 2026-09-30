#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
mkdir -p build_v7
cd build_v7

vcs -debug +v2k -sverilog \
    -f ../listfile_v7.f \
    -l compile_v7.log \
    -o simv

./simv -l run_v7.log
