FROM debian:buster
LABEL maintainer "Dogukan Cagatay <dcagatay@gmail.com>"

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  openjdk-11-jre-headless \
  python3 \
  python3-pip \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && pip3 install -U pip py4j \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# HADOOP
ENV HADOOP_VERSION 3.2.2
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:${HADOOP_HOME}/bin

RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.4.7
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_CONF_DIR /conf
ENV SPARK_MASTER_PORT 7077
ENV SPARK_WORKER_PORT 8881
ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_MASTER_URI spark://master:7077
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin

RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

COPY docker-entrypoint.sh run.sh /
RUN chmod +x /docker-entrypoint.sh /run.sh

COPY conf/master/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf.master
COPY conf/worker/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf.worker

WORKDIR $SPARK_HOME
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run.sh"]
