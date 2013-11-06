#!/usr/bin/env bash

set -e
set -x

server_admin_email="ops@example.org"
server_admin_name="Example Operations"
title="Example Translation Server"
description="Example Translation Server"
manage_user=root
app_name=pootle
app_user=pootle
# env=local
# domain=local
env=test
domain=example.org
apache_group=www-data
python_dir=python2.7
server=${app_name}.${env}.${domain}
app_base=/home/${app_user}/${app_name}
app_venv=${app_base}/env
app_current=${app_base}/current
app_po=${app_base}/po
db_name=${app_name}
db_user=${app_user}
db_password=${app_user}

# expected:
# - ubuntu 12.04 LTS
# - posgres 9.3 with an empty ${db_name} database
# - apache WSGI vhost set up
# - /home/${user}/${app_name}/current/public exists

ssh ${manage_user}@${server} "(apt-get install -y python python-dev python-pip unzip; pip install virtualenv)"
ssh ${manage_user}@${server} pip install virtualenv

ssh ${app_user}@${server} virtualenv ${app_venv}
ssh ${app_user}@${server} "(source ${app_venv}/bin/activate; pip install pootle psycopg2 python-levenshtein)"

cat >pootle.conf.input.erb <<END
<%
server_admin_email='${server_admin_email}'
server_admin_name='${server_admin_name}'
title='${title}'
description='${description}'
manage_user='${manage_user}'
app_name='${app_name}'
app_user='${app_user}'
env='${env}'
domain='${domain}'
python_dir='${python_dir}'
apache_group='${apache_group}'
server='${server}'
app_base='${app_base}'
app_venv='${app_venv}'
app_current='${app_current}'
app_po='${app_po}'
db_name='${app_name}'
db_user='${app_user}'
db_password='${app_user}'
%>
END
cat pootle.conf.input.erb pootle.conf.erb | erb -T - > pootle.conf
cat pootle.conf.input.erb pootle_wsgi.py.erb | erb -T - > pootle_wsgi.py
cat pootle.conf.input.erb pootle_vhost.conf.erb | erb -T - > pootle_vhost.conf

scp pootle_wsgi.py pootle.conf ${app_user}@${server}:${app_current}

ssh ${manage_user}@${server} "(mkdir -p -m 775 ${app_po}; chmod 775 ${app_po}; chown ${app_user} ${app_po}; chgrp ${apache_group} ${app_po})"

echo Now customize the apache vhost with pootle_vhost.conf, i.e.
echo "  scp pootle_vhost.conf ${manage_user}@${server}:/etc/apache2/apps/pootle-vhost-customization.conf"
