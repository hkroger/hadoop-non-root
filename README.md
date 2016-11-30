# hadoop-non-root
This a hadoop:2.6 image on which dfs and yarn service are run by a non-root user. It's based on [sequenceiq/hadoop-docker](https://github.com/sequenceiq/hadoop-docker).

You won't be annoyed by permission issues when you clean up the output files written by hadoop workers in a mount volume.

By default, the hadoop worker has the same system previllegs as the first non-root user in Ubuntu system, whose uid is 1000. You can set the previlleges of the hadoop worker to be the same as a specific user by specifying an environmental variable LOCAL_USER_ID when you start a container.

##Build the image
```bash
docker build -t wuyang1990/hadoop-non-root .
```

##Pull the image
```bash
docker pull wuyang1990/hadoop-non-root
```

##Start a container
```bash
docker run -it -e  LOCAL_USER_ID=1000 wuyang1990/hadoop-non-root bash
```
##Refrence
[hadoop docker image by sequenceig](https://github.com/sequenceiq/hadoop-docker)

[handling permissions with docker volumes](https://denibertovic.com/posts/handling-permissions-with-docker-volumes/)
