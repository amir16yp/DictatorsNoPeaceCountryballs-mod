#!/bin/bash

# Check if a .csproj file path is provided
if [ $# -eq 0 ]; then
    echo "Please provide the path to the .csproj file."
    exit 1
fi

# Set the .csproj file path
CSPROJ_PATH="$1"

# Set the include directory path
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INCLUDE_DIR="$SCRIPT_DIR/include"

# Convert to Windows path
INCLUDE_DIR_WIN=$(echo "$INCLUDE_DIR" | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/')

# Check if the .csproj file exists
if [ ! -f "$CSPROJ_PATH" ]; then
    echo "Error: The specified .csproj file does not exist: $CSPROJ_PATH"
    exit 1
fi

# Check if the include directory exists
if [ ! -d "$INCLUDE_DIR" ]; then
    echo "Error: The include directory does not exist: $INCLUDE_DIR"
    exit 1
fi

# Create a temporary file
TEMP_FILE=$(mktemp)

# Process the .csproj file
while IFS= read -r line; do
    if [[ $line =~ \<ItemGroup\> ]]; then
        echo "$line" >> "$TEMP_FILE"
        # Add new references for all DLLs in the include directory
        for dll in "$INCLUDE_DIR"/*.dll; do
            dll_name=$(basename "$dll")
            echo "    <Reference Include=\"$(basename "$dll" .dll)\">" >> "$TEMP_FILE"
            echo "      <HintPath>$INCLUDE_DIR_WIN\\$dll_name</HintPath>" >> "$TEMP_FILE"
            echo "    </Reference>" >> "$TEMP_FILE"
        done
        # Skip existing Reference Include elements
        while IFS= read -r subline; do
            if [[ $subline =~ \</ItemGroup\> ]]; then
                echo "$subline" >> "$TEMP_FILE"
                break
            fi
        done
    elif [[ ! $line =~ \<Reference ]]; then
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$CSPROJ_PATH"
# Replace the original file with the modified content
mv "$TEMP_FILE" "$CSPROJ_PATH"

echo "Updated references in $CSPROJ_PATH with all DLLs from $INCLUDE_DIR_WIN"