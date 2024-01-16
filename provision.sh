#!/usr/bin/bash

DEBIAN_FRONTEND=noninteractive
CONFIG_DIR="/vagrant/config"

# install dependencies
apt update -y >/dev/null 2>&1
apt install bind9 bind9utils bind9-doc -y >/dev/null 2>&1

# set the default DNS and default start bind command
cp ${CONFIG_DIR}/named /etc/default

# check if we are on tierra or venus before copying files
if [ $(cat /etc/hostname) == "ns1" ]; then
    cp ${CONFIG_DIR}/ns1/named.conf.options /etc/bind
    cp ${CONFIG_DIR}/ns1/named.conf.local /etc/bind
    cp ${CONFIG_DIR}/ns1/db.dani.com /var/lib/bind
    cp ${CONFIG_DIR}/ns1/57.168.192.db /var/lib/bind
else
    cp ${CONFIG_DIR}/ns2/named.conf.local /etc/bind
    cp ${CONFIG_DIR}/ns2/named.conf.options /etc/bind
fi

# restart the service to apply all changes
systemctl restart named