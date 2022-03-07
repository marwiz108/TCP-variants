#!/bin/bash

tcps=("Reno" "Sack1")
queue_algorithms=("DropTail" "RED")
PREFIX=/course/cs4700f12/ns-allinone-2.35/bin/ns

for variant in "${tcps}"
do
    echo "Running simulation for $variant"

    for queue in "${queue_algorithms}"
    do
        echo "Simulating $variant with $queue algorithm"
        $PREFIX experiment_3.tcl $variant $queue
    done
done
