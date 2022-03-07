#!/bin/bash

TCP_VARIANT_PAIRS=("TCP/Reno TCP/Reno" "TCP/Newreno TCP/Reno" "TCP/Vegas TCP/Vegas" "TCP/Newreno TCP/Vegas")
PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

# Run simulation for Experiment 2 for 4 TCP variant pairs: Reno/Reno, NewReno/Reno, Vegas/Vegas, and Newreno/Vegas
for variant_pair in "${TCP_VARIANT_PAIRS[@]}"
do

    # Run simulation for each pair of TCP variants with CBR flow starting from 1Mbps till the bottleneck capacity
    for rate in {1..10}
    do
        for start_time in $(seq 1.0 1.0 3.0)
        do
            $PREFIX experiment_2.tcl $variant_pair $rate $start_time "4.0 - $start_time" | bc

        done

    done

done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents