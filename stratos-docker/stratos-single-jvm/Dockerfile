FROM    ubuntu:14.04

RUN apt-get update
RUN apt-get upgrade tzdata -y
RUN apt-get install openjdk-7-jre-headless unzip -y

# TODO this will need to be variable driven
ADD /files/apache-stratos.zip apache-stratos.zip

RUN unzip -q apache-stratos.zip 
RUN rm apache-stratos.zip
RUN mv apache-stratos-* apache-stratos

ADD /files/stratos-installer/config/all/repository/conf/activemq/jndi.properties apache-stratos/repository/conf/


ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

CMD ["/usr/local/bin/run"]
