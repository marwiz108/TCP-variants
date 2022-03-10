#!/bin/bash

file_path=$(pwd)

for f in $file_path/Experiment-1/trace_data/*
    do 
        python3 parser.py exp1 $f res_exp1.csv
    done

for f in $file_path/Experiment-2/trace_data/*
    do 
        python3 parser.py exp2 $f res_exp2.csv
    done

for f in $file_path/Experiment-3/trace_data/*
    do 
        python3 parser.py exp3 $f res_exp3.csv
    done
