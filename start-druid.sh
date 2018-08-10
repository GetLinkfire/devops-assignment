#!/bin/bash
set -ex

# Abort if no server type is given
if [ "${1:0:1}" = '' ]; then
    echo "Aborting: No druid server type set!"
    exit 1
fi

nodeType=$1

MYSQL_CONNECT_URI="jdbc:mysql\:\/\/${MYSQL_HOST}\:${MYSQL_PORT}\/${MYSQL_DBNAME}"
ENVIRONMENT=$MYSQL_DBNAME

# configure zookeeper host
sed -ri 's/druid.zk.service.host.*/druid.zk.service.host='${ZOOKEEPER_HOST}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure mysql connection string
sed -ri 's/druid.metadata.storage.connector.connectURI.*/druid.metadata.storage.connector.connectURI='${MYSQL_CONNECT_URI}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure mysql username
sed -ri 's/druid.metadata.storage.connector.user.*/druid.metadata.storage.connector.user='${MYSQL_USERNAME}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure mysql password
sed -ri 's/druid.metadata.storage.connector.password.*/druid.metadata.storage.connector.password='${MYSQL_PASSWORD}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure druid cluster name in Kafka metrics emitter
sed -ri 's/druid.emitter.kafka.clusterName=.*/druid.emitter.kafka.clusterName='${ENVIRONMENT}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure Kafka servers, for metrics emmission
sed -ri 's/druid.emitter.kafka.bootstrap.servers=.*/druid.emitter.kafka.bootstrap.servers='${KAFKA_BOOTSTRAP}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
# configure hostname
sed -ri 's/druid.host=.*/druid.host='${HOSTNAME}'/g' $DRUID_DIR/conf/druid/$nodeType/runtime.properties

if [ "$DRUID_XMX" != "-" ]; then
    # configure JVM xmx heap space setting
    sed -ri 's/Xmx.*/Xmx'${DRUID_XMX}'/g' $DRUID_DIR/conf/druid/$nodeType/jvm.config
fi

if [ "$DRUID_XMS" != "-" ]; then
    # configure JVM xms heap space setting
    sed -ri 's/Xms.*/Xms'${DRUID_XMS}'/g' $DRUID_DIR/conf/druid/$nodeType/jvm.config
fi

if [ "$DRUID_NEWSIZE" != "-" ]; then
    # configure JVM heap new size
    sed -ri 's/NewSize=.*/NewSize='${DRUID_NEWSIZE}'/g' $DRUID_DIR/conf/druid/$nodeType/jvm.config
fi

if [ "$DRUID_MAXNEWSIZE" != "-" ]; then
    # configure JVM heap max new size
    sed -ri 's/MaxNewSize=.*/MaxNewSize='${DRUID_MAXNEWSIZE}'/g' $DRUID_DIR/conf/druid/$nodeType/jvm.config
fi

if [ "$DRUID_MAXDIRECTMEMORY" != "-" ]; then
    # configure JVM heap new size
    sed -ri 's/MaxDirectMemorySize=.*/MaxDirectMemorySize='${DRUID_MAXDIRECTMEMORY}'/g' $DRUID_DIR/conf/druid/$nodeType/jvm.config
fi

if [ "$DRUID_LOGLEVEL" != "-" ]; then
    # configure log level
    sed -ri 's/druid.emitter.logging.logLevel=.*/druid.emitter.logging.logLevel='${DRUID_LOGLEVEL}'/g' $DRUID_DIR/conf/druid/_common/common.runtime.properties
fi

if [ "$DRUID_PROCESS_BUFFER" != "-" ]; then
    # configure size of processing buffer
    sed -ri 's/druid.processing.buffer.sizeBytes=.*/druid.processing.buffer.sizeBytes='${DRUID_PROCESS_BUFFER}'/g' $DRUID_DIR/conf/druid/$nodeType/runtime.properties
fi

if [ "$DRUID_PROCESS_THREADS" != "-" ]; then
    # configure number of processing threads
    sed -ri 's/druid.processing.numThreads=.*/druid.processing.numThreads='${DRUID_PROCESS_THREADS}'/g' $DRUID_DIR/conf/druid/$nodeType/runtime.properties
fi

mkdir -p $DRUID_DIR/var/druid/hadoop-tmp $DRUID_DIR/var/tmp

LIB_DIR=$DRUID_DIR/lib
CONF_DIR=$DRUID_DIR/conf/druid

cat $DRUID_DIR/conf/druid/_common/common.runtime.properties

cd $DRUID_DIR
java `cat $CONF_DIR/$nodeType/jvm.config | xargs` -cp $CONF_DIR/_common:$CONF_DIR/$nodeType:$LIB_DIR/* io.druid.cli.Main server $nodeType
