FROM        debian

MAINTAINER WikiFM sysadmin@wikifm.org

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ADD ./sources.list /etc/apt/

ADD ./run.sh /

ADD ./initDocker.sh /root/
RUN /bin/chmod +x /root/initDocker.sh
RUN /root/initDocker.sh && rm /root/initDocker.sh

EXPOSE 25 587 110 143 993 995

ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/run.sh"]
