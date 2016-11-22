#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration

USER_ID=${LOCAL_USER_ID:-9001}
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

mkdir /tmp/hadoop
mkdir /tmp/hadoop/tmp
mkdir /tmp/hadoop/data
mkdir /tmp/hadoop/name
chmod -R 777 /tmp/hadoop/

/usr/local/bin/gosu user $HADOOP_PREFIX/bin/hdfs namenode -format

/usr/local/bin/gosu user ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@sandbox

#service ssh start
#/usr/local/bin/gosu user $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-dfs.sh
#/usr/local/bin/gosu user $HADOOP_PREFIX/sbin/start-yarn.sh

CMD=${1:-"exit 0"}
if [[ "$CMD" == "-d" ]];
then
	service ssh stop
	/usr/sbin/ssh -D -d
else
	/bin/bash -c "$*"
fi
