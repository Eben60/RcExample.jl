#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
JLSCRIPT="$SCRIPT_DIR/src/rex.jl"

julia --project=$SCRIPT_DIR $JLSCRIPT $@