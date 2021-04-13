# hadoop-non-root
This a hadoop:2.10.1 image on which dfs and yarn service are run by a non-root user. It's a bastard child of [sequenceiq/hadoop-docker](https://github.com/sequenceiq/hadoop-docker) and [WuyangLI/hadoop-non-root](https://github.com/WuyangLI/hadoop-non-root).

You won't be annoyed by permission issues when you clean up the output files written by hadoop workers in a mount volume.

By default, the hadoop worker has the same system previllegs as the first non-root user in Ubuntu system, whose uid is 1000. You can set the previlleges of the hadoop worker to be the same as a specific user by specifying an environmental variable `LOCAL_USER_ID` when you start a container.

## Build the image
```bash
docker build -t hkroger/hadoop-non-root .
```

## Pull the image
```bash
docker pull hkroger/hadoop-non-root
```

## Start a container

Simple:

```bash
docker run -it -e LOCAL_USER_ID=1000 hkroger/hadoop-non-root -bash
```

All ports published:

```bash
docker run -it -e LOCAL_USER_ID=1000 -p 9000:9000 -p 50010:50010 -p 50020:50020 -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 8020:8020 hkroger/hadoop-non-root -bash
```

## Reference
* [hadoop docker image by WuyangLI](https://github.com/WuyangLI/hadoop-non-root)
* [hadoop docker image by sequenceig](https://github.com/sequenceiq/hadoop-docker)
* [handling permissions with docker volumes](https://denibertovic.com/posts/handling-permissions-with-docker-volumes/)
