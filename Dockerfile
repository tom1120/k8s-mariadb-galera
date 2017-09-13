FROM mariadb:10.2.8

ADD ["my.cnf", "/etc/mysql/"]
ADD ["entrypoint.sh", "/usr/local/bin/"]
ADD ["peer-finder/peer-finder", "/usr/local/bin/"]

COPY report_status.sh /report_status.sh
COPY healthcheck.sh /healthcheck.sh
COPY peer-finder/on-change.sh /on-change.sh
COPY galera-recovery.sh /galera-recovery.sh

RUN chmod +x /on-change.sh /galera-recovery.sh

#HEALTHCHECK --interval=10s --timeout=3s --retries=15 \
#	CMD /bin/sh /healthcheck.sh || exit 1

EXPOSE 3306 4444 4567 4568

ENTRYPOINT ["entrypoint.sh"]
CMD ["mysqld"]
