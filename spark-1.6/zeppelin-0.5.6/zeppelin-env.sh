# Spark master url. eg. spark://master_addr:7077. Leave empty if you want to use local mode
export MASTER=yarn-client
export SPARK_YARN_JAR=wasb:///apps/zeppelin/zeppelin-spark.jar
export SPARK_HOME=/usr/hdp/current/spark-client/

# Where log files are stored.  PWD by default.
export ZEPPELIN_LOG_DIR=/var/log/zeppelin

# The pid files are stored. /tmp by default.
export ZEPPELIN_PID_DIR=/var/run/zeppelin-notebook

# Options read in YARN client mode
# yarn-site.xml is located in configuration directory in HADOOP_CONF_DIR.
export HADOOP_CONF_DIR=/etc/hadoop/conf

# Additional jvm options. for example, export ZEPPELIN_JAVA_OPTS="-Dspark.executor.memory=8g -Dspark.cores.max=16"

HDP_VER=`hdp-select status hadoop-client | sed 's/hadoop-client - \(.*\)/\1/'`
export ZEPPELIN_JAVA_OPTS="-Dhdp.version=$HDP_VER -Dspark.executor.memory=2g -Dspark.yarn.queue=default"

# Pyspark (supported with Spark 1.2.1 and above)
# To configure pyspark, you need to set spark distribution's path to 'spark.home' property in Interpreter setting screen in Zeppelin GUI
# path to the python command. must be the same path on the driver(Zeppelin) and all workers.
# export PYSPARK_PYTHON
# export PYTHONPATH
export PYTHONPATH=${SPARK_HOME}/python

# Zeppelin jvm mem options Default -Xmx1024m -XX:MaxPermSize=512m
# export ZEPPELIN_MEM

# zeppelin interpreter process jvm mem options. Defualt = ZEPPELIN_MEM
# export ZEPPELIN_INTP_MEM

# zeppelin interpreter process jvm options. Default = ZEPPELIN_JAVA_OPTS
# export ZEPPELIN_INTP_JAVA_OPTS

# Where notebook saved
# export ZEPPELIN_NOTEBOOK_DIR

# A string representing this instance of zeppelin. $USER by default
# export ZEPPELIN_IDENT_STRING

# The scheduling priority for daemons. Defaults to 0.
# export ZEPPELIN_NICENESS
