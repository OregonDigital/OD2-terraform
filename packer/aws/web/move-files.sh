#!/bin/bash
cd /tmp
tar xf files.tar

sudo mv /tmp/files/etc/nginx/nginx.conf /etc/nginx/
sudo mv /tmp/files/etc/nginx/conf.d/* /etc/nginx/conf.d/
sudo mv /tmp/files/etc/monit.d/* /etc/monit.d/
sudo mv /tmp/files/data0/hydra/shared/app.sh /data0/hydra/shared/app.sh

rm -rf /tmp/files*
