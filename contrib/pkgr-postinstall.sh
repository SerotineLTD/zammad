#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad"
DB="zammad_production"
DB_USER="zammad"

echo -e "# (Re)Create init scripts"
zammad scale web=1 websocket=1 worker=1

echo -e "# Stopping Zammad"
systemctl stop zammad

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    # get existing password
    DB_PASS="$(grep "password:" < ${ZAMMAD_DIR}/config/database.yml | sed 's/.*password: //')"

    #zammad config set
    zammad config:set DATABASE_URL=postgres://${DB_USER}:${DB_PASS}@127.0.0.1/${DB}

    # db migration
    echo -e "# database.yml exists. Updating db..."
    zammad run rake db:migrate
else
    DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c10)"

    # create database
    echo -e "database.yml not found. Creating new db..."
    su - postgres -c "createdb -E UTF8 ${DB}"

    # create postgres user
    echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql 

    # grant privileges
    echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

    # update configfile
    sed -e "s/  password:/  password: ${DB_PASS}/" < ${ZAMMAD_DIR}/config/database.yml.pkgr > ${ZAMMAD_DIR}/config/database.yml

    # zammad config set
    zammad config:set DATABASE_URL=postgres://${DB_USER}:${DB_PASS}@127.0.0.1/${DB}

    # fill database
    zammad run rake db:migrate 
    zammad run rake db:seed
fi

echo -e "# Starting Zammad"
systemctl start zammad

# nginx config
if [ -d /etc/nginx/sites-enabled ]; then
    # copy nginx config 
    test -f /etc/nginx/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/nginx/sites-available/zammad.conf /etc/nginx/sites-available/zammad.conf

    if [ ! -f /etc/nginx/sites-available/zammad.conf ]; then
	# creating symlink
	ln -s /etc/nginx/sites-available/zammad.conf /etc/nginx/sites-enabled/zammad.conf
	
	echo -e "\nAdd your FQDN to servername directive in /etc/nginx/sites/enabled/zammad.conf anmd restart nginx if you're not testing localy!\n"
    fi

    echo -e "\nOpen http://localhost in your browser to start using Zammad!\n"

    # restart nginx
    systemctl restart nginx
else
    echo -e "\nOpen http://localhost:3000 in your browser to start using Zammad!\n"
fi