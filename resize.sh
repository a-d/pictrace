#!/bin/bash
# resize.sh - Image processing script for pictrace
# Replaces gulpfile.js with pure bash + CLI tools
# 
# Requirements:
#   apt install imagemagick libavif-bin libimage-exiftool-perl
#
# Usage:
#   ./resize.sh                    # Interactive mode (prompts for year/location)
#   ./resize.sh 2026 "Paris"       # Direct mode with arguments
#   ./resize.sh 2026 "Paris" -d    # Delete originals after processing
#   ./resize.sh 2026 "Paris" -v    # Verbose mode (show avifenc output)
#   ./resize.sh 2026 "Paris" -d -v # Combine flags

# Note: Not using 'set -e' as it can cause unexpected exits with arithmetic operations

# Handle Ctrl+C gracefully
INTERRUPTED=false
trap 'INTERRUPTED=true; echo -e "\n${YELLOW}Interrupted! Finishing current image...${NC}"' INT

# Configuration
FULL_WIDTH=1024
THUMB_WIDTH=512
FULL_QUALITY=95               # Base quality (used for JPG)
THUMB_QUALITY=80              # Base quality (used for JPG)
AVIF_QUALITY_MULTIPLIER=0.83  # AVIF uses lower quality number (more efficient codec)
IMAGES_DIR="images"

# Convert JPEG-style quality (0-100) to avifenc quantizer (0-63)
# Higher quality = lower quantizer
# Formula: quantizer = 63 - (quality * 63 / 100)
quality_to_quantizer() {
    local quality=$1
    echo $(( 63 - (quality * 63 / 100) ))
}

# Calculate AVIF quality (apply multiplier)
# Using awk for floating-point math, then truncate to integer
AVIF_FULL_QUALITY=$(awk "BEGIN {printf \"%.0f\", $FULL_QUALITY * $AVIF_QUALITY_MULTIPLIER}")
AVIF_THUMB_QUALITY=$(awk "BEGIN {printf \"%.0f\", $THUMB_QUALITY * $AVIF_QUALITY_MULTIPLIER}")

FULL_QUANTIZER=$(quality_to_quantizer $AVIF_FULL_QUALITY)
THUMB_QUANTIZER=$(quality_to_quantizer $AVIF_THUMB_QUALITY)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments or prompt interactively
DELETE_ORIGINALS=false
VERBOSE=false

if [ $# -ge 2 ]; then
    YEAR="$1"
    LOCATION="$2"
    shift 2
    # Parse remaining flags
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--delete) DELETE_ORIGINALS=true ;;
            -v|--verbose) VERBOSE=true ;;
        esac
        shift
    done
else
    read -p "Enter the year: " YEAR
    read -p "Enter the location: " LOCATION
    read -p "Delete original images after processing? [y/N]: " DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" =~ ^[Yy]$ ]]; then
        DELETE_ORIGINALS=true
    fi
fi

# Validate inputs
if [ -z "$YEAR" ] || [ -z "$LOCATION" ]; then
    echo -e "${RED}Error: Year and location are required${NC}"
    exit 1
fi

# Function to get indexed location directory
get_indexed_location() {
    local year="$1"
    local location="$2"
    local year_dir="$IMAGES_DIR/$year"
    
    # Create year directory if it doesn't exist
    if [ ! -d "$year_dir" ]; then
        mkdir -p "$year_dir"
        echo "01_$location"
        return
    fi
    
    # Check if this location already exists (with any index)
    local existing=$(find "$year_dir" -maxdepth 1 -type d -name "*_$location" 2>/dev/null | head -1)
    if [ -n "$existing" ]; then
        basename "$existing"
        return
    fi
    
    # Find the highest index currently in use
    local highest_index=0
    for dir in "$year_dir"/*/; do
        [ -d "$dir" ] || continue
        local dirname=$(basename "$dir")
        if [[ "$dirname" =~ ^([0-9]+)_ ]]; then
            local idx=${BASH_REMATCH[1]}
            idx=$((10#$idx))  # Remove leading zeros for arithmetic
            if [ $idx -gt $highest_index ]; then
                highest_index=$idx
            fi
        fi
    done
    
    # Use the next available index
    local next_index=$((highest_index + 1))
    printf "%02d_%s" $next_index "$location"
}

# Get the indexed directory name
DIR=$(get_indexed_location "$YEAR" "$LOCATION")
FULLS_DIR="$IMAGES_DIR/$YEAR/$DIR/fulls"
THUMBS_DIR="$IMAGES_DIR/$YEAR/$DIR/thumbs"

echo -e "${BLUE}Processing images for: $YEAR / $DIR${NC}"
echo -e "Full-size: ${FULL_WIDTH}px @ ${FULL_QUALITY}% quality"
echo -e "Thumbnails: ${THUMB_WIDTH}px @ ${THUMB_QUALITY}% quality"
echo ""

# Create output directories
mkdir -p "$FULLS_DIR" "$THUMBS_DIR"

# Find all images in the root images directory
shopt -s nullglob nocaseglob
IMAGE_FILES=("$IMAGES_DIR"/*.{jpg,jpeg,png,tiff,tif,webp})
shopt -u nullglob nocaseglob

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No images found in $IMAGES_DIR/${NC}"
    echo "Place your images in the '$IMAGES_DIR' directory and run again."
    exit 0
fi

echo -e "${GREEN}Found ${#IMAGE_FILES[@]} image(s) to process${NC}"
echo ""

# Process each image
PROCESSED=0
FAILED=0

for img in "${IMAGE_FILES[@]}"; do
    # Check for Ctrl+C interrupt
    [ "$INTERRUPTED" = true ] && break
    [ -f "$img" ] || continue
    
    FILENAME=$(basename "$img")
    BASENAME="${FILENAME%.*}"
    
    echo -e "${BLUE}Processing: $FILENAME${NC}"
    
    # Create temporary PNG files for lossless intermediate (avoids JPG→AVIF transcoding loss)
    TEMP_FULL="/tmp/resize_full_$$.png"
    TEMP_THUMB="/tmp/resize_thumb_$$.png"
    
    # Resize to lossless PNG intermediates (preserves quality for both JPG and AVIF encoding)
    echo -n "  Resizing to ${FULL_WIDTH}px... "
    if convert "$img" -resize "${FULL_WIDTH}x>" "$TEMP_FULL" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
        rm -f "$TEMP_FULL" "$TEMP_THUMB" 2>/dev/null
        continue
    fi
    
    echo -n "  Resizing to ${THUMB_WIDTH}px... "
    if convert "$img" -resize "${THUMB_WIDTH}x>" "$TEMP_THUMB" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
        rm -f "$TEMP_FULL" "$TEMP_THUMB" 2>/dev/null
        continue
    fi
    
    # Full-size JPG (with essential EXIF metadata only)
    echo -n "  Creating full-size JPG... "
    if convert "$TEMP_FULL" -quality "$FULL_QUALITY" -interlace Plane "$FULLS_DIR/$BASENAME.jpg" 2>/dev/null; then
        # Copy only essential EXIF tags (Model, FNumber, FocalLength, ExposureTime, ISO)
        # This reduces metadata from ~77KB to ~1-2KB
        exiftool -overwrite_original -TagsFromFile "$img" \
            -Model -Make -FNumber -FocalLength -FocalLengthIn35mmFormat \
            -ExposureTime -ISOSpeedRatings -ISO -DateTimeOriginal \
            "$FULLS_DIR/$BASENAME.jpg" >/dev/null 2>&1
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
        rm -f "$TEMP_FULL" "$TEMP_THUMB" 2>/dev/null
        continue
    fi
    
    # Full-size AVIF (encoded from lossless PNG, not from JPG)
    echo -n "  Creating full-size AVIF... "
    # --yuv 420 for better compression (same as JPEG uses)
    # Encode directly from PNG to avoid generation loss
    if [ "$VERBOSE" = true ]; then
        avifenc --speed 6 --jobs all --yuv 420 --min 0 --max "$FULL_QUANTIZER" -- "$TEMP_FULL" "$FULLS_DIR/$BASENAME.avif"
        AVIF_RESULT=$?
    else
        avifenc --speed 6 --jobs all --yuv 420 --min 0 --max "$FULL_QUANTIZER" -- "$TEMP_FULL" "$FULLS_DIR/$BASENAME.avif" >/dev/null 2>&1
        AVIF_RESULT=$?
    fi
    if [ $AVIF_RESULT -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}SKIPPED (avifenc failed)${NC}"
    fi
    
    # Thumbnail JPG (with essential EXIF metadata only)
    echo -n "  Creating thumbnail JPG... "
    if convert "$TEMP_THUMB" -quality "$THUMB_QUALITY" -interlace Plane "$THUMBS_DIR/$BASENAME.jpg" 2>/dev/null; then
        # Copy only essential EXIF tags (Model, FNumber, FocalLength, ExposureTime, ISO)
        # This reduces metadata from ~77KB to ~1-2KB
        exiftool -overwrite_original -TagsFromFile "$img" \
            -Model -Make -FNumber -FocalLength -FocalLengthIn35mmFormat \
            -ExposureTime -ISOSpeedRatings -ISO -DateTimeOriginal \
            "$THUMBS_DIR/$BASENAME.jpg" >/dev/null 2>&1
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
        rm -f "$TEMP_FULL" "$TEMP_THUMB" 2>/dev/null
        continue
    fi
    
    # Thumbnail AVIF (encoded from lossless PNG, not from JPG)
    echo -n "  Creating thumbnail AVIF... "
    # --yuv 420 for better compression (same as JPEG uses)
    if [ "$VERBOSE" = true ]; then
        avifenc --speed 6 --jobs all --yuv 420 --min 0 --max "$THUMB_QUANTIZER" -- "$TEMP_THUMB" "$THUMBS_DIR/$BASENAME.avif"
        AVIF_RESULT=$?
    else
        avifenc --speed 6 --jobs all --yuv 420 --min 0 --max "$THUMB_QUANTIZER" -- "$TEMP_THUMB" "$THUMBS_DIR/$BASENAME.avif" >/dev/null 2>&1
        AVIF_RESULT=$?
    fi
    if [ $AVIF_RESULT -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}SKIPPED (avifenc failed)${NC}"
    fi
    
    # Cleanup temporary files
    rm -f "$TEMP_FULL" "$TEMP_THUMB" 2>/dev/null
    
    PROCESSED=$((PROCESSED + 1))
    echo ""
done

echo -e "${GREEN}Processed: $PROCESSED image(s)${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED image(s)${NC}"
fi

# Delete originals if requested
if [ "$DELETE_ORIGINALS" = true ]; then
    echo ""
    echo -e "${YELLOW}Deleting original images...${NC}"
    for img in "${IMAGE_FILES[@]}"; do
        [ -f "$img" ] && rm "$img"
    done
    echo -e "${GREEN}Original images deleted${NC}"
fi

echo ""
echo -e "${GREEN}Done! Images saved to:${NC}"
echo "  Full-size: $FULLS_DIR"
echo "  Thumbnails: $THUMBS_DIR"