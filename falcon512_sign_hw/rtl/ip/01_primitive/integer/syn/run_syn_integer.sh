#!/bin/bash

mkdir -p reports
mkdir -p netlist
mkdir -p sdf
mkdir -p logs
mkdir -p work

dc_shell -f scripts/syn_integer.tcl | tee logs/syn_integer.log
