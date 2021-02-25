FROM openjdk:8u282-jdk-buster
LABEL maintainer="Doğukan Çağatay <dcagatay@gmail.com>"

ARG HADOOP_VERSION_ARG="3.3.0"
ARG SPARK_VERSION_ARG="3.0.2"
ARG SPARK_PACKAGE_SPEC

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

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  unzip \
  gnupg \
  python3-pip \
  && pip3 install -U pip py4j \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# Hadoop
ENV HADOOP_VERSION ${HADOOP_VERSION_ARG}
ENV HADOOP_URL "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV PATH ${HADOOP_HOME}/bin/:${PATH}

RUN set -x \
  && curl -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS \
  && gpg --import KEYS \
  && curl -fSL --retry 3 "${HADOOP_URL}" -o /tmp/hadoop.tar.gz \
  && curl -fSL --retry 3 "${HADOOP_URL}.asc" -o /tmp/hadoop.tar.gz.asc \
  && gpg --verify /tmp/hadoop.tar.gz.asc \
  && tar -xf /tmp/hadoop.tar.gz -C /opt/ \
  && rm /tmp/hadoop.tar.gz* \
  && ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
  && rm -rf ${HADOOP_HOME}/share/doc \
  && chown -R root:root ${HADOOP_HOME}

# Spark
ENV SPARK_VERSION ${SPARK_VERSION_ARG}
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop${SPARK_PACKAGE_SPEC}
ENV SPARK_URL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz"
ENV SPARK_HOME /opt/spark
ENV SPARK_CONF_DIR /conf
ENV SPARK_MASTER_PORT 7077
ENV SPARK_WORKER_PORT 8881
ENV SPARK_WORKER_WEBUI_PORT 8081
ENV SPARK_MASTER_URI spark://master:7077
ENV SPARK_DIST_CLASSPATH "${HADOOP_HOME}/etc/hadoop/*:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/yarn/lib/*:${HADOOP_HOME}/share/hadoop/yarn/*:${HADOOP_HOME}/share/hadoop/mapreduce/lib/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:${HADOOP_HOME}/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin

RUN set -x \
  && curl -O https://archive.apache.org/dist/spark/KEYS \
  && gpg --import KEYS \
  && curl -fSL --retry 3 "${SPARK_URL}" -o /tmp/spark.tar.gz \
  && curl -fSL --retry 3 "${SPARK_URL}.asc" -o /tmp/spark.tar.gz.asc \
  && gpg --verify /tmp/spark.tar.gz.asc \
  && tar -xf /tmp/spark.tar.gz -C /opt/ \
  && rm /tmp/spark.tar.gz* \
  && mv /opt/${SPARK_PACKAGE} /opt/spark-${SPARK_VERSION} \
  && ln -s /opt/spark-${SPARK_VERSION} ${SPARK_HOME} \
  && chown -R root:root ${SPARK_HOME}

COPY docker-entrypoint.sh run.sh /
COPY conf/master/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf.master
COPY conf/worker/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf.worker

RUN chmod +x /docker-entrypoint.sh /run.sh

WORKDIR ${SPARK_HOME}
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run.sh"]
