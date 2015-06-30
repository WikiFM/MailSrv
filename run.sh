#!/bin/bash

if [[ ! -f /etc/ssl/private/mail.key ]] || [[ ! -f /etc/ssl/certs/mail.crt ]] ; then
 rm -f /etc/ssl/private/mail.key
 rm -f /etc/ssl/certs/mail.crt

 openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
 openssl rsa -passin pass:x -in server.pass.key -out /etc/ssl/private/mail.key
 rm server.pass.key
 openssl req -new -key /etc/ssl/private/mail.key -out server.csr -subj "/C=IT/ST=Italia/L=Milano/O=WikiFM/OU=IT Department/CN=www.wikifm.org"
 openssl x509 -req -days 365000 -in server.csr -signkey /etc/ssl/private/mail.key -out /etc/ssl/certs/mail.crt
 rm server.csr
fi

/etc/init.d/postfix start
/etc/init.d/postfix stop

/usr/bin/supervisord
