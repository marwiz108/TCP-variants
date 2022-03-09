#!/bin/bash

RATES=(1 2 3 4 5 6 6.5 7 7.5 8 8.5 9 9.2 9.4 9.6 9.8 10)
PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

# Run simulation for Experiment 2 for 4 TCP variant pairs: Reno/Reno, NewReno/Reno, Vegas/Vegas, and Newreno/Vegas
# Run for each pair of TCP variants with CBR flow starting from 1Mbps till the bottleneck capacity
for rate in "${RATES[@]}"
    do
        $PREFIX experiment2_NR_R.tcl $rate 1.0 3.0
        $PREFIX experiment2_NR_V.tcl $rate 1.0 3.0
        $PREFIX experiment2_R_R.tcl $rate 1.0 3.0
        $PREFIX experiment2_V_V.tcl $rate 1.0 3.0
        
    done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents