#!/bin/bash

TCP_VARIANT_PAIRS=("TCP/Reno TCP/Reno" "TCP/Newreno TCP/Reno" "TCP/Vegas TCP/Vegas" "TCP/Newreno TCP/Vegas")
PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

# Run simulation for Experiment 2 for 4 TCP variant pairs: Reno/Reno, NewReno/Reno, Vegas/Vegas, and Newreno/Vegas
for variant_pair in "${TCP_VARIANT_PAIRS[@]}"
do
    echo "Running Simulation for 2 TCP Variants: $variant_pair"

    # Run simulation for each pair of TCP variants with CBR flow starting from 1Mbps till the bottleneck capacity
    for rate in {1..10}
    do
        echo "Simulating for 2 variants $variant_pair with CBR flow: $rate"
        $PREFIX experiment_2.tcl $variant_pair $rate

    done

done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents