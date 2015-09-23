#!/bin/bash

if [ -f /certs/mail.crt ] ; then
 echo "Copy /certs/mail.crt"
 cp /certs/mail.crt /etc/ssl/certs/mail.crt
fi
if [ -f /certs/mail.key ] ; then
 echo "Copy /certs/mail.key"
 cp /certs/mail.key /etc/ssl/private/mail.key
fi

if [[ ! -f /etc/ssl/private/mail.key ]] ; then
 rm -f /etc/ssl/private/mail.key
 rm -f /etc/ssl/certs/mail.crt

 openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
 openssl rsa -passin pass:x -in server.pass.key -out /etc/ssl/private/mail.key
 rm server.pass.key
 openssl req -new -key /etc/ssl/private/mail.key -out server.csr -subj "/C=IT/ST=Italia/L=Milano/O=WikiFM/OU=IT Department/CN=www.wikifm.org"
 openssl x509 -req -days 365000 -in server.csr -signkey /etc/ssl/private/mail.key -out /etc/ssl/certs/mail.crt
 rm server.csr
fi

if [[ "$RELAYHOST" != "" ]] ; then
 sed  -i '/relayhost/d' /etc/postfix/main.cf
 echo "relayhost = "$RELAYHOST >> /etc/postfix/main.cf
fi

/etc/init.d/postfix start
/etc/init.d/postfix stop

/usr/bin/supervisord
