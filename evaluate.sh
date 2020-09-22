#!/bin/bash

if [ $# -lt 1 ]; then echo "USAGE: ./evaluate.sh <output-score-file>"; exit; fi
resfile=$1

data_dir="$(dirname $(realpath $0))/dataset"
goldfile="$data_dir/AILA-dataset/statute_gold.txt"
echo "USING goldfile AS $goldfile"
trec_path="$data_dir/AILA-dataset/trec_eval.8.1"


$trec_path/trec_eval $goldfile $resfile | egrep '^(num_rel.*|map|bpref|P10)\s+all'
