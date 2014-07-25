#!/bin/bash

### copy stratos.mysql

# mysql container uses--init-file option which does not like comments 
# and likes each command on its own line

cp -f /home/vagrant/stratos-source/tools/stratos-installer/resources/mysql.sql files/mysql.tmp.0

# strip singleline comments
grep -v '^--.*$' files/mysql.tmp.0 > files/mysql.tmp.1

# strip multiline comments
perl -0777 -pe 's{/\*.*?\*/}{}gs' files/mysql.tmp.1 > files/mysql.sql

# remove newlines
sed -i ':a;N;$!ba;s/\n/ /g' files/mysql.sql

# replace ; with ;\n
sed -i 's/;/;\n/g' files/mysql.sql

rm files/mysql.tmp.*

### build docker

sudo docker build -t=apachestratos/mysql .
#sudo docker push apachestratos/mysql
