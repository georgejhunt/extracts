#!/bin/bash 
set -o errexit
set -o pipefail

readonly CSV_FILE=${CSV_FILE:-"./data/iiab.csv"}
# https://ia802807.us.archive.org/21/items/osm-vector-mbtiles/2020-10-planet-14.mbtiles
readonly PLANET_MBTILES=${PLANET_MBTILES:-"./data/2020-10-planet-14.mbtiles"}
readonly EXTRACT_DIR=${EXTRACT_DIR:-"PLANET_MBTILES"}
readonly PATCH_ZOOM=${BASE_ZOOM:-"10"}
readonly PATCH_SRC=$EXTRACT_DIR/${PLANET_BASE:-"planet_z0-z${PATCH_ZOOM}.mbtiles"}
scriptdir=$(dirname $0)

echo $CSV_FILE
echo $PLANET_MBTILES
echo $EXTRACT_DIR
echo Zoom =$PATCH_ZOOM
echo planet base = $PATCH_SRC

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
    if [ ! -f $EXTRACT_DIR/planet_z0-z6.mbtiles ];then
      echo Writing $EXTRACT_DIR/planet_z0-z6.mbtiles
      python3 -u $scriptdir/create_extracts.py zoom-level "$PLANET_MBTILES" \
        --max-zoom=6 --target-dir="$EXTRACT_DIR"
    else
        echo File already exists: $EXTRACT_DIR/planet_z0-z6.mbtiles
    fi
    if [ ! -f $EXTRACT_DIR/planet_z0-z${PATCH_ZOOM}.mbtiles ];then
       echo 'Writing %S'%$EXTRACT_DIR/planet_z0-z${PATCH_ZOOM}.mbtiles
       python3 -u $scriptdir/create_extracts.py zoom-level "$PLANET_MBTILES" \
        --max-zoom=${PATCH_ZOOM} --target-dir="$EXTRACT_DIR"
    else
        echo File already exists: $EXTRACT_DIR/planet_z0-z${PATCH_ZOOM}.mbtiles 
    fi

    python3 -u $scriptdir/create_extracts.py bbox "$PLANET_MBTILES" "$CSV_FILE" \
        --target-dir="$EXTRACT_DIR" --min-zoom=11
        #--patch-from="$PATCH_SRC" --target-dir="$EXTRACT_DIR" 
}

main
