#!/bin/bash

project_dir="$(dirname $(dirname $(realpath $0)))" 
data_dir="${project_dir}/dataset"
output_dir="${project_dir}/rf"
goldfile="$data_dir/AILA-dataset/statute_gold.txt"
queryFold="${project_dir}/rf/queryFold"
RUN_SUFFIX="untitled"

if [ $# -lt 1 ]
then
    echo "USAGE: ./relfreq <score-file> [<queryFold-file> <goldfile> <run_title>]" 
    exit
fi

scorefile=$1
if [ $# -ge 4 ] ; then RUN_SUFFIX=$4; fi
if [ $# -ge 3 ] ; then goldfile=$3; fi
if [ $# -ge 2 ] ; then queryFold=$2; fi    

# temp directory
cur_date=$(date +%F)
cur_time=$(date +%T)
cur_time=${cur_time//:/-}   #replace colons with dashes
tmp_dir=${output_dir}/"rf-files-${cur_date}-${cur_time}"
mkdir $tmp_dir

#create score files
if [ -f ${queryFold} ]
then    
    patter=$(tail -n+1 $queryFold | head -n1);    egrep "^AILA_($patter) " $scorefile > ${tmp_dir}/score.fold1.$RUN_SUFFIX;
    patter=$(tail -n+2 $queryFold | head -n1);    egrep "^AILA_($patter) " $scorefile > ${tmp_dir}/score.fold2.$RUN_SUFFIX;
    patter=$(tail -n+3 $queryFold | head -n1);    egrep "^AILA_($patter) " $scorefile > ${tmp_dir}/score.fold3.$RUN_SUFFIX;
    patter=$(tail -n+4 $queryFold | head -n1);    egrep "^AILA_($patter) " $scorefile > ${tmp_dir}/score.fold4.$RUN_SUFFIX;
    patter=$(tail -n+5 $queryFold | head -n1);    egrep "^AILA_($patter) " $scorefile > ${tmp_dir}/score.fold5.$RUN_SUFFIX;
else    echo "NOT FOUND ${queryFold}"; exit; fi

#create remaining query fold files
for((i=2; i<=5; i++)); do    tail -n+$i $queryFold | paste -s -d'|' > ${tmp_dir}/q${i}5.ptn; done
for((i=1; i<=4; i++)); do    head -$i $queryFold | paste -s -d'|' > ${tmp_dir}/q1${i}.ptn; done
paste -d'|' ${tmp_dir}/q35.ptn ${tmp_dir}/q11.ptn > ${tmp_dir}/q31.ptn; rm  ${tmp_dir}/q35.ptn ${tmp_dir}/q11.ptn;
paste -d'|' ${tmp_dir}/q45.ptn ${tmp_dir}/q12.ptn > ${tmp_dir}/q42.ptn; rm  ${tmp_dir}/q45.ptn ${tmp_dir}/q12.ptn;
paste -d'|' ${tmp_dir}/q55.ptn ${tmp_dir}/q13.ptn > ${tmp_dir}/q53.ptn; rm  ${tmp_dir}/q55.ptn ${tmp_dir}/q13.ptn;

#create relfreq files
if [ -f ${goldfile} ] 
then
    patter=$(head -n1 ${tmp_dir}/q14.ptn);    egrep "^AILA_($patter) .* 1$" $goldfile | cut -d' ' -f3 | sort -n | uniq -c > ${tmp_dir}/relfreq14.$RUN_SUFFIX;
    patter=$(head -n1 ${tmp_dir}/q25.ptn);    egrep "^AILA_($patter) .* 1$" $goldfile | cut -d' ' -f3 | sort -n | uniq -c > ${tmp_dir}/relfreq25.$RUN_SUFFIX;
    patter=$(head -n1 ${tmp_dir}/q31.ptn);    egrep "^AILA_($patter) .* 1$" $goldfile | cut -d' ' -f3 | sort -n | uniq -c > ${tmp_dir}/relfreq31.$RUN_SUFFIX;
    patter=$(head -n1 ${tmp_dir}/q42.ptn);    egrep "^AILA_($patter) .* 1$" $goldfile | cut -d' ' -f3 | sort -n | uniq -c > ${tmp_dir}/relfreq42.$RUN_SUFFIX;
    patter=$(head -n1 ${tmp_dir}/q53.ptn);    egrep "^AILA_($patter) .* 1$" $goldfile | cut -d' ' -f3 | sort -n | uniq -c > ${tmp_dir}/relfreq53.$RUN_SUFFIX;
else    echo "NOT FOUND ${goldfile}"; exit; fi 
