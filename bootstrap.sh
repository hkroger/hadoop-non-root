#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}
USER_ID=${LOCAL_USER_ID:-1000}
echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
usermod -a -G hadoop user
usermod -g hadoop user
export HOME=/home/user

/usr/local/bin/gosu user rm -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu user ssh-keygen -q -N "" -t rsa -f $HOME/.ssh/id_rsa
/usr/local/bin/gosu user cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat /root/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
cat $HOME/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cat /root/.ssh/config > $HOME/.ssh/config
chown user:hadoop $HOME/.ssh/config
chmod 600 $HOME/.ssh/config

#chown user /usr/local/hadoop/logs

mkdir /hadoopApp/
mkdir /hadoopApp/tmp
mkdir /hadoopApp/data
mkdir /hadoopApp/name
chown -R user:hadoop /hadoopApp/
chmod -R 775 /hadoopApp/

/usr/local/bin/gosu user echo "PATH=$PATH:$JAVA_HOME/bin\nPATH=$PATH:/usr/local/hadoop/bin\nHADOOP_PREFIX=/usr/local/hadoop\nHADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop" >> $HOME/.bashrc
/usr/local/bin/gosu user $HADOOP_PREFIX/bin/hdfs namenode -format

service ssh start
/usr/local/bin/gosu user ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@sandbox
/usr/local/bin/gosu user $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-dfs.sh
/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-yarn.sh

CMD=${1:-"exit 0"}
if [[ "$CMD" == "-d" ]];
then
	service ssh stop
	/usr/sbin/ssh -D -d
else
	/bin/bash -c "$*"
fi
