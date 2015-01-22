#!/bin/bash
#
# Script to (Dis/En)able Nagios Host & Service Notifications for Saturday Night Madness Servers
 
# ln nagiosSaturdayMadnessAlerts.bash ./nagiosSaturdayMadnessAlerts-Enable.bash
 
# cmd_typ 28 = Enable Notifications
# cmd_typ 29 = Disable Notifications

# ENV Vars
_DEBUG="on"		# on/off
DATE_LOG=`date +%F_%H%M`
BASE=/root/bin
LOGDIR=$BASE/saturdaynightmadness
LOGFILE=$LOGDIR/snm-$DATE_LOG.log
HOSTLIST=$LOGDIR/snm-hosts.txt  # one FQDN Hostname per line of systems you want to (dis/en)able notifications on

# Replace/Update with valid values
EMAIL_USERS='<some email address>'
NAGURL=http://<nagios server FQDN>/nagios/cgi-bin/cmd.cgi
USER=<nagios user id>
PASS=<nagios user id password>

function usage() {
cat << EOF
Usage: ${0##*/} <options>
OPTIONS:
 -d Debug Messages on/off. Defaults to on"
 -h Usage/Help
Example: Turn on Debug Messages
${0##*/} -d
EOF
exit 0
}
# A ':' after an option in the getopts line say the next bit is the argument value
# and is set with 'SOMEVARIABLE="$OPTARG"'
while getopts "dh" OPTION_NAME; do
  case $OPTION_NAME in
    d) _DEBUG="on";;
    h|*) usage
       exit 0
       ;;
  esac
done

# Basic email function
send_mail() {
  for USER in $EMAIL_USERS
  do
    echo $1 | mailx -s "ERROR: (Dis/En)able Nagios Host & Service Notifications for Saturday Night Madness Servers" $USER
  done
}

function DEBUG() {
  [ "$_DEBUG" == "on" ] &&  $@
}

[ $(whoami) != "root" ] && err "You must be root to run this script"

# Verify dir we expect to be there are
if [ ! -d $LOGDIR ]; then
  echo "Creating log directory $LOGDIR"
  mkdir $LOGDIR
  if [ $? != 0 ]; then
    send_mail "Error creating directory $LOGDIR"
    exit 1
  fi
fi

# Make sure all required utils are installed
CMDS="curl"
for i in $CMDS
do
  command -v $i >/dev/null && continue || { echo "ERROR: $i command not found."; exit 1; }
done


# determine what name was used to call the script
if [ `basename $0` == nagiosSaturdayMadnessAlerts-Enable.bash ]; then
  CMDTYPE=28
else
  CMDTYPE=29
fi

function die {
  echo $1 >> $LOGFILE; 
  exit 1;
}

for HOST in `cat  ${HOSTLIST}`; do

  if [ ${CMDTYPE} == 29 ]; then
    DEBUG echo "Saturday Night Madness - Attempting Disable Notification for ${HOST}" >> $LOGFILE
  elif [ ${CMDTYPE} == 28 ]; then
    DEBUG echo "Saturday Night Madness - Attempting Enable Notification for ${HOST}" >> $LOGFILE
  else
    DEBUG echo "Saturday Night Madness - Something went wrong!!!!!" >> $LOGFILE
    send_mail "Saturday Night Madness - Something went wrong!!!!!"
    exit 1
  fi

  curl --silent --show-error \
    --data cmd_typ=${CMDTYPE} \
    --data cmd_mod=2 \
    --data host=$HOST \
    --data ahas=1 \
    --data btnSubmit=Commit \
    --insecure \
    $NAGURL -u "$USER:$PASS" | grep -q "Your command request was successfully submitted to Nagios for processing." || die "Failed to contact nagios";

  if [ ${CMDTYPE} == 29 ]; then
    DEBUG echo "Saturday Night Madness - Disable Notification Success for ${HOST}" >> $LOGFILE
  elif [ ${CMDTYPE} == 28 ]; then
    DEBUG echo "Saturday Night Madness - Enable Notification Success for ${HOST}" >> $LOGFILE
  else 
    DEBUG echo "Saturday Night Madness - Something went wrong!!!!!" >> $LOGFILE
    send_mail "Saturday Night Madness - Something went wrong!!!!!"
    exit 1
  fi

done

#######
# Resources
# http://stackoverflow.com/questions/6842683/how-to-set-downtime-for-any-specific-nagios-host-for-certain-time-from-commandlin
# CGI Defintions: http://docs.icinga.org/latest/en/cgiparams.html

