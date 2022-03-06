#!/bin/bash

TCP_VARIANTS=("TCP" "TCP/Reno" "TCP/Newreno" "TCP/Vegas")
PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

# Run simulation for Experiment 1 for 4 TCP variants: Tahoe, Reno, NewReno and Vegas
for variant in "${TCP_VARIANTS[@]}"
do
    echo "Running Simulation for TCP Variant: $variant"

    # Run simulation for each TCP variant with CBR flow starting from 1Mbps till the bottleneck capacity
    for rate in {1..10}
    do
        echo "Simulating $variant with CBR flow: $rate"
        $PREFIX experiment_1.tcl $variant $rate

    done

done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents