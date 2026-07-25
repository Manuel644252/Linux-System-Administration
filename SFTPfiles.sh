#!/bin/bash
# SFTPfiles.sh
# Monitoriza alterações na pasta SFTP e regista-as num ficheiro de log.
# Agendado via crontab para correr a cada 5 minutos.

LOGFILE="/var/log/sftp_changes.log"
SFTP_DIR="/home/sftp"

echo "$(date): A verificar diretório SFTP..." >> "$LOGFILE"

find "$SFTP_DIR" -type f -newermt "-5 minutes" | while read -r file; do
    echo "$(date): Alteração detetada -> $file" >> "$LOGFILE"
done
