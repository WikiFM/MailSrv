#!/bin/bash

chmod +x /run.sh

debconf-set-selections <<< "postfix postfix/mailname string mail.wikitolearn.org"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get update
apt-get -y install supervisor rsyslog cron logrotate nano
apt-get -y install postfix postfix-pcre
apt-get -y install dovecot-common dovecot-imapd dovecot-pop3d
apt-get -y install procmail

maildirmake.dovecot /etc/skel/Maildir
maildirmake.dovecot /etc/skel/Maildir/.Archive
maildirmake.dovecot /etc/skel/Maildir/.Sent
maildirmake.dovecot /etc/skel/Maildir/.Trash
chmod 700 /etc/skel/Maildir/

useradd -p $(perl -e'print crypt("sysadmin", "sysadmin")') -m -s /bin/bash -N sysadmin

sed -i '/^mail_location/d' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#.*mail_location.*Maildir/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf

sed -i 's/#unix_listener/unix_listener/' /etc/dovecot/conf.d/10-master.conf
sed -i '/unix_listener/{n;s/#/ /}' /etc/dovecot/conf.d/10-master.conf
sed -i '/unix_listener/{n;n;s/#/ /}' /etc/dovecot/conf.d/10-master.conf

sed -i '/^auth_mechanisms/ s/$/ login/' /etc/dovecot/conf.d/10-auth.conf

sed -i 's/ssl = no/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf
sed -i 's/#ssl_cert = .*/ssl_cert = <\/etc\/ssl\/certs\/mail.crt/' /etc/dovecot/conf.d/10-ssl.conf
sed -i 's/#ssl_key = .*/ssl_key = <\/etc\/ssl\/private\/mail.key/' /etc/dovecot/conf.d/10-ssl.conf

postconf -e "myorigin = wikitolearn.org"
postconf -e "myhostname=mail.wikitolearn.org"
postconf -e "relay_domains = wikitolearn.org wikifm.org"
postconf -e "mydestination = wikitolearn.org wikifm.org"

postconf -e "home_mailbox = Maildir/"
postconf -e "mailbox_command = "

postconf -e 'smtpd_sasl_type = dovecot'
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
postconf -e 'smtpd_sasl_path = private/auth'


postconf -e 'smtpd_tls_cert_file=/etc/ssl/certs/mail.crt'
postconf -e 'smtpd_tls_key_file=/etc/ssl/private/mail.key'
postconf -e 'smtpd_use_tls=yes'
postconf -e 'smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache'
postconf -e 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'
postconf -e 'smtpd_tls_security_level=may'
postconf -e 'smtpd_tls_protocols = !SSLv2, !SSLv3'

postconf -e 'alias_maps = hash:/etc/aliases'
postconf -e 'alias_database = hash:/etc/aliases'

postconf -e 'local_recipient_maps = proxy:unix:passwd.byname $alias_maps'

cat <<EOF >> /etc/postfix/master.cf

submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_wrappermode=no
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth

EOF
