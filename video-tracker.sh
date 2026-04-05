#!/usr/bin/env bash

# Initialize variables
FILENAME="${1}"
DIR=$(echo "$FILENAME" | cut -f 1 -d '.')
OUTPUT=${PWD}/${DIR}
COLMAP="${OUTPUT}/colmap"
IMAGES="${COLMAP}/images"
SPARSE="${COLMAP}/sparse"
DATABASE="${COLMAP}/database.db"
THREADS="$(grep -c ^processor /proc/cpuinfo)"

# Create output directories
echo "Setting up project directory...\n"
mkdir "${OUTPUT}"
mkdir "${COLMAP}"
mkdir "${IMAGES}"
mkdir "${SPARSE}"

# Options
read -sp "Feature matching:\n[1]: Sequential\n[2]: Exhaustive\n" feature_matching

# Extract frames
ffmpeg -stats -i "${FILENAME}" -qscale:v 2 "${IMAGES}/frame_%06d.jpg"

# Track sequence
colmap feature_extractor --database_path "${DATABASE}" --image_path "${IMAGES}" --ImageReader.single_camera 1

if [ $feature_matching == "1" ]; then
    colmap sequential_matcher --database_path "${DATABASE}"
elif [ $feature_matching == "2" ]; then
    colmap exhaustive_matcher --database_path "${DATABASE}"
else
    echo "Invalid argument. Defaulting to exhaustive matching"
    colmap exhaustive_matcher --database_path "${DATABASE}"
fi

colmap mapper --database_path "${DATABASE}" --image_path "${IMAGES}" --output_path "${SPARSE}" --Mapper.num_threads "${THREADS}"
colmap model_converter --input_path "${SPARSE}/0" --output_path "${SPARSE}" --output_type TXT
