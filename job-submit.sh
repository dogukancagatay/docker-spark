#!/usr/bin/env bash

echo -e "import pyspark\n\nprint(pyspark.SparkContext().parallelize(range(0, 10)).count())" > count.py

docker run --rm -it \
    --hostname athena.home.local \
    -p 4040:4040 \
    -p 7001:7001 \
    -p 7002:7002 \
    -p 7003:7003 \
    -p 7004:7004 \
    -p 7005:7005 \
    --add-host="m1:192.168.1.69" \
    --add-host="m2:192.168.1.69" \
    --add-host="w1:192.168.1.69" \
    --add-host="w2:192.168.1.69" \
    -v "$(pwd)/job/count.py:/count.py" \
    dcagatay/docker-spark:2.4.7-hadoop3.2.2 \
    bin/spark-submit --master spark://m1:7077 /count.py

rm -rf count.py