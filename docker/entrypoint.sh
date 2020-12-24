#!/bin/sh
set -e
if [ -f $CODE_PATH/$PHP_ENV_FILE ]; then
    cp -f $CODE_PATH/$PHP_ENV_FILE $CODE_PATH/.env
fi
if [ -d $CODE_PATH/storage ]; then
    chmod -R 777 $CODE_PATH/storage
fi
sudo chsh -s /bin/zsh

#/usr/sbin/crond   -f  -L  /var/log/cron/cron.log
supervisord --nodaemon --configuration /etc/supervisor/conf.d/supervisord.conf
