FROM php:7.4-fpm

#
# Set container timezone
#
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#
# Install tools
#
RUN apt-get update && apt-get install --no-install-recommends -y \
        unzip \
        telnet \
        openssl \
        libaio1 \
        curl

#
# Install oracle
#
ARG ORACLE_CLIENT_VERSION="19.10.0.0.0dbru"
ARG ORACLE_CLIENT_PATH="/opt/oracle"
ARG ORACLE_CONFIG_PATH="/.conf"

RUN mkdir $ORACLE_CLIENT_PATH

ADD instantclient-basic-linux.x64-$ORACLE_CLIENT_VERSION.zip $ORACLE_CLIENT_PATH
ADD instantclient-sdk-linux.x64-$ORACLE_CLIENT_VERSION.zip $ORACLE_CLIENT_PATH
ADD instantclient-sqlplus-linux.x64-$ORACLE_CLIENT_VERSION.zip $ORACLE_CLIENT_PATH

RUN unzip $ORACLE_CLIENT_PATH/instantclient-basic-linux.x64-$ORACLE_CLIENT_VERSION.zip -d $ORACLE_CLIENT_PATH
RUN unzip $ORACLE_CLIENT_PATH/instantclient-sdk-linux.x64-$ORACLE_CLIENT_VERSION.zip -d $ORACLE_CLIENT_PATH
RUN unzip $ORACLE_CLIENT_PATH/instantclient-sqlplus-linux.x64-$ORACLE_CLIENT_VERSION.zip -d $ORACLE_CLIENT_PATH

RUN rm -f $ORACLE_CLIENT_PATH/*.zip
RUN mv $ORACLE_CLIENT_PATH/instantclient_* $ORACLE_CLIENT_PATH/instantclient_$ORACLE_CLIENT_VERSION

ENV ORACLE_HOME="${ORACLE_CLIENT_PATH}/instantclient_$ORACLE_CLIENT_VERSION"
ENV LD_LIBRARY_PATH="${ORACLE_HOME}"

RUN mkdir $ORACLE_CONFIG_PATH
ENV TNS_ADMIN="${ORACLE_CONFIG_PATH}"

RUN docker-php-ext-configure oci8 --with-oci8=instantclient,$ORACLE_HOME
RUN docker-php-ext-install oci8

#
# Install redis
#
RUN mkdir -p /tmp/redis

COPY redis-5.3.7.tgz /tmp/redis/redis-5.3.7.tgz

RUN cd /tmp/redis/ \
        && tar -xvf redis-5.3.7.tgz \
        && cd redis-5.3.7 \
        && phpize \
        && ./configure \
        && make install \
        && touch /usr/local/etc/php/conf.d/20-redis.ini \
        && echo 'extension=redis' > /usr/local/etc/php/conf.d/20-redis.ini

RUN docker-php-ext-enable redis

#
# Add php configs
#
ADD php-date.ini /usr/local/etc/php/conf.d/php-date.ini


#
# Add composer
#
ADD composer.phar /app/composer.phar

WORKDIR /app
RUN mv composer.phar /usr/local/bin/composer
RUN chmod 0755 /usr/local/bin/composer
RUN ln -s /usr/local/bin/composer /usr/bin/composer

#
# Add entrypoint
#
ADD entrypoint.sh /etc/entrypoint.sh
RUN chmod 0755 /etc/entrypoint.sh

#
# Configure system user
#
RUN usermod -s /bin/bash www-data
RUN usermod -d /app www-data
