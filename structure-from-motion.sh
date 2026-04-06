#!/usr/bin/env bash

# Initialize variables
PASSED=$1
DIR="$PASSED"

OUTPUT=${PWD}/${DIR}
COLMAP="${OUTPUT}/colmap"
IMAGES="${COLMAP}/images"
SPARSE="${COLMAP}/sparse"
DATABASE="${COLMAP}/database.db"
THREADS="$(grep -c ^processor /proc/cpuinfo)"


# Create output directories
printf "Setting up project directory...\n"
mkdir "${COLMAP}"
mkdir "${SPARSE}"

if [[ -d $PASSED ]]; then
    printf "Passed argument is a directory, tracking image sequence...\n"
    IMAGES=$DIR
elif [[ -f $PASSED ]]; then
    # Extract frames
    printf "Passed argument is a file, extracting images...\n"
    mkdir "${OUTPUT}"
    mkdir "${IMAGES}"
    ffmpeg -stats -i "${FILENAME}" -qscale:v 2 "${IMAGES}/frame_%06d.jpg"
    DIR=$(echo "$PASSED" | cut -f 1 -d '.')
else
    printf "Passed argument is not a file or directory"
fi

# Options
printf "Feature matching:\n[1]: Sequential\n[2]: Exhaustive\n"
read feature_matching

# Track sequence
colmap feature_extractor --database_path "${DATABASE}" --image_path "${IMAGES}" --ImageReader.single_camera 1

if [ $feature_matching == "1" ]; then
    colmap sequential_matcher --database_path "${DATABASE}"
elif [ $feature_matching == "2" ]; then
    colmap exhaustive_matcher --database_path "${DATABASE}"
else
    printf "Invalid argument. Defaulting to exhaustive matching\n"
    colmap exhaustive_matcher --database_path "${DATABASE}"
fi

colmap mapper --database_path "${DATABASE}" --image_path "${IMAGES}" --output_path "${SPARSE}" --Mapper.num_threads "${THREADS}"
colmap model_converter --input_path "${SPARSE}/0" --output_path "${SPARSE}" --output_type TXT
