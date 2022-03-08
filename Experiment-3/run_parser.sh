#!/bin/bash

file_path=$(pwd)

for f in $file_path/trace_data/*
    do 
        python3 parser.py exp3 $f res_exp3.csv
    done
