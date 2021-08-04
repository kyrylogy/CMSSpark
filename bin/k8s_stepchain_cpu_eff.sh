#!/bin/bash
# This script is intended to be used as cron job in kubernetes.

# Check output path is given
[[ -z "$1" ]] && { echo "ERROR: Output path is not defined" ; exit 1; }

# Check env vars are set
[[ -z "$MY_NODE_NAME" ]] && { echo "ERROR: MY_NODE_NAME is not defined" ; exit 1; }
[[ -z "$CONDOR_CPU_EFF_SERVICE_PORT_PORT_0" ]] && { echo "ERROR: CONDOR_CPU_EFF_SERVICE_PORT_PORT_0 is not defined" ; exit 1; }
[[ -z "$CONDOR_CPU_EFF_SERVICE_PORT_PORT_1" ]] && { echo "ERROR: CONDOR_CPU_EFF_SERVICE_PORT_PORT_1 is not defined" ; exit 1; }


# Kerberos
keytab=/etc/condor-cpu-eff/keytab
principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal"
kinit $principal -k -t "$keytab"
if [ $? == 1 ]; then
    echo "Unable to perform kinit"
    exit 1
fi
klist -k "$keytab"

# Start crond if it is not runing
if [ -z "`ps auxww | grep crond | grep -v grep`" ]; then
    crond -n &
fi

currentDir=$(
  cd "$(dirname "$0")" && pwd
)

spark_submit=/usr/hdp/spark-2.3.0/bin/spark-submit
spark_confs=(
    --conf spark.driver.bindAddress=0.0.0.0
    --conf spark.driver.host=$MY_NODE_NAME
    --conf spark.driver.port=$CONDOR_CPU_EFF_SERVICE_PORT_PORT_0
    --conf spark.driver.blockManager.port=$CONDOR_CPU_EFF_SERVICE_PORT_PORT_1
    --conf spark.driver.extraClassPath='$WDIR/hadoop-mapreduce-client-core-2.6.0-cdh5.7.6.jar'
    --conf spark.executor.memory=8g
    --conf spark.executor.instances=60
    --conf spark.executor.cores=4
    --conf spark.driver.memory=4g
)

OUTPUT_DIR="${1}/stepchain"

echo "Starting spark job for stepchain cpu efficiencies, folder: " $OUTPUT_DIR
$spark_submit --master yarn "${spark_confs[@]}" \
	"$currentDir/../src/python/CMSSpark/stepchain_cpu_eff.py" --output_folder "$OUTPUT_DIR"

