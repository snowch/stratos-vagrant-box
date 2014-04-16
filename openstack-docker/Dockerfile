# stratosbase
# VERSION 0.0.1
FROM ubuntu64base
MAINTAINER Damitha Kumarage "damitha23@gmail.com"
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

RUN apt-get install -y openssh-server
RUN echo 'root:g' |chpasswd

RUN apt-get install -q -y zip
RUN apt-get install -q -y unzip
RUN apt-get install -q -y curl

ADD metadata_svc_bugfix.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/metadata_svc_bugfix.sh
ADD file_edit_patch.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/file_edit_patch.sh
ADD run_scripts.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run_scripts.sh
ENV LD_LIBRARY_PATH /root/lib
EXPOSE 22
ENTRYPOINT /usr/local/bin/run_scripts.sh | /usr/sbin/sshd -D
