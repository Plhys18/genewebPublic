#!/bin/sh
ulimit -n 10240

# Check if a directory argument is provided
if [ $# -gt 0 ]; then
    TARGET_DIR=$1
    # Check if TARGET_DIR exists and is a directory
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: $TARGET_DIR not found or is not a directory."
        exit 1
    fi
else
    TARGET_DIR="source_data/*"
    rm -rf output
    mkdir output
fi


# Run all or specific directory
for FILE in $TARGET_DIR ; do
    if [ -d "$FILE" ]; then
        DIRECTORY=$(basename ${FILE})
        echo "Running $DIRECTORY"
        dart run bin/pipeline.dart $DIRECTORY | tee output/${DIRECTORY}.info.txt
        zip output/${DIRECTORY}.fasta.zip output/${DIRECTORY}.fasta

        # Run organisms with TSS
        if [ "$DIRECTORY" = "Arabidopsis_thaliana_private" ] || \
           [ "$DIRECTORY" = "Arabidopsis_thaliana" ] || \
           [ "$DIRECTORY" = "Physcomitrium_patens" ] || \
           [ "$DIRECTORY" = "Marchantia_polymorpha" ] || \
           [ "$DIRECTORY" = "Silene_vulgaris" ] || \
           [ "$DIRECTORY" = "Zea_mays" ] || \
           [ "$DIRECTORY" = "Solanum_lycopersicum" ]; then
            echo "Running $DIRECTORY --with-tss"
            dart run bin/pipeline.dart $DIRECTORY --with-tss | tee output/${DIRECTORY}-with-tss.info.txt
            zip output/${DIRECTORY}-with-tss.fasta.zip output/${DIRECTORY}-with-tss.fasta
        fi
    else
        echo "Skipping $FILE: Not a directory."
    fi
done