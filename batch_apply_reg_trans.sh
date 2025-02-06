#!/bin/bash

# Define colors for output messages
GREEN='\033[0;32m'    # Green color
YELLOW='\033[1;33m'   # Yellow color
NC='\033[0m'          # No color

echo -e "${YELLOW}=====[ Batch Processing for Applying Registration Transform ]=====${NC}"

# Input and output folders
FOLDER_FS="$1"
FOLDER_OUT="$2"
TEMPLATE_PATH="$3"
TRANSFORM_PATH="$4"

# Check for valid input
if [ $# -lt 4 ]; then
  echo "Usage: $0 <input_folder> <output_folder> <template_path> <transform_path>"
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

if [ ! -e "$TRANSFORM_PATH" ]; then
  echo "Transform file does not exist: $TRANSFORM_PATH"
  exit 1
fi

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

  # Apply the given transform to the image
  antsApplyTransforms -d 3 \
                      -i "$IMAGE" \
                      -r "$TEMPLATE_PATH" \
                      -o "$OUTPUT_IMAGE" \
                      -t "$TRANSFORM_PATH" \
                      --interpolation Linear

  # Apply the given transform to the segmentation mask
  antsApplyTransforms -d 3 \
                      -i "$SEGMENTATION" \
                      -r "$TEMPLATE_PATH" \
                      -o "$OUTPUT_SEGMENTATION" \
                      -t "$TRANSFORM_PATH" \
                      --interpolation NearestNeighbor

  echo -e "${GREEN}Processed $IMAGE and saved results to $FOLDER_OUT.${NC}"
done

echo -e "${GREEN}=====[ Batch Processing Complete ]=====${NC}"
