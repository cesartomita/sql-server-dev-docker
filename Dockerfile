FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/opt/mssql/backup /scripts

COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/restore.sql /scripts/restore.sql

RUN chmod -R 755 /var/opt/mssql && \
    chmod -R 755 /scripts && \
    chmod +x /scripts/entrypoint.sh

USER root

ENTRYPOINT ["/scripts/entrypoint.sh"]