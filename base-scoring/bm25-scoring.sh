#!/bin/bash

project_dir="$(dirname $(dirname $(realpath $0)))" 
data_dir="${project_dir}/dataset"
data_zip="${data_dir}/trec_formatted_statutes.zip"
extract_folder="${data_dir}/AILA-dataset/trec_fmt_statutes"

# extract trec_formatted.zip
if [ -f $data_zip ] && [ ! -d $extract_folder ]
then
	echo "Found trec zip .. extracting."
	unzip -q $data_zip -d $extract_folder
elif [[ -d $extract_folder ]]
then
	echo "Skipping .. Found extracted trec_fmt_statutes."
else
	echo "Aborting .. trec zip not found."
	exit 2
fi

terrier_run="${TERRIER_HOME}/bin/trec_terrier.sh"
terrier_etc="${TERRIER_HOME}/etc"
terrier_var="${TERRIER_HOME}/var"
terrier_files=${project_dir}/base-scoring/terrier-files

# checking Terrier 
if [ ! -f $terrier_run ]
then
	echo "Aborting .. $terrier_run does not exist."
	exit 3
fi

# put project's collection.spec and terrier.properties under terrier_etc
if [ ! -f ${terrier_files}/collection_statute.spec ] ||  [ ! -f ${terrier_files}/terrier.properties.statute ]
then 
	echo "Aborting .. $terrier_files path is missing some files."
	exit 4
fi	

cp --interactive ${terrier_files}/terrier.properties.statute ${terrier_etc}/terrier.properties
sed "s#^/home/shashank/Downloads#$data_dir#" ${terrier_files}/collection_statute.spec > ${terrier_etc}/collection.spec # edit paths for collection.spec

#backup and remove old index
if [ ${terrier_var}/index ]
then
	cur_date=$(date +%F)
	cur_time=$(date +%T)
	cur_time=${cur_time//:/-}	#replace colons with dashes
	bkp_folder=${terrier_var}/"oldindex-${cur_date}-${cur_time}"
	mkdir $bkp_folder
	mv $terrier_var/index/* $bkp_folder
fi

#for indexing of statute docs
echo "Starting indexing of dataset .."
${terrier_run} -i  > ${terrier_var}/"indexing-${cur_date}-${cur_time}".info 2>&1

#print stats
echo "Finished indexing of dataset"
echo "============="
echo "Stats"
${terrier_run} --printstats

#retrieve with bm25 model	
${terrier_run} -r -Dtrec.topics=${terrier_files}/topics.txt -Dtrec.model=BM25  > ${terrier_var}/"retrieval-${cur_date}-${cur_time}".info 2>&1

res_path=$(ls -1t ${terrier_var}/results/*.res | head -1)
res_filename=$(basename ${res_path}) 

echo "============="
echo "Result file generated at: $res_path"

#copy the results file
cp $res_path ${project_dir}/base-scoring/

echo "Copied to directory: ${project_dir}/base-scoring"
echo "============="
sed -i 's/Q0 /Q0 S/' ${project_dir}/base-scoring/${res_filename}
echo "edited result file document names to match gold file"