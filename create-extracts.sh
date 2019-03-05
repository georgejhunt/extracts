#!/bin/bash -x
set -o errexit
set -o pipefail

readonly CSV_FILE=${CSV_FILE:-"extracts.csv"}
readonly PLANET_MBTILES=${PLANET_MBTILES:-"planet.mbtiles"}
readonly EXTRACT_DIR=$(dirname "$PLANET_MBTILES")
readonly PATCH_ZOOM=${BASE_ZOOM:-"9"}
readonly PATCH_SRC=$EXTRACT_DIR/${PLANET_BASE:-"planet_z0-z${PATCH_ZOOM}.mbtiles"}

function main() {
    if [ ! -f "$PLANET_MBTILES" ]; then
        echo "$PLANET_MBTILES not found."
        exit 10
    fi

    local upload_flag='--upload'
    if [ -z "${S3_ACCESS_KEY}" ]; then
        upload_flag=''
        echo 'Skip upload since no S3_ACCESS_KEY was found.'
    fi

    # Generate patch sources first but do not upload them
    if [ ! -f $MG_HARD_DISK/output/planet_z0-z5.mbtiles ];then
      python -u create_extracts.py zoom-level "$PLANET_MBTILES" \
        --max-zoom=5 --target-dir="$EXTRACT_DIR"
    fi
    if [ ! -f $MG_HARD_DISK/output/planet_z0-z${PATCH_ZOOM}.mbtiles ];then
       python -u create_extracts.py zoom-level "$PLANET_MBTILES" \
        --max-zoom=${PATCH_ZOOM} --target-dir="$EXTRACT_DIR"
    fi

    python -u create_extracts.py bbox "$PLANET_MBTILES" "$CSV_FILE" \
        --patch-from="$PATCH_SRC" --target-dir="$EXTRACT_DIR" $upload_flag
}

main
