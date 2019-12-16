#!/bin/bash
eval "$(cat credentials.txt)"

if [ "$(whoami)" != "$HDUSER" ]; then
        echo "Script must be run as user: $HDUSER"
        exit
fi

#-----Change directory to the directory of the script------------------------
cd "$(dirname "$0")"

#-------------------Downloading the hadoop binaries-------------------------------
mkdir -p binaries

if [ -e binaries/hadoop-2.9.2.tar.gz ]
then
	echo "OK"
else
	 wget https://archive.apache.org/dist/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz \
	-P binaries
fi

#---------------------Setting up SSH Certificate--------------------------------------
echo -e "\n\n\n" | ssh-keygen -t rsa -P ''
cat $HDUSER_HOME/.ssh/id_rsa.pub >> $HDUSER_HOME/.ssh/authorized_keys

#--------------------Extracting the tar file-----------------------------------------
echo -e "$PASS" | sudo tar -xvzf binaries/hadoop-2.9.2.tar.gz -C /usr/local/
echo -e "$PASS" | sudo mv /usr/local/hadoop-2.9.2 /usr/local/hadoop
echo -e "$PASS" | sudo chown -R $HDUSER:hadoop /usr/local/hadoop

#--------------------Setting up bash file---------------------------------------------
echo "" >> $HDUSER_HOME/.bashrc
echo "#Hadoop variables" >> $HDUSER_HOME/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/jdk1.8" >> $HDUSER_HOME/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_INSTALL=/usr/local/hadoop" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_HOME=\$HADOOP_INSTALL" >> $HDUSER_HOME/.bashrc
echo "export PATH=\$PATH:\$HADOOP_INSTALL/bin" >> $HDUSER_HOME/.bashrc
echo "export PATH=\$PATH:\$HADOOP_INSTALL/sbin" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_COMMON_HOME=\$HADOOP_INSTALL" >> $HDUSER_HOME/.bashrc
echo "export HADOOP_HDFS_HOME=\$HADOOP_INSTALL" >> $HDUSER_HOME/.bashrc
echo "export YARN_HOME=\$HADOOP_INSTALL" >> $HDUSER_HOME/.bashrc

#sourcing the bash file
eval "$(cat $HDUSER_HOME/.bashrc)"

# Checking hadoop version
hadoop version

#------------------------- configuring hadoop--------------------------------------------
mkdir -p $HDUSER_HOME/mydata/hdfs/namenode
mkdir -p $HDUSER_HOME/mydata/hdfs/datanode
rm $HADOOP_INSTALL/etc/hadoop/mapred-site.xml.template
cp configs/* $HADOOP_INSTALL/etc/hadoop/
sed -i "s|HDUSER_HOME|$HDUSER_HOME|g" $HADOOP_INSTALL/etc/hadoop/hdfs-site.xml
sed -i "s|\${JAVA_HOME}|$JAVA_HOME|g" $HADOOP_INSTALL/etc/hadoop/hadoop-env.sh

#-------------------------Starting hdfs---------------------------------------------------
hdfs namenode -format
echo -e "yes" | start-dfs.sh
echo -e "yes" | start-yarn.sh

#--------------------------Checking the hadoop--------------------------------------------
jps

#--------------------------Running map reduce job------------------------------------------
# Installing mrjob
echo -e "$PASS" | sudo pip install mrjob

# Downloading hadoop streaming jar
if [ -e binaries/hadoop-streaming-2.9.2.jar ]
then
	echo "OK"
else
	wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-streaming/2.9.2/hadoop-streaming-2.9.2.jar \
	-P binaries
fi

cp binaries/hadoop-streaming-2.9.2.jar $HADOOP_INSTALL/hadoop-streaming.jar

python MapReduce/best_ratings.py -r hadoop --hadoop-streaming-jar $HADOOP_INSTALL/hadoop-streaming.jar ml-100k/u.data

# Copying ml-100k data to hdfs
hadoop fs -copyFromLocal ml-100k .

