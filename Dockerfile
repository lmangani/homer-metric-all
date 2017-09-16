FROM debian:jessie
MAINTAINER L. Mangani <lorenzo.mangani@gmail.com>
# v.5.02

# Default baseimage settings
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Update and upgrade apt
RUN apt-get update -qq
# RUN apt-get upgrade -y
RUN apt-get install --no-install-recommends --no-install-suggests -yqq ca-certificates apache2 libapache2-mod-php5 php5 php5-ldap php5-cli php5-gd php-pear php5-dev php5-mysql php5-json php-services-json git wget curl pwgen && rm -rf /var/lib/apt/lists/* && a2enmod php5

# MySQL
RUN mkdir /docker-entrypoint-initdb.d && \
    groupadd -r mysql && useradd -r -g mysql mysql && \
    apt-get update && apt-get install -y perl libdbi-perl libclass-dbi-mysql-perl --no-install-recommends && rm -rf /var/lib/apt/lists/*

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
ENV MYSQL_MAJOR 5.7
ENV MYSQL_VERSION 5.6.27
RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list && \
    apt-get update && apt-get install -y mysql-server libmysqlclient18 && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chmod -R 755 /var/lib/mysql/

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
	&& echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
	&& mv /tmp/my.cnf /etc/mysql/my.cnf


WORKDIR /

# HOMER 5
RUN git clone --depth 1 https://github.com/sipcapture/homer-api.git /homer-api && \
    git clone --depth 1 https://github.com/sipcapture/homer-ui.git /homer-ui

RUN chmod -R +x /homer-api/scripts/mysql/* && \
    cp -R /homer-api/scripts/mysql/. /opt/ && \
    cp -R /homer-ui/* /var/www/html/ && \
    cp -R /homer-api/api /var/www/html/ && \
    chown -R www-data:www-data /var/www/html/store/ && \
    chmod -R 0775 /var/www/html/store/dashboard && \
    wget https://raw.githubusercontent.com/sipcapture/homer-config/master/docker/configuration.php -O /var/www/html/api/configuration.php && \
    wget https://raw.githubusercontent.com/sipcapture/homer-config/master/docker/preferences.php -O /var/www/html/api/preferences.php && \
    wget https://raw.githubusercontent.com/sipcapture/homer-config/master/docker/vhost.conf -O /etc/apache2/sites-enabled/000-default.conf

# Kamailio + sipcapture module
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xfb40d3e6508ea4c8 && \
    echo "deb http://deb.kamailio.org/kamailio50 jessie main" >> etc/apt/sources.list && \
    echo "deb-src http://deb.kamailio.org/kamailio50 jessie main" >> etc/apt/sources.list && \
    apt-get update -qq && apt-get install -f -yqq kamailio rsyslog kamailio-outbound-modules kamailio-geoip-modules kamailio-sctp-modules kamailio-tls-modules kamailio-websocket-modules kamailio-utils-modules kamailio-mysql-modules kamailio-extra-modules && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && git init tmpgit \
  && cd tmpgit \
  && git remote add -f origin https://github.com/sipcapture/homer-config \
  && git config core.sparseCheckout true \
  && echo "metric/kamailio5/" >> .git/info/sparse-checkout \
  && git pull origin master \
  && cd .. && cp -r tmpgit/metric/kamailio5/* /etc/kamailio/ && rm -rf tmpgit \
  && chmod 775 /etc/kamailio/kamailio.cfg \
  && ln -s /usr/lib64 /usr/lib/x86_64-linux-gnu/

# PATCH CONFIG
RUN sed -i -e "s/127.0.0.1:8086/influxdb:8086/g" /etc/kamailio/kamailio.cfg

# GeoIP (http://dev.maxmind.com/geoip/legacy/geolite/)
RUN apt-get update -qq && apt-get install -f -yqq geoip-database geoip-database-extra

# Install the cron service
RUN touch /var/log/cron.log && apt-get install cron -y && \
    echo "30 3 * * * /opt/homer_mysql_rotate >> /var/log/cron.log 2>&1" > /crons.conf && \
    crontab /crons.conf

COPY run.sh /run.sh
RUN chmod a+rx /run.sh

# Add persistent MySQL volumes
VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/www/html/store"]

# UI
EXPOSE 80
# HEP
EXPOSE 9060
# MySQL
#EXPOSE 3306

ENTRYPOINT ["/run.sh"]
