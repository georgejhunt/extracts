#!/bin/bash -x
set -o errexit
set -o pipefail

readonly CSV_FILE=${CSV_FILE:-"extracts.csv"}
readonly PLANET_MBTILES=${PLANET_MBTILES:-"planet.mbtiles"}
readonly SAT_URL=${SAT_URL:-"tms:https://tiles.maps.eox.at/wmts?layer=s2cloudless-2018_3857&style=default&tilematrixset=g&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image%2Fjpeg&TileMatrix={z}&TileCol={x}&TileRow={y}"}
readonly EXTRACT_DIR=$(dirname "$PLANET_MBTILES")
readonly PATCH_ZOOM=7  #${BASE_ZOOM:-"5"}
readonly PATCH_SRC=$EXTRACT_DIR/${PLANET_BASE:-"satellite_z0-z${PATCH_ZOOM}.mbtiles"}


function main() {
    if [ ! -f "$PLANET_MBTILES" ]; then
        echo "$PLANET_MBTILES not found."
        exit 10
    fi

    # Generate patch sources first but do not upload them
    if [ ! -f $MR_SSD/output/stage2/satellite_z0-z${PATCH_ZOOM}.mbtiles ];then
      python -u create_extracts.py zoom-level "$SAT_URL" \
        --max-zoom=${PATCH_ZOOM} --target-dir="$EXTRACT_DIR"
    fi
    python -u create_extracts.py bbox "$PLANET_MBTILES" "$CSV_FILE" \
        --patch-from="$PATCH_SRC" --target-dir="$EXTRACT_DIR" $upload_flag
}

main
