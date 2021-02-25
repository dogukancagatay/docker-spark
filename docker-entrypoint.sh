#!/usr/bin/env bash

# Add Zookeeper hosts configuration
if [ ! -z ${ZK_HOSTS+x} ]; then
    echo "Setting Zookeeper hosts: $ZK_HOSTS"
    export SPARK_DAEMON_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=$ZK_HOSTS"
fi

# Populate SPARK_DIST_CLASSPATH
export SPARK_DIST_CLASSPATH="$(hadoop classpath)"

# Populate configuration folder with templates
mkdir -p $SPARK_CONF_DIR
cp ${SPARK_HOME}/conf/*.template $SPARK_CONF_DIR/

# Add working configuration
if [ "$SPARK_MODE" == "worker" ]; then
    if [ ! -e $SPARK_CONF_DIR/spark-defaults.conf ]; then
        echo "Add default worker configuration"
        mv $SPARK_HOME/conf/spark-defaults.conf.worker $SPARK_CONF_DIR/spark-defaults.conf
    fi

else
    if [ ! -e $SPARK_CONF_DIR/spark-defaults.conf ]; then
        echo "Add default master configuration"
        mv $SPARK_HOME/conf/spark-defaults.conf.master $SPARK_CONF_DIR/spark-defaults.conf
    fi

fi

exec "$@"