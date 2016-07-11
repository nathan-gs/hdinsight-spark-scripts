#! /bin/bash

INSTALL_DIR=/usr/hdp/current/incubator-zeppelin

ZEPPELIN_VERSION=0.5.6
ZEPPELIN_BINARIES_LINK=https://archive.apache.org/dist/incubator/zeppelin/${ZEPPELIN_VERSION}-incubating/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all.tgz
ZEPPELIN_KEYS_LINK=https://www.apache.org/dist/incubator/zeppelin/KEYS
ZEPPELIN_ASC_LINK=https://archive.apache.org/dist/incubator/zeppelin/${ZEPPELIN_VERSION}-incubating/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all.tgz.asc

ZEPPELIN_SETUP_DIR=/tmp/zeppelinsetup
ZEPPELIN_KEYS_FILE=$ZEPPELIN_SETUP_DIR/KEYS
ZEPPELIN_ASC_FILE=$ZEPPELIN_SETUP_DIR/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all.tgz.asc
ZEPPELIN_DOWNLOADED_TGZ=$ZEPPELIN_SETUP_DIR/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all.tgz

installZeppelind() {
echo "Adding Zeppelin's Init.d configuration"

cat >/etc/init.d/zeppelind <<EOL
test -e $INSTALL_DIR/bin/zeppelin-daemon.sh || exit 1
sudo $INSTALL_DIR/bin/zeppelin-daemon.sh \$@
EOL

chmod +x /etc/init.d/zeppelind
update-rc.d zeppelind defaults
update-rc.d zeppelind enable
}

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

fullHostName=$(hostname -f)
echo "fullHostName=$fullHostName"
if [[ $fullHostName != headnode0* && $fullHostName != hn0* ]]; then
    echo "$fullHostName is not headnode 0. This script has to be run on headnode 0."
    exit 0
fi

# In case Zeppelin is installed, exit.
if [ -e $INSTALL_DIR ]; then
    echo "Zeppelin is already installed, exiting ..."
    exit 0
fi

echo "Downloading Zeppelin binaries"
rm -rf $ZEPPELIN_SETUP_DIR
mkdir $ZEPPELIN_SETUP_DIR
echo download_file $ZEPPELIN_BINARIES_LINK $ZEPPELIN_DOWNLOADED_TGZ
download_file $ZEPPELIN_BINARIES_LINK $ZEPPELIN_DOWNLOADED_TGZ

if [ ! -f $ZEPPELIN_DOWNLOADED_TGZ ]; then
    echo "Failed to download Zeppelin binaries. Exiting..."
    exit 1
fi

echo "Verifying the integrity of downloaded file"

echo download_file $ZEPPELIN_KEYS_LINK $ZEPPELIN_KEYS_FILE
download_file $ZEPPELIN_KEYS_LINK $ZEPPELIN_KEYS_FILE

if [ ! -f $ZEPPELIN_KEYS_FILE ]; then
    echo "Failed to download Zeppelin PGP Keys for validating downloaded binaries. Exiting..."
    exit 1
fi

echo download_file $ZEPPELIN_ASC_LINK $ZEPPELIN_ASC_FILE
download_file $ZEPPELIN_ASC_LINK $ZEPPELIN_ASC_FILE

if [ ! -f $ZEPPELIN_ASC_FILE ]; then
    echo "Failed to download Zeppelin asc signature for validating downloaded binaries. Exiting..."
    exit 1
fi

gpg --import $ZEPPELIN_KEYS_FILE
gpg --verify $ZEPPELIN_ASC_FILE $ZEPPELIN_DOWNLOADED_TGZ

if [ $? -ne 0 ]; then
    echo "Failed to verify integrity of downloaded binaries. Exiting...!"
    exit 1
fi

echo untar_file $ZEPPELIN_DOWNLOADED_TGZ /usr/hdp/current
untar_file $ZEPPELIN_DOWNLOADED_TGZ /usr/hdp/current

echo mv /usr/hdp/current/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all $INSTALL_DIR
mv /usr/hdp/current/zeppelin-${ZEPPELIN_VERSION}-incubating-bin-all $INSTALL_DIR

# remove the temporary file
rm -f $ZEPPELIN_DOWNLOADED_TGZ

if ls $INSTALL_DIR/interpreter/spark/dep/zeppelin-spark-*.jar 
then
    export LOCAL_SPARK_JAR=$INSTALL_DIR/interpreter/spark/dep/zeppelin-spark-*.jar
else
    export LOCAL_SPARK_JAR=$INSTALL_DIR/interpreter/spark/zeppelin-spark-*.jar
fi
echo "LOCAL_SPARK_JAR is $LOCAL_SPARK_JAR"

SPARK_JAR_DIR=wasb:///apps/zeppelin/
SPARK_JAR=$SPARK_JAR_DIR/zeppelin-spark.jar
hadoop fs -mkdir -p $SPARK_JAR_DIR
hadoop fs -put -f -p $LOCAL_SPARK_JAR $SPARK_JAR

download_file https://raw.githubusercontent.com/nathan-gs/hdinsight-spark-scripts/master/spark-1.6/zeppelin-${ZEPPELIN_VERSION}/zeppelin-env.sh $INSTALL_DIR/conf/zeppelin-env.sh
download_file https://raw.githubusercontent.com/nathan-gs/hdinsight-spark-scripts/master/spark-1.6/zeppelin-${ZEPPELIN_VERSION}/zeppelin-site.xml $INSTALL_DIR/conf/zeppelin-site.xml

installZeppelind
service zeppelind start
echo "Installation succeeded"
