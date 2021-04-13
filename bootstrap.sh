#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

#create a non-root user in container which shares the same id as the local user
USER_ID=${LOCAL_USER_ID:-1000}
echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
usermod -a -G hadoop user
usermod -g hadoop user
export HOME=/home/user

# ssh settings for user
/usr/local/bin/gosu user rm -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu user ssh-keygen -q -N "" -t rsa -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu user cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat /root/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat $HOME/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cat /root/.ssh/config > $HOME/.ssh/config
chown user:hadoop $HOME/.ssh/config
chmod 600 $HOME/.ssh/config

# create directories for name node and data node
mkdir /hadoopApp/
mkdir /hadoopApp/tmp
mkdir /hadoopApp/data
mkdir /hadoopApp/name
chown -R user:hadoop /hadoopApp/
chmod -R 775 /hadoopApp/

# replace the hard-coded hostname in the conf files with container host name
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
sed -i "s|sandbox|$HOSTNAME|g" $HADOOP_PREFIX/etc/hadoop/core-site.xml

# env variables for non-root user
/usr/local/bin/gosu user echo "PATH=$PATH:$JAVA_HOME/bin\nPATH=$PATH:/usr/local/hadoop/bin\nHADOOP_PREFIX=/usr/local/hadoop\nHADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop" >> $HOME/.bashrc

# format the name node before starting hadoop service
/usr/local/bin/gosu user $HADOOP_PREFIX/bin/hdfs namenode -format

# start sshd, hadoop and yarn service
service ssh start
source $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

/usr/local/bin/gosu user ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@$HOSTNAME
/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-dfs.sh
/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-yarn.sh

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

