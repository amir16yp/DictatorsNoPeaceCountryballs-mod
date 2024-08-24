#!/bin/bash

# Set the directories
ORIGINAL_DIR="decompiled_assembly"
MODIFIED_DIR="work"
PATCH_DIR="patches"

# Check if the directories exist
if [ ! -d "$ORIGINAL_DIR" ]; then
    echo "Error: Original directory '$ORIGINAL_DIR' not found."
    exit 1
fi

if [ ! -d "$MODIFIED_DIR" ]; then
    echo "Error: Modified directory '$MODIFIED_DIR' not found."
    exit 1
fi

# Create the patch directory if it doesn't exist
mkdir -p "$PATCH_DIR"

# Convert all files to Unix line endings
echo "Converting files to Unix line endings..."
find "$ORIGINAL_DIR" "$MODIFIED_DIR" -type f -exec dos2unix {} +

# Generate patches for modified files and copy new files
while IFS= read -r -d '' file; do
    # Get the relative path of the file
    rel_path=${file#$MODIFIED_DIR/}
    patch_path="$PATCH_DIR/${rel_path//\//_}.patch"
    
    if [ -f "$ORIGINAL_DIR/$rel_path" ]; then
        # File exists in both directories, generate a patch
        diff -u --strip-trailing-cr "$ORIGINAL_DIR/$rel_path" "$file" > "$patch_path"
        
        # Check if the patch is empty (no differences)
        if [ ! -s "$patch_path" ]; then
            rm "$patch_path"
        else
            echo "Generated patch for $rel_path"
        fi
    else
        # File is new, copy it to the patch directory with .new extension
        mkdir -p "$(dirname "$PATCH_DIR/${rel_path//\//_}.new")"
        cp "$file" "$PATCH_DIR/${rel_path//\//_}.new"
        echo "Copied new file: $rel_path"
    fi
done < <(find "$MODIFIED_DIR" -type f -print0)

# Check for deleted files
while IFS= read -r -d '' file; do
    rel_path=${file#$ORIGINAL_DIR/}
    if [ ! -f "$MODIFIED_DIR/$rel_path" ]; then
        echo "File deleted: $rel_path" > "$PATCH_DIR/${rel_path//\//_}.deleted"
        echo "Marked deleted file: $rel_path"
    fi
done < <(find "$ORIGINAL_DIR" -type f -print0)

echo "Patch generation complete. Patches, new files, and deletion markers are stored in the '$PATCH_DIR' directory."