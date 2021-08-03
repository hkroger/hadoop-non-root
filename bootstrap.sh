#!/bin/bash

: ${HADOOP_HOME:=/usr/local/hadoop}

#create a non-root user in container which shares the same id as the local user
USER_ID=${LOCAL_USER_ID:-1000}
USER=${LOCAL_USER_NAME:-user}
echo "Starting with UID : $USER_ID"
echo "Starting with USER: $USER"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m $USER
usermod -a -G hadoop $USER
usermod -g hadoop $USER
export HOME=/home/$USER

# ssh settings for user
/usr/local/bin/gosu $USER rm -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu $USER ssh-keygen -q -N "" -t rsa -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu $USER cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat /root/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat $HOME/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cat /root/.ssh/config > $HOME/.ssh/config
chown $USER:hadoop $HOME/.ssh/config
chmod 600 $HOME/.ssh/config

echo "AllowUsers $USER root" >> /etc/ssh/sshd_config

# create directories for name node and data node
mkdir /hadoopApp/
mkdir /hadoopApp/tmp
mkdir /hadoopApp/data
mkdir /hadoopApp/name
chown -R $USER:hadoop /hadoopApp/
chmod -R 775 /hadoopApp/

# replace the hard-coded hostname in the conf files with container host name
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_HOME/etc/hadoop/core-site.xml

# env variables for non-root user
/usr/local/bin/gosu $USER echo "PATH=$PATH:$JAVA_HOME/bin\nPATH=$PATH:/usr/local/hadoop/bin\nHADOOP_HOME=/usr/local/hadoop\nHADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop" >> $HOME/.bashrc

# format the name node before starting hadoop service
/usr/local/bin/gosu $USER $HADOOP_HOME/bin/hdfs namenode -format

# start sshd, hadoop and yarn service
service ssh start
source $HADOOP_HOME/etc/hadoop/hadoop-env.sh

/usr/local/bin/gosu $USER ssh-copy-id -i $HOME/.ssh/id_rsa.pub $USER@$HOSTNAME
/usr/local/bin/gosu $USER $HADOOP_HOME/sbin/start-dfs.sh
/usr/local/bin/gosu $USER $HADOOP_HOME/sbin/start-yarn.sh

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

