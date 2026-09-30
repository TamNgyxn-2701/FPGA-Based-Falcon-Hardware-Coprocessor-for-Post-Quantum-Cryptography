#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/build_v1"

if [ ! -f simv ]; then
    echo "ERROR: simv not found. Run bash sim/run_vcs_v1.sh first."
    exit 1
fi

./simv -gui
