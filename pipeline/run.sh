#!/bin/sh
ulimit -n 10240
rm -rf output
mkdir output
for FILE in source_data/* ; do
    if [ -d "$FILE" ]; then
        DIRECTORY=$(basename ${FILE})
        echo "Running $DIRECTORY"
        dart run bin/pipeline.dart $DIRECTORY > output/${DIRECTORY}.info.txt
        zip output/${DIRECTORY}.fasta.zip output/${DIRECTORY}.fasta
    fi
done

