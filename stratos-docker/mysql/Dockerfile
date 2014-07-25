FROM stackbrew/ubuntu:12.04
MAINTAINER Chris Snow <chsnow@apache.org>

RUN apt-get update -qq && apt-get install -y mysql-server-5.5

ADD my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 664 /etc/mysql/conf.d/my.cnf
ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

ADD files/mysql.sql /etc/mysql/conf.d/stratos.sql
RUN chmod 664 /etc/mysql/conf.d/stratos.sql

VOLUME ["/var/lib/mysql"]
EXPOSE 3306
CMD ["/usr/local/bin/run"]
