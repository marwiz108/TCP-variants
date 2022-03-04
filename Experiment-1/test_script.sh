#!/bin/bash

tcp_variants = ("TCP" "TCP/Reno" "TCP/Newreno" "TCP/Vegas")

# Run simulation for Experiment 1 for 4 TCP variants: Tahoe, Reno, NewReno and Vegas
for variant in "${tcp_variants[@]}"
do
    echo "Running Simulation for $variant"

    # Run simulation for each TCP variant with CBR flow rate starting from 1Mbps till the bottleneck capacity
    for rate in {1..10}
    do
        echo "Simulating $variant for CBR flow rate: $rate"
        ns experiment_1.tcl $variant $rate

    done

done

# REFERENCES:
# https://www.isi.edu/nsnam/ns/doc/node387.html TCP Agents