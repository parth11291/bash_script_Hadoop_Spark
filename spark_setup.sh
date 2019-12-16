#!/bin/bash

eval "$(cat credentials.txt)"

if [ "$(whoami)" != "$HDUSER" ]; then
        echo "Script must be run as user: $HDUSER"
        exit
fi

#-----Change directory to the directory of the script------------------------
cd "$(dirname "$0")"

mkdir -p binaries

if [ -e binaries/spark-*.tgz ]
then
	echo "OK"
else
	wget wget http://mirror.vorboss.net/apache/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz \
	-P binaries
fi

#------------------Extracting the tar file--------------------------------------
echo $PASS | sudo tar -xvzf binaries/spark-*.tgz -C /usr/local/
echo $PASS | sudo mv /usr/local/spark-*/ /usr/local/spark

#------------------Configuring bash ---------------------------------------
echo "" >> $HDUSER_HOME/.bashrc
echo "#Set SPARK_HOME" >> $HDUSER_HOME/.bashrc
echo "export SPARK_HOME=/usr/local/spark" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_CONF_DIR=\$HADOOP_INSTALL/etc/hadoop/" >> $HDUSER_HOME/.bashrc
echo "export LD_LIBRARY_PATH=\$HADOOP_INSTALL/lib/native/:$LD_LIBRARY_PATH" >> $HDUSER_HOME/.bashrc
echo "export PATH=\$PATH:\$SPARK_HOME/bin/" >> $HDUSER_HOME/.bashrc

#sourcing the bash file
eval "$(cat $HDUSER_HOME/.bashrc)"

#-----------------Configuring Spark -----------------------------------------
sudo chown -R $HDUSER:hadoop $SPARK_HOME
mv $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf