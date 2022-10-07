#!/bin/sh

rm -rf output
mkdir output
echo "Running Ambo..."
dart run bin/pipeline.dart Ambo > output/ambo_info.txt
echo "Running Mp..."
dart run bin/pipeline.dart Mp > output/mp_info.txt
echo "Running Physco..."
dart run bin/pipeline.dart Physco > output/physco_info.txt
echo "Running Sola..."
dart run bin/pipeline.dart Sola > output/sola_info.txt