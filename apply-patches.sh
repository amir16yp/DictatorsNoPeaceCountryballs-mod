#!/bin/bash

# Set the directories
ORIGINAL_DIR="decompiled_assembly"
WORK_DIR="work"
PATCH_DIR="patches"

# Check if the original directory exists
if [ ! -d "$ORIGINAL_DIR" ]; then
    echo "Error: Original directory '$ORIGINAL_DIR' not found."
    exit 1
fi

# Remove the existing work directory if it exists
if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

# Copy the original directory to the work directory
cp -r "$ORIGINAL_DIR" "$WORK_DIR"

# Check if the patch directory exists
if [ ! -d "$PATCH_DIR" ]; then
    echo "Error: Patch directory '$PATCH_DIR' not found."
    exit 1
fi

# Convert all files in the work directory to Unix line endings
echo "Converting files to Unix line endings..."
find "$WORK_DIR" -type f -exec dos2unix {} +

# Function to apply a patch
apply_patch() {
    local patch_file="$1"
    local target_file="$2"
    if patch --dry-run -R -p1 < "$patch_file" >/dev/null 2>&1; then
        echo "Reverse patch detected, applying with -R option"
        patch -R -p1 -u -F 3 --ignore-whitespace "$target_file" < "$patch_file"
    else
        patch -p1 -u -F 3 --ignore-whitespace "$target_file" < "$patch_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Successfully applied patch: $patch_file"
    else
        echo "Failed to apply patch: $patch_file"
    fi
}

# Apply patches and handle new/deleted files
for item in "$PATCH_DIR"/*; do
    if [[ "$item" == *.patch ]]; then
        # It's a patch file
        rel_path=$(echo "$item" | sed -e "s|$PATCH_DIR/||" -e 's/\.patch$//' -e 's/_/\//g')
        target_file="$WORK_DIR/$rel_path"
        apply_patch "$item" "$target_file"
    elif [[ "$item" == *.new ]]; then
        # It's a new file
        rel_path=$(echo "$item" | sed -e "s|$PATCH_DIR/||" -e 's/\.new$//' -e 's/_/\//g')
        mkdir -p "$(dirname "$WORK_DIR/$rel_path")"
        cp "$item" "$WORK_DIR/$rel_path"
        echo "Copied new file: $rel_path"
    elif [[ "$item" == *.deleted ]]; then
        # It's a deletion marker
        rel_path=$(echo "$item" | sed -e "s|$PATCH_DIR/||" -e 's/\.deleted$//' -e 's/_/\//g')
        if [ -f "$WORK_DIR/$rel_path" ]; then
            rm "$WORK_DIR/$rel_path"
            echo "Deleted file: $rel_path"
        else
            echo "Warning: File to delete not found: $rel_path"
        fi
    fi
done

echo "Patch application complete. Modified files are in the '$WORK_DIR' directory."

# echo "Fixing dependencies..."

# # Find all .csproj files in the work directory and run deps-fixer.sh on them
# find "$WORK_DIR" -name "*.csproj" | while read -r csproj_file; do
#     echo "Fixing dependencies for: $csproj_file"
#     bash deps-fixer.sh "$csproj_file"
#     if [ $? -eq 0 ]; then
#         echo "Successfully fixed dependencies for: $csproj_file"
#     else
#         echo "Failed to fix dependencies for: $csproj_file"
#     fi
# done

# echo "Dependency fixing complete."