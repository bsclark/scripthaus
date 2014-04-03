#!/bin/bash
#
# The script;
#    Encrypts all the files in a directory

# ENV Vars
_DEBUG="off"        # on/off
DATE=`date +%Y%m%d`
LOGDIR=/root/logs
LOGFILE=$LOGDIR/encrypt-status-$DATE.log
PASSPHRASEFILE=/root/.passphrase

function usage() {
cat << EOF
Usage: ${0##*/} <options>
OPTIONS:
  REQUIRED
   -p Full Directory Path where files are located.
 OPTIONAL
   -d Debug Messages on/off. Defaults to off"
   -h Usage/Help

Example: 
${0##*/} -p /some/dir/path/to/encyrpt
EOF
exit 0
}

# A ':' after an option in the getopts line say the next bit is the argument value
# and is set with 'SOMEVARIABLE="$OPTARG"'
while getopts "dp:h" OPTION_NAME; do
  case $OPTION_NAME in
    d) _DEBUG="on";;
    p) BACKUP_DIR="$OPTARG";;
    h|*) usage
       exit 0
       ;;
  esac
done

function DEBUG() {
  [ "$_DEBUG" == "on" ] &&  $@
}

# Verify dir we expect to be there are
if [ ! -d $LOGDIR ]; then
  echo "Creating log directory $LOGS"
  mkdir $LOGDIR
  if [ $? != 0 ]; then
    echo "Error creating directory $LOGDIR"
    exit 1
  fi
fi

[ $(whoami) != "root" ] && err "You must be root to run this script"

# Make sure all required utils are installed
CMDS="gpg"
for i in $CMDS
do
  command -v $i >/dev/null && continue || { echo "ERROR: $i command not found."; exit 1; }
done

function encrypt() {
# File Encryption
for FILE in `ls -l $BACKUP_DIR|awk '{print $9}'`
do
  if [ -f $BACKUP_DIR/$FILE ]; then
    ls -ail $BACKUP_DIR/$FILE >> $LOGFILE
    gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase-file $PASSPHRASEFILE $BACKUP_DIR/$FILE
    rm -rf $BACKUP_DIR/$FILE
    ls -ail $BACKUP_DIR/$FILE.gpg >> $LOGFILE
  else
    echo "the file that was there aint no more... doing nothing."
  fi
done
}

# ===================================================
if [ -z "$BACKUP_DIR" ]; then
  usage
else
  encrypt
fi
