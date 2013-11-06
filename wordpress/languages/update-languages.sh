#!/usr/bin/env bash

# todo: this could be much better :(

set -e
set -x

remote=wp@wp.example.org
languagesdir=`dirname $0`

find $languagesdir -type d -exec chmod 755 {} \;
find $languagesdir -type f -exec chmod 644 {} \;
chmod +x $languagesdir/update-languages.sh

rsync -av --delete $languagesdir/ $remote:/home/wp/www/languages/

ssh $remote "find /home/wp/www/languages/ -type d -exec chmod 755 {} \;"
ssh $remote "find /home/wp/www/languages/ -type f -exec chmod 644 {} \;"
