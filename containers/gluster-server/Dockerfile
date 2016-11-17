FROM ubuntu:xenial

# Install GlusterFS
RUN apt-get update -y
RUN apt-get install -y \
  glusterfs-server \
  attr

# Install entrypoint
ADD bin/entrypoint.sh /user/bin

ENTRYPOINT ["entrypoint.sh"]
