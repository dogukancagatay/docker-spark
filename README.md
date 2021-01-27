# Apache Spark

A `debian:stretch` based [Spark](http://spark.apache.org) container. Use it in a standalone cluster with the accompanying `docker-compose.yml`, or as a base for more complex recipes.

## Labels

- `latest`, `dcagatay/docker-spark:2.4.7-hadoop3.2.2`

## Highlights

- Highly available standalone cluster compatible (Multiple masters, with zookeeper)
- Highly configurable, configuration files are exposed
- Extendable configuration, you can extend to have a Spark container for your application
- Customizable versions, you can customize Hadoop and Spark versions inside Dockerfile according to your needs and rebuild your image
- Multi server setup is possible

## Running

`docker-compose.yml` provides a single-master spark cluster, you can start the cluster via `docker-compose up -d`.

You can find the highly available version at `docker-compose-ha.yml`.

### Configuration

Traditional Spark configuration is possible, you can configure according to Spark configuration documentation.

In order to configure via `$SPARK_HOME/conf` directory, you should map `/conf` directory of container to a local one, and put your configuration inside that directory for master and worker separately. Note that, if the mapped directory is empty, it is self populated with templates and current configuration for convenience.

There are a couple of configuration extensions for increasing usability via environment variables.

- `SPARK_MODE`: (Required for worker) Running mode for the spark instance. Required for worker. ([`worker`, `master`], Default: `master`)
- `SPARK_MASTER_URI`: (Required for worker) Tells worker nodes where which master to connect on startup. (e.g. `spark://m1:7077,spark://m2:7077`)
- `ZK_HOSTS`: (Optional) For HA configuration, enables to set zookeeper hosts quickly.(e.g. `zk1:2181,zk2:2181,zk3:2181`)

You can access more configuration options from [here](https://spark.apache.org/docs/2.4.7/configuration.html) and [here](https://spark.apache.org/docs/2.4.7/spark-standalone.html)

## Examples

### SparkPi Example

After running single-master or highly available version you can run spark examples.

```bash
docker-compose exec m1 bin/run-example SparkPi 100
```

### PySpark Example

You can submit PySpark jobs via master.

```bash
docker-compose exec m1 bash -c 'echo -e "import pyspark\n\nprint(pyspark.SparkContext().parallelize(range(0, 10)).count())" > /tmp/count.py'
docker-compose exec m1 bin/spark-submit /tmp/count.py
```

### Submitting jobs from other machines

You need to consider following items if you want to run jobs from another machine.

- When using multiple workers, you need to run and expose different ports for driver. (or bind them to different IP addresses)
- You should set DNS settings on job-submitting machine according to your `docker-compose.yml`. (e.g. `/etc/hosts`)
- You should set `SPARK_PUBLIC_DNS` and `SPARK_LOCAL_HOSTNAME` environment variables according to your DNS settings.
- You cannot use IP address instead of DNS, since container IP adresses and exposed IP addresses are different.
- An example: `job-submit.sh`

## Build

You can build your custom images according to your Spark and Hadoop version requirements by just changing the `SPARK_VERSION` and `HADOOP_VERSION` environment variables and `docker build -t your-custom-spark .` command.

## License

MIT

Extended from [gettyimages/docker-spark](https://github.com/gettyimages/docker-spark.git)
