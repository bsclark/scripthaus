#Encrypt Backup just made
if [ -f $BACKUP_DIR/$DB_HOST/backup_$DATE.gz ];
then
  ls -ail $BACKUP_DIR/$DB_HOST/backup_$DATE.gz

   gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase-file /path/to/passphrase $BACKUP_DIR/$DB_HOST/backup_$DATE.gz

  rm -rf $BACKUP_DIR/$DB_HOST/backup_$DATE.gz
  ls -ail $BACKUP_DIR/$DB_HOST/backup_$DATE.gz.gpg
fi



