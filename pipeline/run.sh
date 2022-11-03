#!/bin/sh
ulimit -n 10240
rm -rf output
mkdir output

# Run organisms with TSS
for DIRECTORY in Physco Mp Zea Sola ; do
    echo "Running $DIRECTORY --with-tss"
    dart run bin/pipeline.dart $DIRECTORY --with-tss > output/${DIRECTORY}-with-tss.info.txt
    zip output/${DIRECTORY}-with-tss.fasta.zip output/${DIRECTORY}-with-tss.fasta
done

# Run all
for FILE in source_data/* ; do
    if [ -d "$FILE" ]; then
        DIRECTORY=$(basename ${FILE})
        echo "Running $DIRECTORY"
        dart run bin/pipeline.dart $DIRECTORY > output/${DIRECTORY}.info.txt
        zip output/${DIRECTORY}.fasta.zip output/${DIRECTORY}.fasta
    fi
done

