FROM    ubuntu:14.04

RUN apt-get update
RUN apt-get upgrade tzdata -y
RUN apt-get install openjdk-7-jre-headless unzip wget -y

#################
# Unpack Stratos 
#################

ADD /files/apache-stratos.zip apache-stratos.zip
RUN unzip -q apache-stratos.zip 
RUN rm apache-stratos.zip
RUN mv apache-stratos-* apache-stratos

ADD /files/stratos-installer/config/all/repository/conf/activemq/jndi.properties apache-stratos/repository/conf/

####################
# Get ActiveMQ libs
####################

RUN wget http://archive.apache.org/dist/activemq/5.9.1/apache-activemq-5.9.1-bin.tar.gz
RUN mkdir tmp-activemq
RUN tar -C tmp-activemq -xzf apache-activemq-5.9.1-bin.tar.gz
RUN cp -f tmp-activemq/apache-activemq-5.9.1/lib/activemq-broker-5.9.1.jar apache-stratos/repository/components/lib/
RUN cp -f tmp-activemq/apache-activemq-5.9.1/lib/activemq-client-5.9.1.jar apache-stratos/repository/components/lib/
RUN cp -f tmp-activemq/apache-activemq-5.9.1/lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar apache-stratos/repository/components/lib/ 
RUN cp -f tmp-activemq/apache-activemq-5.9.1/lib/geronimo-jms_1.1_spec-1.1.1.jar apache-stratos/repository/components/lib/ 
RUN rm -rf tmp-activemq

###################
# Setup run script
###################

ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

CMD ["/usr/local/bin/run"]
