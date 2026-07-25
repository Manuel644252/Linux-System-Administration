#!/bin/bash
# backup.sh
# Cria um backup incremental das pastas de origem, usando hard links
# para poupar espaço entre execuções (rsync --link-dest).
# Agendado via crontab para correr diariamente às 2h.

SOURCE1="/home/BkpNomeApelido"
SOURCE2="/home/PartilhaDeRede"
DEST="/home/BackupFolder"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$DEST/$DATE"

rsync -av --link-dest="$DEST/latest" "$SOURCE1" "$DEST/$DATE/"
rsync -av --link-dest="$DEST/latest" "$SOURCE2" "$DEST/$DATE/"

rm -f "$DEST/latest"
ln -s "$DEST/$DATE" "$DEST/latest"

echo "Backup concluído em $(date)"
