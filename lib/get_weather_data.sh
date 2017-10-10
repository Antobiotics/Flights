#!/bin/bash
YEAR="2013"
ARCHIVE_BASE_NAME="gsod_""${YEAR}"
URL="ftp://ftp.ncdc.noaa.gov/pub/data/gsod/"${YEAR}"/$ARCHIVE_BASE_NAME.tar"
TMP_DATA_DIR="./data/tmp"
WEATHER_DATA_DIR="$TMP_DATA_DIR"/"$ARCHIVE_BASE_NAME"

mkdir -p $WEATHER_DATA_DIR

echo "Fetching Archive"
wget -P $TMP_DATA_DIR "$URL"

echo "Extracting Data"
tar -zxvf "$TMP_DATA_DIR"/"$ARCHIVE_BASE_NAME".tar -C $WEATHER_DATA_DIR

cd "$WEATHER_DATA_DIR" || exit 1

echo "Expanding datasets"
ls | xargs -I {} bash -c "gunzip {}"

cd - || exit 1
