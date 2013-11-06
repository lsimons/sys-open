#!/usr/bin/env bash

# todo: this could be much better :(

set -e
set -x

remote=wp@wp.example.org
themesdir=`dirname $0`

find $themesdir -type d -exec chmod 755 {} \;
find $themesdir -type f -exec chmod 644 {} \;
chmod +x $themesdir/update-themes.sh

rsync -av --delete $themesdir/ $remote:/home/wp/www/themes/

ssh $remote "find /home/wp/www/themes/ -type d -exec chmod 755 {} \;"
ssh $remote "find /home/wp/www/themes/ -type f -exec chmod 644 {} \;"
