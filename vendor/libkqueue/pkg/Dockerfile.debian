FROM debian:sid
MAINTAINER mark@heily.com
RUN apt-get update && apt-get install -y build-essential
RUN apt-get install -y cmake debhelper
ARG project_version
RUN mkdir -p /tmp/libkqueue-${project_version}
COPY . /tmp/libkqueue-${project_version}
WORKDIR /tmp
RUN tar zcf libkqueue_${project_version}.orig.tar.gz libkqueue-${project_version}
COPY pkg/debian/ /tmp/libkqueue-${project_version}/debian/
WORKDIR /tmp/libkqueue-${project_version}
RUN rm -f CMakeCache.txt

