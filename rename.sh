#!/bin/bash
apt-get update && apt-get install -y exiftool

# docker run -v "${PWD}:/photos" -w /photos perl:latest bash /photos/run.sh

for file in *.jpg *.JPG *.jpeg *.JPEG; do
    [ -e "$file" ] || continue
    
    basename="${file%.*}"
    extension="${file##*.}"
    
    if [[ "$basename" =~ ~[0-9]{8}_[0-9]{6}$ ]]; then
        echo "Skipped: $file"
        continue
    fi
    
    datetime=$(exiftool -DateTimeOriginal -d "%Y%m%d_%H%M%S" -s3 "$file" 2>/dev/null)
    
    if [ -z "$datetime" ]; then
        datetime=$(exiftool -CreateDate -d "%Y%m%d_%H%M%S" -s3 "$file" 2>/dev/null)
    fi
    
    if [ -n "$datetime" ]; then
        newname="${basename}~${datetime}.${extension}"
        mv "$file" "$newname"
        echo "Renamed: $file -> $newname"
    else
        echo "No date: $file"
    fi
done