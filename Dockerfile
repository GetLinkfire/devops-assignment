FROM anapsix/alpine-java:8_server-jre_unlimited

MAINTAINER Kristian Martensen @ Linkfire <km@linkfire.com>
# thanks to Anastas Dancha <anapsix@random.io> for the alpine-java image
# this image is very heavily inspired by the znly/docker-druid image by jbaptiste <jb@zen.ly>

# Don't change these on runtime
ENV DRUID_VERSION      0.12.1
ENV DRUID_DIR          /opt/druid

# These must be set, but not necessarily changed on runtime
ENV MYSQL_HOST         mysql
ENV MYSQL_PORT         3306
ENV MYSQL_DBNAME       druid
ENV MYSQL_USERNAME     druid
ENV MYSQL_PASSWORD     druid
ENV ZOOKEEPER_HOST     zookeeper

# These variables must be adjusted on runtime
ENV S3_STORAGE_BUCKET  druid-deep-storage
ENV S3_INDEXING_BUCKET druid-indexing
ENV S3_ACCESS_KEY      xxxxxxxxxxxx
ENV S3_SECRET_KEY      xxxxxxxxxxxx

# Optional variables
ENV DRUID_XMX              '-'
ENV DRUID_XMS              '-'
ENV DRUID_NEWSIZE          '-'
ENV DRUID_MAXNEWSIZE       '-'
ENV DRUID_MAXDIRECTMEMORY  '-'
ENV DRUID_HOSTNAME         '-'
ENV DRUID_LOGLEVEL         '-'
ENV DRUID_PROCESS_BUFFER   '-'
ENV DRUID_PROCESS_THREADS  '-'

RUN set -ex \
    && apk add --no-cache bash curl \
    && curl http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt \
    && ln -s $DRUID_DIR-$DRUID_VERSION $DRUID_DIR \
    && cp $DRUID_DIR/extensions/druid-hdfs-storage/aws-java-sdk-s3-1.10.77.jar $DRUID_DIR/lib \
    && cp $DRUID_DIR/extensions/druid-hdfs-storage/hadoop-aws-2.7.3.jar $DRUID_DIR/lib \
    && mkdir $DRUID_DIR/log \
    && mkdir -p $DRUID_DIR/var/tmp \
    && mkdir -p $DRUID_DIR/var/druid/hadoop-tmp \
    && rm -rf $DRUID_DIR/quickstart $DRUID_DIR/conf-quickstart $DRUID_DIR/bin/init $DRUID_DIR/bin/generate-example-metrics $DRUID_DIR/bin/jconsole.sh \
    && curl http://static.druid.io/artifacts/releases/mysql-metadata-storage-$DRUID_VERSION.tar.gz | tar -xzf - -C $DRUID_DIR/extensions \
    && java -classpath "/opt/druid/lib/*" io.druid.cli.Main tools pull-deps --clean  -c io.druid.extensions.contrib:kafka-emitter:0.12.0 --no-default-hadoop \
    && mv /extensions/kafka-emitter /opt/druid/extensions/

COPY conf $DRUID_DIR/conf
COPY start-druid.sh /start-druid.sh

ENTRYPOINT ["/start-druid.sh"]
