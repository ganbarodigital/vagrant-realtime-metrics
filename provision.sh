#!/bin/bash

# ========================================================================
#
# ganbarodigital/vagrant-realtime-metrics
#
# A Graphite / statsd instance for collecting realtime metrics from your
# app and environment.
#
# See http://ganbarodigital.com/w/realtime-metrics-with-graphite
# See http://blog.stuartherbert.com/php/2011/09/21/real-time-graphing-with-graphite/
#
# ------------------------------------------------------------------------

# ========================================================================
#
# Versions
#
# Edit if you want to change which versions we install
#
# ------------------------------------------------------------------------

elasticsearch_version="1.3.2"
etsy_version="0.7.2"
grafana_version="1.9.1"
graphite_version="0.9.x"
nodejs_version="0.12.0"

# ========================================================================
#
# Script setup
#
# ------------------------------------------------------------------------

basedir=$(dirname $0)
basedir=$(cd $basedir && pwd)

# ========================================================================
#
# Image setup
#
# ------------------------------------------------------------------------

apt-get -y install software-properties-common
apt-get -y update
apt-get -y install build-essential git wget curl python-dev

# Pre-req for installing source code
mkdir ~/src

# ========================================================================
#
# Supervisor
#
# Install this first so that there's somewhere to drop config files into
#
# ------------------------------------------------------------------------

apt-get -y install supervisor
cp $basedir/files/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ========================================================================
#
# HTTP frontend
#
# ------------------------------------------------------------------------

# Install
apt-get -y install nginx
service nginx stop

# Config files
cp $basedir/files/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Startup scripts
cp $basedir/files/etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf

# ========================================================================
#
# NodeJS
#
# Needed for etsy's statsd
#
# ------------------------------------------------------------------------

# Install
cd ~/src \
    && wget http://nodejs.org/dist/v0.12.0/node-v${nodejs_version}.tar.gz \
    && tar -zxf node-v${nodejs_version}.tar.gz \
    && cd node-v${nodejs_version} \
    && ./configure \
    && make install

# ========================================================================
#
# Statsd
#
# ------------------------------------------------------------------------

# Install statsd into /opt
    cd ~/src \
    && git clone https://github.com/etsy/statsd.git \
    && cd statsd \
    && git checkout v${etsy_version} \
    && mkdir /opt/statsd \
    && cp -r * /opt/statsd

# Install statsd config file
cp $basedir/files/opt/statsd/config.js /opt/statsd/config.js

# Startup scripts
cp $basedir/files/etc/supervisor/conf.d/statsd.conf /etc/supervisor/conf.d/statsd.conf

# ========================================================================
#
# Graphite
#
# ------------------------------------------------------------------------

# Dependencies
apt-get -y install python-django-tagging python-simplejson \
                   python-memcache python-ldap python-cairo \
                   python-pysqlite2 python-support python-pip \
                   gunicorn memcached

pip install Twisted==11.1.0
pip install Django==1.5

# Install Whisper, Carbon, and Graphite-web
cd ~/src \
    && git clone https://github.com/graphite-project/whisper.git \
    && cd whisper \
    && git checkout ${graphite_version} \
    && python setup.py install

cd ~/src \
    && git clone https://github.com/graphite-project/carbon.git \
    && cd carbon \
    && git checkout ${graphite_version} \
    && python setup.py install

cd ~/src \
    && git clone https://github.com/graphite-project/graphite-web.git \
    && cd graphite-web \
    && git checkout ${graphite_version} \
    && python setup.py install

# Realtime hack
sed -e 's|var interval = 60;|var interval = 1;|g' -i /opt/graphite/webapp/content/js/*.js

# Config files
cp $basedir/files/opt/graphite/conf/carbon.conf /opt/graphite/conf/carbon.conf
cp $basedir/files/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
cp $basedir/files/opt/graphite/conf/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
mv /opt/graphite/conf/storage-aggregation.conf.example /opt/graphite/conf/storage-aggregation.conf

# 2nd state of setup after installing config files
mkdir -p /opt/graphite/storage/whisper
chown -R www-data:www-data /opt/graphite/storage
chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper
touch /opt/graphite/storage/graphite.db
chmod 0664 /opt/graphite/storage/graphite.db
cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput

# Startup scripts
cp $basedir/files/etc/supervisor/conf.d/carbon-cache.conf /etc/supervisor/conf.d/carbon-cache.conf
cp $basedir/files/etc/supervisor/conf.d/graphite-webapp.conf /etc/supervisor/conf.d/graphite-webapp.conf
cp $basedir/files/etc/supervisor/conf.d/memcached.conf /etc/supervisor/conf.d/memcached.conf

# ========================================================================
#
# ElasticSearch
#
# Needed for Grafara's dashboards
#
# ------------------------------------------------------------------------

# Dependencies
apt-get -y install openjdk-7-jre

# Install ElasticSearch
cd ~/src \
    && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${elasticsearch_version}.deb \
    && dpkg -i elasticsearch-${elasticsearch_version}.deb

cp $basedir/files/usr/local/bin/run_elasticsearch.sh /usr/local/bin/run_elasticsearch.sh
chmod 755 /usr/local/bin/run_elasticsearch.sh

# Startup files
cp $basedir/files/etc/supervisor/conf.d/elasticsearch.conf /etc/supervisor/conf.d/elasticsearch.conf

# ========================================================================
#
# Grafana
#
# ------------------------------------------------------------------------

# Install Grafana into /opt
cd ~/src \
    && wget http://grafanarel.s3.amazonaws.com/grafana-${grafana_version}.tar.gz \
    && tar -zxf grafana-${grafana_version}.tar.gz \
    && cd grafana-${grafana_version} \
    && mkdir /opt/grafana \
    && cp -r * /opt/grafana

# Config files
cp $basedir/files/opt/grafana/config.js /opt/grafana/config.js

# ========================================================================
#
# All done
#
# ------------------------------------------------------------------------

service supervisor restart