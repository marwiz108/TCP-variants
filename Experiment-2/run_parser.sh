#!/bin/bash

file_path=$(pwd)

for f in $file_path/trace_data/*
    do 
        python3 parser.py exp2 $f res_exp2.csv
    done
