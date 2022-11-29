#!/bin/bash
sudo yum update -y
sudo yum install -y mariadb-server java-1.8.0-openjdk wget
sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo bash -c "cat << EOF | sudo tee -a my.sql
UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
DROP DATABASE IF EXISTS metastore;
CREATE DATABASE metastore;
CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON *.* TO 'hive'@'localhost';
FLUSH PRIVILEGES;
EOF"

mysql -uroot < my.sql;

wget https://repo1.maven.org/maven2/org/apache/hive/hive-standalone-metastore/3.1.3/hive-standalone-metastore-3.1.3-bin.tar.gz;
tar -zxvf hive-standalone-metastore-3.1.3-bin.tar.gz;
rm hive-standalone-metastore-3.1.3-bin.tar.gz;
sudo mv apache-hive-metastore-3.1.3-bin/ /usr/local/bin/metastore;
sudo chown -R $(id -u -n):$(id -u -n) /usr/local/bin/metastore;

wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz;
tar -zxvf hadoop-3.3.1.tar.gz;
sudo mv hadoop-3.3.1/  /usr/local/bin/hadoop;
sudo chown -R $(id -u -n):$(id -u -n) /usr/local/bin/hadoop;
rm hadoop-3.3.1.tar.gz;

rm /usr/local/bin/metastore/lib/guava-19.0.jar;
cp /usr/local/bin/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar \
  /usr/local/bin/metastore/lib/;
cp /usr/local/bin/hadoop/share/hadoop/tools/lib/hadoop-aws-3.3.1.jar \
  /usr/local/bin/metastore/lib/;
cp /usr/local/bin/hadoop/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.901.jar \
  /usr/local/bin/metastore/lib/;

wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.28/mysql-connector-java-5.1.28.jar;
wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar;
sudo cp gcs-connector-hadoop3-latest.jar /usr/local/bin/metastore/lib/;
sudo mv gcs-connector-hadoop3-latest.jar /usr/local/bin/hadoop/lib/;

# move the jar to metastore lib
sudo mv mysql-connector-java-5.1.28.jar /usr/local/bin/metastore/lib/;

echo "export HADOOP_HOME=/usr/local/bin/hadoop" >> ~/.bashrc;
#javadir=$(ls -l /usr/lib/jvm/ | grep "^d" | cut -d" " -f10);
echo "export JAVA_HOME=/usr/lib/jvm/${javadir}/jre" >> ~/.bashrc;
echo 'HADOOP_HOME=/usr/local/bin/hadoop' | sudo tee -a /usr/lib/systemd/system/common.env;
echo 'JAVA_HOME=/usr/lib/jvm//jre' | sudo tee -a /usr/lib/systemd/system/common.env;
source ~/.bashrc;
export HADOOP_HOME=/usr/local/bin/hadoop
export JAVA_HOME=/usr/lib/jvm//jre
cat << EOF > /usr/local/bin/metastore/conf/metastore-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
      <property>
        <name>metastore.thrift.uris</name>
        <value>thrift://localhost:9083</value>
        <description>Thrift URI for the remote metastore. Used by metastore client to connect to remote metastore.</description>
      </property>
      <property>
        <name>metastore.task.threads.always</name>
        <value>org.apache.hadoop.hive.metastore.events.EventCleanerTask</value>
      </property>
      <property>
        <name>metastore.expression.proxy</name>
        <value>org.apache.hadoop.hive.metastore.DefaultPartitionExpressionProxy</value>
      </property>
      <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost/metastore?createDatabaseIfNotExist=true</value>
      </property>
      <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
      </property>
      <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
      </property>
      <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
      </property>
      <property>
        <name>hive.metastore.event.db.notification.api.auth</name>
        <value>false</value>
      </property>
      <property>
        <name>hive.stats.autogather</name>
        <value>true</value>
      </property>
</configuration>
EOF

/usr/local/bin/metastore/bin/schematool -initSchema -dbType mysql;

sudo bash -c 'cat << EOF > /usr/lib/systemd/system/metastore.service
[Unit]
Description=Manage Hive Metastore service

[Service]
User=ec2-user
# WorkingDirectory=/home/ec2-user
ExecStart=/usr/local/bin/metastore/bin/start-metastore
ExecStop=/bin/kill -15 $MAINPID
EnvironmentFile=/usr/lib/systemd/system/common.env
TimeoutSec=30

Type=simple
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target'

sudo systemctl enable metastore
sudo systemctl start metastore
