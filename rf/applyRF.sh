#!/bin/bash

set -e

project_dir="$(dirname $(dirname $(realpath $0)))"
output_dir="${project_dir}/rf"
RUN_SUFFIX="untitled"

# temp directory
cur_date=$(date +%F)
cur_time=$(date +%T)
cur_time=${cur_time//:/-}   #replace colons with dashes
export tmp_dir=${output_dir}/"rf-files-${cur_date}-${cur_time}"

if [ $# -lt 1 ] 
then 
    echo "USAGE: ./applyRF.sh <score-file>" 
    exit
fi

scorefile=$1
rf_calc_file=${project_dir}/rf/rf_calc.py 
rels=(25 31 42 53 14)

# find relevance frequencies of all folds
bash ${project_dir}/rf/relfreq.sh $scorefile


if [ -f ${project_dir}/rf/rf_calc.py ]
then
    echo 'USING rf_calc.py...'
else 
    echo 'rf_calc.py NOT FOUND'
    exit 
fi

for((i=1,j=0; i<=5; i++,j++))
do    
    if [[ -f ${tmp_dir}/score.fold$i.${RUN_SUFFIX} && -f ${tmp_dir}/relfreq${rels[$j]}.${RUN_SUFFIX} ]]
    then
        python $rf_calc_file ${tmp_dir}/score.fold$i.$RUN_SUFFIX ${tmp_dir}/relfreq${rels[$j]}.$RUN_SUFFIX   
        echo "DONE score.fold$i.${RUN_SUFFIX} relfreq${rels[$j]}.${RUN_SUFFIX}..."
    else
        echo "ERROR MISSING score.fold$i.${RUN_SUFFIX} OR relfreq${rels[$j]}.${RUN_SUFFIX}..."
    fi
done
