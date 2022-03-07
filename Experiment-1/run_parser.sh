#!/bin/bash

file_path=$(pwd)

for f in $file_path/trace_data_exp1/*
do python3 parser.py exp1 $f res.csv
done