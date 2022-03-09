#!/bin/bash

PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

# Run simulation for Experiment 2 for 4 TCP variant pairs: Reno/Reno, NewReno/Reno, Vegas/Vegas, and Newreno/Vegas
# Run for each pair of TCP variants with CBR flow starting from 1Mbps till the bottleneck capacity
for rate in {1..10}
    do
        $PREFIX experiment2_NR_R.tcl $rate 1.0 3.0
        $PREFIX experiment2_NR_V.tcl $rate 1.0 3.0
        $PREFIX experiment2_R_R.tcl $rate 1.0 3.0
        $PREFIX experiment2_V_V.tcl $rate 1.0 3.0
        
    done

# # Run simulation for Experiment 2 for 4 TCP variant pairs: Reno/Reno, NewReno/Reno, Vegas/Vegas, and Newreno/Vegas
# for variant_pair in "${TCP_VARIANT_PAIRS[@]}"
# do
#     # Run simulation for each pair of TCP variants with CBR flow starting from 1Mbps till the bottleneck capacity
#     for rate in {1..10}
#     do
#         $PREFIX experiment_2.tcl $variant_pair $rate 2.0 5.0
#         $PREFIX experiment_2.tcl $variant_pair $rate 4.0 4.0

#     done
# done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents