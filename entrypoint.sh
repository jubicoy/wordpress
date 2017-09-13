#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

# Copy configuration files
if [ ! -f /var/www/wordpress/wp-content/wp-config.php ]; then
    cp -f /workdir/wp-config.php /var/www/wordpress/wp-content/wp-config.php
    sed -i "s/database_name_here/${MYSQL_DATABASE}/g" /var/www/wordpress/wp-content/wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/g" /var/www/wordpress/wp-content/wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/g" /var/www/wordpress/wp-content/wp-config.php
    sed -i "s/db_host_here/${DB_HOST}/g" /var/www/wordpress/wp-content/wp-config.php

    # Move default plugins and themes back to volume
    cp -arf /tmp/plugins /var/www/wordpress/wp-content/
    cp -arf /tmp/themes /var/www/wordpress/wp-content/
    cp -arf /tmp/index.php /var/www/wordpress/wp-content/
fi

if [ ! -f /tmp/dav_auth ]; then
  # Create locks file
  # touch /tmp/davlocks
  # Create WebDAV Basic auth user
  echo ${DAV_PASS}|htpasswd -i -c /tmp/dav_auth ${DAV_USER}
fi

# Add nginx configuration if does not exist
if [ ! -f /var/www/wordpress/wp-content/conf/default.conf ]; then
  mkdir -p /var/www/wordpress/wp-content/conf/
  mv /workdir/default.conf /var/www/wordpress/wp-content/conf/default.conf
fi

if [ ! -f /var/www/wordpress/wp-content/conf/php.ini ]; then
  mv /tmp/php.ini /var/www/wordpress/wp-content/conf/php.ini
fi

exec "/usr/bin/supervisord"
