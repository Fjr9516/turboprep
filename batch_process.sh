#!/bin/bash

# Define colors for output messages
GREEN='\033[0;32m'    # Green color
YELLOW='\033[1;33m'   # Yellow color
NC='\033[0m'          # No color

echo -e "${YELLOW}=====[ Batch Processing for Affine Registration and Segmentation Transformation ]=====${NC}"

# Input and output folders
FOLDER_FS="$1"
FOLDER_OUT="$2"
TEMPLATE_PATH="$3"

# Check for valid input
if [ $# -lt 3 ]; then
  echo "Usage: $0 <input_folder> <output_folder> <template_path>"
  exit 1
fi

if [ ! -d "$FOLDER_FS" ]; then
  echo "Input folder does not exist: $FOLDER_FS"
  exit 1
fi

if [ ! -d "$FOLDER_OUT" ]; then
  mkdir -p "$FOLDER_OUT"
fi

if [ ! -e "$TEMPLATE_PATH" ]; then
  echo "Template file does not exist: $TEMPLATE_PATH"
  exit 1
fi

# Dynamically determine the number of threads to use
THREADS=$(nproc)

# Process each pair of image and segmentation in FOLDER_FS
for IMAGE in "$FOLDER_FS"/*_d*.nii.gz; do
  BASENAME=$(basename "$IMAGE" .nii.gz)
  SEGMENTATION="${FOLDER_FS}/${BASENAME}_SynthSeg.nii.gz"

  if [ ! -e "$SEGMENTATION" ]; then
    echo "Segmentation mask not found for $IMAGE. Skipping."
    continue
  fi

  echo -e "${YELLOW}Processing $IMAGE and $SEGMENTATION...${NC}"

  OUTPUT_IMAGE="$FOLDER_OUT/$BASENAME.nii.gz"
  OUTPUT_SEGMENTATION="$FOLDER_OUT/${BASENAME}_SynthSeg.nii.gz"
  INTERMEDIATE_DIR=$(mktemp -d)

  # Step 1: Run antsRegistrationSyNQuick.sh
  antsRegistrationSyNQuick.sh -d 3 \
                              -f "$TEMPLATE_PATH" \
                              -m "$IMAGE" \
                              -o "$INTERMEDIATE_DIR/turboprep_" \
                              -n "$THREADS" \
                              -t a

  # Step 2: Apply the affine transformation to the segmentation mask
  antsApplyTransforms -d 3 \
                      -i "$SEGMENTATION" \
                      -r "$TEMPLATE_PATH" \
                      -o "$OUTPUT_SEGMENTATION" \
                      -t "${INTERMEDIATE_DIR}/turboprep_0GenericAffine.mat" \
                      --interpolation NearestNeighbor

  # Step 3: Save the registered image
  cp "${INTERMEDIATE_DIR}/turboprep_Warped.nii.gz" "$OUTPUT_IMAGE"

  # Step 4: Clean up intermediate files
  rm -rf "$INTERMEDIATE_DIR"

  echo -e "${GREEN}Processed $IMAGE and saved results to $FOLDER_OUT.${NC}"
done

echo -e "${GREEN}=====[ Batch Processing Complete ]=====${NC}"
