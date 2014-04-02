#!/bin/bash
#
# From orig clouddns.sh, by Dan Jackson - Tendril
#
#  Script to scrape cloud instance name/ip and build a bind zone
#
#  The script;
#     1) collects active cloud accounts
#     2) gathers running instance names/ip per account
#     3) checks bind nameserver lookup
#     4) creates name record if non-existent
#

# ENV Vars
_DEBUG="off"        # on/off
BASE=/root/bin
LOGS=$BASE/csdns-log
VMFILE=$LOGS/vmfile.txt
CLOUDAPISCRIPT=$BASE/get-api-cloudstack.bash
ADMINUSERP=`cat $BASE/.dnsonly`             # admin user password in file. chmod 600

# Replace/Update with valid values
DNSDOMAIN='<DNS Domain name>'
EMAIL_USERS='<some email address>'
ADMINUSER='<IPA user allowed to update, delete, add, query IPA DNS>'

function usage() {
cat << EOF
Usage: ${0##*/} <options>
OPTIONS:
 -d Debug Messages on/off. Defaults to off"
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
    echo $1 | mailx -s "ERROR Aquriring New/Updated DNS from Cloudstack" $USER
  done
}

function DEBUG() {
  [ "$_DEBUG" == "on" ] &&  $@
}

[ $(whoami) != "root" ] && err "You must be root to run this script"

# Verify dir we expect to be there are
if [ ! -d $LOGS ]; then
  echo "Creating log directory $LOGS"
  mkdir $LOGS
  if [ $? != 0 ]; then
    send_mail "Error creating directory $LOGS"
    exit 1
  fi
fi

# Make sure all required utils are installed
CMDS="xmlstarlet $CLOUDAPISCRIPT"
for i in $CMDS
do
  command -v $i >/dev/null && continue || { echo "ERROR: $i command not found."; exit 1; }
done

echo $ADMINUSERP | kinit $ADMINUSER -l 1m
if [ $? -ne 0 ]; then
  send_mail "kinit failed for $ADMINUSER"
  exit 1
fi

{
rm -rf $VMFILE

DEBUG echo "Extract current list of vms and thier IPs"

DOMAINLIST=`$CLOUDAPISCRIPT command=listDomains listall=true`
for DOMAIN in `echo $DOMAINLIST| sed -e 's/\<domain\>/\n/g' | grep id |cut -f 3 -d ">" |cut -f 1 -d "<"`
do
  DEBUG echo "Get list of VM hostnames"
  DEBUG echo "domainid= $DOMAIN"

  CLOUDDATA=`$CLOUDAPISCRIPT command=listVirtualMachines domainid=$DOMAIN details=nics|xmlstarlet sel -T -t -m '///name' -v '.' -n|grep -v default`
  DEBUG echo "vmname= $CLOUDDATA"

  for VMNAME in $CLOUDDATA
    do
    $CLOUDAPISCRIPT command=listVirtualMachines domainid=$DOMAIN name=$VMNAME details=nics|xmlstarlet sel -T -t -m '///ipaddress' -v '.' -n > $LOGS/$VMNAME
    echo $VMNAME >> $VMFILE
    done
done

for LIST in `cat $VMFILE`
do
  VMHOSTNAME=$LIST
  VMIP=`cat $LOGS/$LIST`
  
  DEBUG echo "vmhostname is " $VMHOSTNAME
  DEBUG echo "vmip is " $VMIP

  if [ ! -z $VMHOSTNAME ]; then 
    LOOKUP=`host $VMHOSTNAME.$DNSDOMAIN|grep -v Using|grep -v Name|grep -v Address|grep -v Aliases|grep -v "^[[:space:]]*$"`
    DEBUG echo "1 lookup is $LOOKUP"
  else 
    LOOKUP="EMPTY"
    DEBUG echo "1 lookup is " $LOOKUP
  fi

  if [ ! -z $VMIP ]; then
    LOOKUPREV=`host $VMIP|grep -v Using|grep -v Name|grep -v Address|grep -v Aliases|grep -v "^[[:space:]]*$"`
    DEBUG echo "1 lookuprev is " $LOOKUPREV
  else
    LOOKUPREV="EMPTY"
    DEBUG echo "1 lookuprev is " $LOOKUPREV
  fi

  if [[ ! $LOOKUP =~ .*"not found".* ]]; then
    LOOKUP=`echo $LOOKUP|awk '{ print $4 }'`
    DEBUG echo "new lookup is " $LOOKUP
  else
    LOOKUP="EMPTY"
    DEBUG echo "new lookup is " $LOOKUP
  fi

  if [[ ! $LOOKUPREV =~ .*"not found".* ]]; then
    LOOKUPREV=`echo $LOOKUPREV|awk -F'.' '{ print $4"."$3"."$2"."$1 }'`
    DEBUG echo "new lookuprev is " $LOOKUPREV
  else
    LOOKUPREV="EMPTY"
    DEBUG echo "new lookuprev is " $LOOKUPREV
  fi

  if [ "$VMIP" == "$LOOKUP" ] && [ "$VMIP" == "$LOOKUPREV" ]; then
    echo "NoNeedToAddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
  elif [ "$LOOKUP" == "EMPTY" ] && [ "$LOOKUPREV" == "EMPTY" ]; then
      if [ ! -z "$VMHOSTNAME" ] && [ ! -z "$VMIP" ]; then
        echo "AddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
        ipa dnsrecord-add $DNSDOMAIN $VMHOSTNAME --a-rec $VMIP --a-create-reverse
      else
        DEBUG echo "VM ($VMHOSTNAME) hostname and/or IP ($VMIP) variable is empty"
      fi
  elif [ "$LOOKUP" != "EMPTY" ] && [ "$LOOKUPREV" != "EMPTY" ] && [ "$LOOKUP" != "$LOOKUPREV" ]; then
    echo "UpdateNeededForIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
    DEBUG echo "lookup hostname is $LOOKUP    ip is $LOOKUPREV"
    # The idea here is to find what DNS is currently set to, 
    # remove it and add the correct DNS entry.
    OLDVMIP=`ipa dnsrecord-find $DNSDOMAIN $VMHOSTNAME --all|grep "A record:"|awk '{ print $3 }'`
    REVOLDVMIP=`echo $OLDVMIP|awk -F"." '{for(i=NF;i>0;i--) printf i!=1?$i".":"%s",$i}'`
    THREEOCTET=`echo $REVOLDVMIP|echo $REVOLDVMIP|awk -F"." '{ print $2"."$3"."$4 }'`
    ONEOCTET=`echo $REVOLDVMIP|echo $REVOLDVMIP|awk -F"." '{ print $1 }'`
    echo "RemoveIt : $VMHOSTNAME.$DNSDOMAIN  $OLDVMIP"
    ipa dnsrecord-del $DNSDOMAIN $VMHOSTNAME --a-rec $OLDVMIP
    ipa dnsrecord-del $THREEOCTET.in-addr.arpa. $ONEOCTET --ptr-rec $VMHOSTNAME.$DNSDOMAIN
    echo "AddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
    ipa dnsrecord-add $DNSDOMAIN $VMHOSTNAME --a-rec $VMIP --a-create-reverse
  elif [ "$LOOKUP" != "EMPTY" ] && [ "$LOOKUP" != "$LOOKUPREV" ]; then
    DEBUG echo "....boom....."
    echo "NoNameinCS-It : $VMHOSTNAME.$DNSDOMAIN  $VMIP doing nothing"
  elif [ "$LOOKUPREV" != "EMPTY" ] && [ "$LOOKUP" != "$LOOKUPREV" ]; then
    DEBUG echo "....destoryed......"
    echo "NoIPinCS-It : $VMHOSTNAME.$DNSDOMAIN  $VMIP doing nothing"
  else
    DEBUG echo "!!!!Something Broke!!!!!"
    DEBUG echo "VM is $VMHOSTNAME   IP is $VMIP  lookup is $LOOKUP    lookuprev is $LOOKUPREV"
    if [ $_DEBUG == "off" ]; then
      send_mail "DNS Adds/Updates not taking place from CS to IPA."
    fi
    exit 1
  fi
done

}| logger -i -s -p user.info -t cloud2ipadns.bash




#######
# Resources
# http://stackoverflow.com/questions/21293364/how-to-parse-xml-using-xmllint-and-store-in-arrays
# http://stackoverflow.com/questions/16959908/native-shell-command-set-to-extract-node-value-from-xml
# http://stackoverflow.com/questions/8568925/get-any-string-between-2-string-and-assign-a-variable-in-bash
# http://www.grymoire.com/Unix/Sed.html#uh-4
# http://stackoverflow.com/questions/16394176/how-to-merge-two-files-consistently-line-by-line
# http://www.cyberciti.biz/tips/debugging-shell-script.html
#

