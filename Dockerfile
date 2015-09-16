FROM debian
MAINTAINER wikitolearn sysadmin@wikitolearn.org
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
RUN apt-get update
RUN apt-get -y install zip unzip nano apt-utils curl rsync git && rm -f /var/cache/apt/archives/*deb

ADD ./sources.list /etc/apt/

ADD ./run.sh /

RUN chmod +x /run.sh

RUN echo "postfix postfix/mailname string mail.wikitolearn.org" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

RUN apt-get update
RUN apt-get -y install supervisor && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install rsyslog && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install cron && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install logrotate && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install postfix && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install postfix-pcre && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install dovecot-common && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install dovecot-imapd && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install dovecot-pop3d && rm -f /var/cache/apt/archives/*deb
RUN apt-get -y install procmail && rm -f /var/cache/apt/archives/*deb

RUN maildirmake.dovecot /etc/skel/Maildir
RUN maildirmake.dovecot /etc/skel/Maildir/.Archive
RUN maildirmake.dovecot /etc/skel/Maildir/.Sent
RUN maildirmake.dovecot /etc/skel/Maildir/.Trash
RUN chmod 700 /etc/skel/Maildir/

RUN useradd -p $(perl -e'print crypt("sysadmin", "sysadmin")') -m -s /bin/bash -N sysadmin

RUN sed -i '/^mail_location/d' /etc/dovecot/conf.d/10-mail.conf
RUN sed -i 's/#.*mail_location.*Maildir/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf

RUN sed -i 's/#unix_listener/unix_listener/' /etc/dovecot/conf.d/10-master.conf
RUN sed -i '/unix_listener/{n;s/#/ /}' /etc/dovecot/conf.d/10-master.conf
RUN sed -i '/unix_listener/{n;n;s/#/ /}' /etc/dovecot/conf.d/10-master.conf

RUN sed -i '/^auth_mechanisms/ s/$/ login/' /etc/dovecot/conf.d/10-auth.conf

RUN sed -i 's/ssl = no/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf
RUN sed -i 's/#ssl_cert = .*/ssl_cert = <\/etc\/ssl\/certs\/mail.crt/' /etc/dovecot/conf.d/10-ssl.conf
RUN sed -i 's/#ssl_key = .*/ssl_key = <\/etc\/ssl\/private\/mail.key/' /etc/dovecot/conf.d/10-ssl.conf

RUN postconf -e "myorigin = wikitolearn.org"
RUN postconf -e "myhostname=mail.wikitolearn.org"
RUN postconf -e "relay_domains = wikitolearn.org wikifm.org"
RUN postconf -e "mydestination = wikitolearn.org wikifm.org"

RUN postconf -e "home_mailbox = Maildir/"
RUN postconf -e "mailbox_command = "

RUN postconf -e 'smtpd_sasl_type = dovecot'
RUN postconf -e 'smtpd_sasl_auth_enable = yes'
RUN postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
RUN postconf -e 'smtpd_sasl_path = private/auth'

RUN postconf -e 'smtpd_tls_cert_file=/etc/ssl/certs/mail.crt'
RUN postconf -e 'smtpd_tls_key_file=/etc/ssl/private/mail.key'
RUN postconf -e 'smtpd_use_tls=yes'
RUN postconf -e 'smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache'
RUN postconf -e 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'
RUN postconf -e 'smtpd_tls_security_level=may'
RUN postconf -e 'smtpd_tls_protocols = !SSLv2, !SSLv3'

RUN postconf -e 'alias_maps = hash:/etc/aliases'
RUN postconf -e 'alias_database = hash:/etc/aliases'

RUN postconf -e 'local_recipient_maps = proxy:unix:passwd.byname $alias_maps'

RUN postconf -e 'mynetworks = 127.0.0.0/8 172.17.0.0/16 [::ffff:127.0.0.0]/104 [::1]/128'

ADD ./modify_master_cf.sh /root/
RUN /bin/chmod +x /root/modify_master_cf.sh
RUN /root/modify_master_cf.sh
RUN rm /root/modify_master_cf.sh

EXPOSE 25 587 110 143 993 995

ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/run.sh"]
