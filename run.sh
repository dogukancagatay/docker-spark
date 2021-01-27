#!/usr/bin/env bash

if [ "$SPARK_MODE" == "worker" ]; then
    echo "Will start Spark in worker mode"
    $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker "$SPARK_MASTER_URI"
else
    echo "Will start Spark in master mode"
    $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master
fi

