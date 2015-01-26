#!/bin/bash
#
# Script to (Dis/En)able Nagios Host & Service Notifications
 
# ENV Vars
_DEBUG="on"		# on/off
DATE_LOG=`date +%F_%H%M`
BASE=/root/bin
LOGDIR=$BASE/saturdaynightmadness
LOGFILE=$LOGDIR/snm-$DATE_LOG.log
HOSTLIST=$LOGDIR/snm-hosts.txt  # one FQDN Hostname per line of systems you want to (dis/en)able notifications on

# Replace/Update with valid values
EMAIL_USERS='<some list to send error email to>'
NAGURL=< URL to nagios server cgi >
USER=< nagios user id >
PASS=< nagios user password >

function usage() {
cat << EOF
Usage: ${0##*/} <options>
OPTIONS:
 -a Alert Cat number
    28 = Enable Notifications, server & all services
    29 = Disable Notifications, server & all services
    22 = Enable Notifications, 1 service only, pass hostname and service name
    23 = Disable Notifications, 1 service only, pass hostname and service name
 -h Hostname to (dis/en)able notifications for
 -s Service Name, ex. HTTPS
 -d Debug Messages on/off. Defaults to on
Example: Turn on Debug Messages
${0##*/} -d
EOF
exit 0
}
# A ':' after an option in the getopts line say the next bit is the argument value
# and is set with 'SOMEVARIABLE="$OPTARG"'
while getopts "a:h:s:d" OPTION_NAME; do
  case $OPTION_NAME in
    a) ALERTCAT="$OPTARG";;
    h) PASSEDHOST="$OPTARG";;
    s) SERVICE="$OPTARG";;
    d) _DEBUG="on";;
    *) usage
       exit 0
       ;;
  esac
done

# Basic email function
send_mail() {
  for USER in $EMAIL_USERS
  do
    echo $1 | mailx -s "ERROR: (Dis/En)able Nagios Host & Service Notifications" $USER
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

# if alert cat was passwd in, set cmdtype to match
if [ ! -z "$ALERTCAT" ]; then
  CMDTYPE=$ALERTCAT
  DEBUG echo ${CMDTYPE} >> $LOGFILE
else
  echo "alertcat issue"
  usage
fi

function die {
  echo $1 >> $LOGFILE; 
  exit 1;
}

if [ -z "$PASSEDHOST" ]; then
  PASSEDHOST=`cat  ${HOSTLIST}`
  DEBUG echo ${PASSEDHOST} >> $LOGFILE
fi  

if [ -z "$SERVICE" ]; then
  BLAS="ahas=1"
else
  BLAS="service=${SERVICE}"
fi

for HOST in ${PASSEDHOST}; do

  DEBUG echo "ATTEMPT: Nagios alert notification change for ${HOST}" >> $LOGFILE

  curl --silent --show-error \
    --data cmd_typ=${CMDTYPE} \
    --data cmd_mod=2 \
    --data host=$HOST \
    --data ${BLAS} \
    --data btnSubmit=Commit \
    --insecure \
    $NAGURL -u "$USER:$PASS" | grep -q "Your command request was successfully submitted to Nagios for processing." || die "Failed to contact nagios";

  DEBUG echo "SUCCESS: Nagios alert notification change for ${HOST}" >> $LOGFILE

done

#######
# Resources
# http://stackoverflow.com/questions/6842683/how-to-set-downtime-for-any-specific-nagios-host-for-certain-time-from-commandlin
# CGI Defintions: http://docs.icinga.org/latest/en/cgiparams.html

