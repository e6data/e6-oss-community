#!/usr/bin/env bash
set -euo pipefail

# Versions – change if you like
HIVE_VERSION="3.1.3"
HADOOP_VERSION="3.3.1"
MARIADB_JDBC_VERSION="3.3.3"

HIVE_TGZ="hive-standalone-metastore-${HIVE_VERSION}-bin.tar.gz"
HADOOP_TGZ="hadoop-${HADOOP_VERSION}.tar.gz"
MARIADB_JAR="mariadb-java-client-${MARIADB_JDBC_VERSION}.jar"

# Where we install things
METASTORE_HOME="/usr/local/bin/metastore"
HADOOP_HOME="/usr/local/bin/hadoop"
ENV_FILE="/etc/default/hive-metastore-env"

SERVICE_USER="$(whoami)"   # user under which metastore will run

echo "==> Installing packages (MariaDB, Java, wget, tar)..."
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server openjdk-8-jdk wget tar

echo "==> Enabling and starting MariaDB..."
sudo systemctl enable --now mariadb

echo "==> Creating Hive metastore database and user in MariaDB..."
sudo mariadb <<'EOF'
DROP DATABASE IF EXISTS metastore;
CREATE DATABASE metastore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS 'hive'@'localhost';
CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost';

FLUSH PRIVILEGES;
EOF

echo "==> Downloading Hive standalone metastore ${HIVE_VERSION}..."
wget -q "https://repo1.maven.org/maven2/org/apache/hive/hive-standalone-metastore/${HIVE_VERSION}/${HIVE_TGZ}"
tar -zxf "${HIVE_TGZ}"
rm "${HIVE_TGZ}"

# Extracted folder name is typically apache-hive-metastore-<ver>-bin
METASTORE_EXTRACT_DIR="apache-hive-metastore-${HIVE_VERSION}-bin"
sudo rm -rf "${METASTORE_HOME}"
sudo mv "${METASTORE_EXTRACT_DIR}" "${METASTORE_HOME}"
sudo chown -R "${SERVICE_USER}:${SERVICE_USER}" "${METASTORE_HOME}"

echo "==> Downloading Hadoop ${HADOOP_VERSION}..."
wget -q "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TGZ}"
tar -zxf "${HADOOP_TGZ}"
rm "${HADOOP_TGZ}"

sudo rm -rf "${HADOOP_HOME}"
sudo mv "hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}"
sudo chown -R "${SERVICE_USER}:${SERVICE_USER}" "${HADOOP_HOME}"

echo "==> Fixing Guava and adding AWS JARs for S3 compatibility..."
# Remove old Guava from metastore and replace with the one from Hadoop
rm -f "${METASTORE_HOME}/lib/guava-19.0.jar" || true
cp "${HADOOP_HOME}/share/hadoop/common/lib/guava-27.0-jre.jar" \
   "${METASTORE_HOME}/lib/"

# Copy Hadoop AWS + AWS SDK bundle into metastore lib
cp "${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-${HADOOP_VERSION}.jar" \
   "${METASTORE_HOME}/lib/" || true
cp "${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-"*.jar \
   "${METASTORE_HOME}/lib/" || true

echo "==> Downloading MariaDB JDBC driver ${MARIADB_JDBC_VERSION}..."
wget -q "https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/${MARIADB_JDBC_VERSION}/${MARIADB_JAR}"
sudo mv "${MARIADB_JAR}" "${METASTORE_HOME}/lib/"

echo "==> (Optional) Downloading GCS connector for Hadoop 3..."
wget -q "https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar"
sudo cp gcs-connector-hadoop3-latest.jar "${METASTORE_HOME}/lib/"
sudo mv gcs-connector-hadoop3-latest.jar "${HADOOP_HOME}/lib/"

echo "==> Detecting JAVA_HOME..."
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME="$(dirname "$(dirname "${JAVA_BIN}")")"
echo "Detected JAVA_HOME=${JAVA_HOME}"

echo "==> Writing environment file for systemd: ${ENV_FILE}"
sudo bash -c "cat > '${ENV_FILE}'" <<EOF
HADOOP_HOME=${HADOOP_HOME}
JAVA_HOME=${JAVA_HOME}
EOF

echo "==> Writing metastore-site.xml..."
sudo mkdir -p "${METASTORE_HOME}/conf"

sudo bash -c "cat > '${METASTORE_HOME}/conf/metastore-site.xml'" <<'EOF'
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

  <!-- Use MariaDB as backend via JDBC -->
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mariadb://localhost:3306/metastore</value>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.mariadb.jdbc.Driver</value>
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

sudo chown -R "${SERVICE_USER}:${SERVICE_USER}" "${METASTORE_HOME}"

echo "==> Initializing Hive metastore schema..."
export HADOOP_HOME="${HADOOP_HOME}"
export JAVA_HOME="${JAVA_HOME}"

# Run schematool from the metastore install
"${METASTORE_HOME}/bin/schematool" -initSchema -dbType mysql

echo "==> Creating systemd service for Hive metastore..."
SERVICE_FILE="/etc/systemd/system/metastore.service"
sudo bash -c "cat > '${SERVICE_FILE}'" <<EOF
[Unit]
Description=Hive Standalone Metastore Service
After=network.target mariadb.service
Wants=mariadb.service

[Service]
User=${SERVICE_USER}
WorkingDirectory=${METASTORE_HOME}
EnvironmentFile=${ENV_FILE}
ExecStart=${METASTORE_HOME}/bin/start-metastore
Restart=always
RestartSec=5
Type=simple

[Install]
WantedBy=multi-user.target
EOF

echo "==> Reloading systemd and starting metastore..."
sudo systemctl daemon-reload
sudo systemctl enable metastore
sudo systemctl start metastore

echo "==> Done."
echo "Metastore should now be listening on thrift://localhost:9083 using MariaDB as backend."
