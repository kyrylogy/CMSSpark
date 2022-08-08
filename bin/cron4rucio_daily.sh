#!/bin/bash
# Daily Rucio dumps
HDFS_OUTPUT_DIR="${1}"
CURRENT_DATE="$(date +%Y-%m-%d)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

/bin/bash "$SCRIPT_DIR/run_rucio_daily.sh" --verbose --output_folder "$HDFS_OUTPUT_DIR" --fdate "$CURRENT_DATE"

# ----- CRON SUCCESS CHECK -----
# This cron job runs each day and threshold should be at max 12 hours, so 43200
# Let's check the current output sizes: hadoop fs -du -h /cms/rucio_daily/rucio/2022/08
# So, in average directory size is 80MB, so we can give 50Mb, in bytes 50000000

CURRENT_DATE_HDFS="$(date +%Y/%m/%d)"
/bin/bash "$SCRIPT_DIR"/utils/check_utils.sh check_hdfs "$HDFS_OUTPUT_DIR"/rucio/"$CURRENT_DATE_HDFS" 43200 50000000

# !!ATTENTION!! no command should be run after this point
