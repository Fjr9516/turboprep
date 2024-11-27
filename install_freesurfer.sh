#!/bin/bash

# Set variables
TEMP_DIR="${PWD}/tmp/freesurfer_install"
URL="https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer_ubuntu22-7.4.1_amd64.deb"
FILE_NAME="freesurfer_ubuntu22-7.4.1_amd64.deb"
MD5_SUM_EXPECTED="bfe85dd76677cfb7ca2b247b9ac6148e"

# Create the temporary directory
echo "Creating temporary directory at $TEMP_DIR..."
mkdir -p "$TEMP_DIR"

# Change to the temporary directory
cd "$TEMP_DIR" || exit 1

# Step 1: Download the DEB file
echo "Downloading FreeSurfer to $TEMP_DIR..."
wget -O "$FILE_NAME" "$URL"

# Step 2: Verify the MD5 checksum
echo "Verifying checksum..."
MD5_SUM_ACTUAL=$(md5sum "$FILE_NAME" | awk '{print $1}')

if [ "$MD5_SUM_ACTUAL" != "$MD5_SUM_EXPECTED" ]; then
    echo "MD5 checksum verification failed!"
    echo "Expected: $MD5_SUM_EXPECTED"
    echo "Actual: $MD5_SUM_ACTUAL"
    exit 1
fi

echo "Checksum verified successfully."

# Step 3: Install the DEB file
echo "Installing FreeSurfer..."
sudo dpkg -i "$FILE_NAME"

# Step 4: Fix dependencies if needed
echo "Checking for missing dependencies..."
sudo apt-get install -f -y

# Step 5: Clean up
echo "Cleaning up temporary files..."
# rm -rf "$TEMP_DIR"

# Step 6: Set up FreeSurfer environment
echo "Setting up FreeSurfer environment..."
export FREESURFER_HOME=/usr/local/freesurfer/7.4.1
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Verify the installation
echo "Verifying FreeSurfer installation..."
freesurfer --version

