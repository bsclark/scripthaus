#!/bin/bash
# 
# Encrypt files in dir.
# Assumes root is running script and key files are found in /root. Prob need to fix sometime.

while getopts "i:o:r:h:t:" OPTION_NAME; do
  case $OPTION_NAME in
    i) UNENCRYPTED_REPORTS_DIR="$OPTARG";;
    o) ENCRYPTED_REPORTS_DIR="$OPTARG";;
    r) GPG_RECPT="$OPTARG";;
    h) GPG_HIDDEN_RECPT="$OPTARG";;
    t) TIMES_DAILY="$OPTARG";;
  esac
done

if [ -z "$TIMES_DAILY" ]
  then 
  TIMES_DAILY=1
fi

DATE=`date -d "$TIMES_DAILY day ago" +%Y-%m-%d`		# meant to run on files from day before
LDATE=`date +%F-%H%M`

LOGFILE="/root/encryption_logs/report_encryption-$LDATE.log"

GPG_ENCRYPT="gpg -a --yes --no-tty --trust-model always --encrypt --recipient $GPG_RECPT --hidden-re
cipient $GPG_HIDDEN_RECPT --passphrase-file /root/.gnupg/passphrase"

# Find all sub dirs in the outbound data dir
DIRS=$(find $UNENCRYPTED_REPORTS_DIR -type d )

for DIR in ${DIRS[@]}; do
  BASEDIR=$(basename $DIR)
  NUM_FILES=`ls $DIR/*-$DATE.log_* | wc -l`
  if [ $NUM_FILES -eq 0 ]; then
    echo "No files in $DIR to encrypt." >> $LOGFILE
  else
    FILES=`ls $DIR/*-$DATE.log_*`
    for FILE in ${FILES[@]}; do
      FILENAME=$(basename $FILE)
      echo $BASEDIR >> $LOGFILE
      if [ ! -d $ENCRYPTED_REPORTS_DIR/$BASEDIR ]; then
        echo "Created $ENCRYPTED_REPORTS_DIR/$BASEDIR because it didnt exist." >> $LOGFILE
        mkdir -p $ENCRYPTED_REPORTS_DIR/$BASEDIR
      fi
			
      if [ -s $FILE ]; then
        echo "Copying file to encrypt" >> $LOGFILE
        cp $FILE /tmp/$FILENAME
        ls -l  /tmp/$FILENAME >> $LOGFILE

        echo "Encrypting $FILE (/tmp/$FILENAME)" >> $LOGFILE
        $GPG_ENCRYPT --output $ENCRYPTED_REPORTS_DIR/$BASEDIR/$FILENAME.asc /tmp/$FILENAME
        chown root:root $ENCRYPTED_REPORTS_DIR/$BASEDIR/$FILENAME.asc
        chmod 644 $ENCRYPTED_REPORTS_DIR/$BASEDIR/$FILENAME.asc
        ls -l $ENCRYPTED_REPORTS_DIR/$BASEDIR/$FILENAME.asc >> $LOGFILE

        echo "Cleanup" >> $LOGFILE
	rm -rf /tmp/$FILENAME
      fi
    done
  fi
done
