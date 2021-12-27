#!/bin/bash

sim/Vverilator_top --vcdfile=$1 && [ $PIPESTATUS -eq 0 ]
# +max-cycles=100 +loadmem=$1 
sed -i 's/timescale 1s/timescale 5ns/g' $1

