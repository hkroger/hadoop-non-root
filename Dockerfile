FROM sequenceiq/hadoop-ubuntu:2.6.0

RUN groupadd hadoop
RUN usermod -a -G hadoop root
RUN chown -R root:hadoop $HADOOP_PREFIX
RUN chmod -R 777 $HADOOP_PREFIX 

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown -R root:hadoop /etc/bootstrap.sh
RUN chmod 755 /etc/bootstrap.sh

RUN service ssh start && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/sbin/start-yarn.sh && $HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && $HADOOP_PREFIX/bin/hadoop fs -chmod 777 /

ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

RUN echo "AuthorizedKeysFile	/root/.ssh/authorized_keys" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

CMD ["/etc/bootstrap.sh", "-d"]
