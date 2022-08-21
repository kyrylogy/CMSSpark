#!/bin/bash

if [ $# -ne 1 ]; then
    echo "dbs_events <output_dir>"
    exit 1
fi

wdir=$1
odir=$wdir/dbs_events
odf=$wdir/dbs_events.csv
hdir=/tmp/kmeliush/

# remove existing hadoop area
hadoop fs -rm -r -skipTrash $odir 2>&1 1>&/dev/null
if [ -d $odir ]; then
    rm -rf $odir
fi
mkdir -p $odir

# run dbs_events.py workflow
echo "PATH=$PATH"
echo "PYTHONPATH=$PYTHONPATH"
echo "PWD=$PWD"
/bin/bash src/python/run_spark dbs_events.py --yarn --fout=$wdir

# get back data frame parts
hadoop fs -get /cms/dbs_events $odir/
head -1 $odir/dbs_events/part-00000* >$odf
cat $odir/dbs_events/part* | grep -v nevents | sed -e "s,\",,g" >>$odf
rm -f ${odf}.gz
gzip $odf
rm -rf $odir
