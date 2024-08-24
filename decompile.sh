#!/bin/bash

# Check if a game directory is provided
if [ $# -eq 0 ]; then
    echo "Please provide the path to the Unity game directory."
    exit 1
fi

# Set the path to dnspy.console.exe
DNSPY_PATH="dnspy.console.exe"

# Set the game directory path
GAME_DIR="$1"

# Validate the game directory
if [ ! -d "$GAME_DIR" ]; then
    echo "Error: The specified game directory does not exist."
    exit 1
fi

# Find the Data directory
DATA_DIR=$(find "$GAME_DIR" -type d -name "*_Data" | head -n 1)
if [ -z "$DATA_DIR" ]; then
    echo "Error: Could not find the Data directory in the specified game directory."
    exit 1
fi

# Find the Managed directory
MANAGED_DIR="$DATA_DIR/Managed"
if [ ! -d "$MANAGED_DIR" ]; then
    echo "Error: Could not find the Managed directory."
    exit 1
fi

# Find the Assembly-CSharp.dll
DLL_PATH="$MANAGED_DIR/Assembly-CSharp.dll"
if [ ! -f "$DLL_PATH" ]; then
    echo "Error: Could not find Assembly-CSharp.dll."
    exit 1
fi

# Set the output directory (relative path)
OUTPUT_DIR="./decompiled_assembly"

# Set the include directory for dependencies
INCLUDE_DIR="./include"

# Create the output and include directories if they don't exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$INCLUDE_DIR"

# Run dnspy.console.exe to decompile the DLL with minimal comments and information
"$DNSPY_PATH" -o "$OUTPUT_DIR" "$DLL_PATH" \
    --dont-xml-doc \
    --dont-show-all \
    --dont-tokens \
    --dont-use-debug-syms \
    --dont-field-initializers \
    --dont-one-ca-per-line

echo "Decompilation complete. Output saved to $OUTPUT_DIR"

# Copy dependencies to the include directory
echo "Copying dependencies from $MANAGED_DIR to $INCLUDE_DIR..."

# Copy all DLL files except Assembly-CSharp.dll
find "$MANAGED_DIR" -maxdepth 1 -type f -name "*.dll" ! -name "Assembly-CSharp.dll" -exec cp {} "$INCLUDE_DIR" \;

echo "Dependencies copied to $INCLUDE_DIR"

echo "copying decompilation to work directory. make your changes in the work direcotry, then generate/apply patches."
rm -r work/
cp- r $OUTPUT_DIR work/