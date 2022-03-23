#!/bin/bash

# usage
# touch-in-dir.sh [touch options] main.cpp in.txt out.txt -dir a b {c..d}
# touch-in-dir.sh [touch options] files --dir a b {c..d}

# competitive cpp
# prepare-ccp.sh [folders]

for folder_name in "$@"; do
	mkdir -p "$folder_name"
	for file_name in "main.cpp" "in.txt" "out.txt"; do
		touch "${folder_name}/${file_name}"
	done
	echo 1 >>"${folder_name}/in.txt"
done
