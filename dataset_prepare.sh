#!/bin/bash

set -e

data_dir="$(dirname $(realpath $0))/dataset"
data_zip="$data_dir/AILA-dataset.zip"
extract_folder="$data_dir/AILA-dataset"
inner_zip="$extract_folder/dataset.zip"

# extract AILA-dataset.zip
if [ -f $data_zip ] && [ ! -d $extract_folder ]
then
	echo "Found dataset .. extracting."
	unzip -q $data_zip -d $data_dir
	unzip -q $inner_zip -d $extract_folder
elif [[ -d $extract_folder ]]; then
	echo "Skipping .. Found extracted dataset."
else
	echo "Aborting .. dataset zip not found."
	exit 2
fi

stat_folder="$extract_folder/AILA-data/Object_statutes"

# create dummy files for S32.txt,S58.txt,S162.txt
if [ -d $stat_folder ]
then
	touch $stat_folder/{S32.txt,S58.txt,S162.txt}
	echo "Created dummy files : S32.txt, S58.txt, S162.txt"
else
	echo "Error .. didn't find the 'Object_statutes' folder in AILA-dataset."
fi

# create ground truth statute task
gold_path="$extract_folder/statute_gold.txt"
train_gold="$extract_folder/train-data-rel-judgment/statutes.txt"
test_gold="$extract_folder/test-data-rel-judgment/goldstd_statute.txt"
if [ ! -f $gold_path ]
then
	cat $train_gold >> $gold_path
	cat $test_gold >> $gold_path
	echo "created statute_gold.txt"
fi