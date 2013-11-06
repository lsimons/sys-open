#!/usr/bin/env bash

# todo: this could be much better :(

set -e
set -x

remote=wp@wp.example.org
plugindir=`dirname $0`

find $plugindir -type d -exec chmod 755 {} \;
find $plugindir -type f -exec chmod 644 {} \;
chmod +x $plugindir/update-plugins.sh

rsync -av --delete $plugindir/ $remote:/home/wp/www/plugins/

ssh $remote "find /home/wp/www/plugins/ -type d -exec chmod 755 {} \;"
ssh $remote "find /home/wp/www/plugins/ -type f -exec chmod 644 {} \;"
