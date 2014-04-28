#!/bin/bash
#
# Script to deploy WAR file to prod server.
# Assumes the account the script is run from as ssh access to root. Need to fix this someday.

PS3="Type a number or 'q' to quit: "

BASE_DIR=/path/to/tomcat/webapps                  # ex. /usr/share/tomcat6/webapps
PRODSERVER=<some server name>                     # Name of server to deploy WAR file to
SSHUSER=root
ARCHIVE_BASE_DIR=/path/to/archive/current_war_to  # ex. /opt/Archive

function cprestart {
  echo "Archiving current prodcution file ($BASE_DIR/$BFILENAME2) on $PRODSERVER"
  ssh $SSHUSER@$PRODSERVER "cp $BASE_DIR/$BFILENAME2 $ARCHIVE_BASE_DIR/$BFILENAME2.`date  +"%Y%m%d"`"

  echo " "
  echo "Deploying to production ($PRODSERVER)"
  ssh $SSHUSER@$PRODSERVER "rm -rf $BASE_DIR/$BFILENAME*"
  scp $BASE_DIR/$BFILENAME2 $SSHUSER@$PRODSERVER:$BASE_DIR/    

  listremotefile

  echo " "
  echo "Deploying to production ($PRODSERVER)"
  echo "Restarting Tomcat on production ($PRODSERVER)"
  ssh $SSHUSER@$PRODSERVER "service tomcat6 restart"
  echo " "
  echo "Restarting HTTPD on production ($PRODSERVER)"
  ssh $SSHUSER@$PRODSERVER "service httpd restart"
}

function listremotefile {
  ssh $SSHUSER@$PRODSERVER "ls -l $BASE_DIR/$BFILENAME2"
}


fileList=`find $BASE_DIR/ -maxdepth 1 -type f`

echo "Select which WAR file to deploy to production ($PRODSERVER)"
select fileName in $fileList; do
  if [ -n "$fileName" ]; then
    BFILENAME=`basename $fileName .war`
    BFILENAME2=`basename $fileName`

    clear
    echo "Current file on production ($PRODSERVER)"
    listremotefile
    echo ""
    echo "Current file on THIS server (`hostname`)"
    ls -l $BASE_DIR/$BFILENAME2
    
    echo ""
    echo "Do you want to continue with this deployment to production ($PRODSERVER)? [y/n]: "

    read USER_CONFIRM

    if [ $USER_CONFIRM != "y" ]; then
      echo "Exiting w/o doing anything per user input"
      break
    else
      cprestart
    fi
  fi
  break
done

