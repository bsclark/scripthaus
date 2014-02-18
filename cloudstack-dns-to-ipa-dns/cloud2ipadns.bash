#!/bin/bash
#
# From orig clouddns.sh, by uknown
#     ?D. Jackson - Tendril?
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
BASE=/root/bin
LOGS=$BASE/csdns-log
FILETMP=$LOGS/vm-name.txt
FILETMP2=$LOGS/ipaddress.txt
VMFILE=$LOGS/vmfile.txt
CLOUDAPISCRIPT=$BASE/get-api-cloudstack.bash
ADMINUSERP=`cat $BASE/.dnsonly`

# Replace/Update with valid values
DNSSERVER='<dns server>'
DNSDOMAIN='<DNS Domain name>'
EMAIL_USERS='<some email address>'
ADMINUSER='<IPA user allowed to update, delete, add, query IPA DNS>'

# Basic email function
send_mail ()
{
  for USER in $EMAIL_USERS
  do
    echo $1 | mailx -s "ERROR Aquriring New/Updated DNS from Cloudstack" $USER
  done
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
CMDS="xmlstarlet $CLOUDAPISCRIPT mailx"
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
# Extract current list of vms and thier IPs
DOMAINLIST=`$CLOUDAPISCRIPT command=listDomains listall=true`
for DOMAIN in `echo $DOMAINLIST| sed -e 's/\<domain\>/\n/g' | grep id |cut -f 3 -d ">" |cut -f 1 -d "<"`
do
  CLOUDDATA=`$CLOUDAPISCRIPT command=listVirtualMachines domainid=$DOMAIN details=nics`
  echo $CLOUDDATA|xmlstarlet sel -T -t -m '///name' -v '.' -n > $FILETMP
  echo $CLOUDDATA|xmlstarlet sel -T -t -m '///ipaddress' -v '.' -n > $FILETMP2
done

paste -d "," $FILETMP $FILETMP2 > $VMFILE

for list in `cat $VMFILE`
do
  VMHOSTNAME=`echo $list|awk -F',' '{ print $1 }'`
  VMIP=`echo $list|awk -F',' '{ print $2 }'`

  LOOKUP=`host $VMHOSTNAME.$DNSDOMAIN $DNSSERVER|grep address|awk '{ print $4 }'`

  if [ -z $LOOKUP ]; then
    LOOKUP=EMPTY
  fi

  if [ "$VMIP" == $LOOKUP ]; then
    echo "NoNeedToAddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
  elif [ $LOOKUP == "EMPTY" ]; then 
    if [ $VMHOSTNAME != "default" ]; then
      echo "AddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
      ipa dnsrecord-add $DNSDOMAIN $VMHOSTNAME --a-rec $VMIP --a-create-reverse
    fi
  elif [ $VMIP != $LOOKUP ]; then
    echo "UpdateNeededForIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
    # The idea here is to find what DNS is currently set to, 
    # remove it and add the correct DNS entry.
    OLDVMIP=`ipa dnsrecord-find $DNSDOMAIN $VMHOSTNAME --all|grep "A record:"|awk '{ print $3 }'`
    REVOLDVMIP=`echo $OLDVMIP|awk -F"." '{for(i=NF;i>0;i--) printf i!=1?$i".":"%s",$i}'`
    THREEOCTET=`echo $REVOLDVMIP|echo $REVOLDVMIP|awk -F"." '{ print $2"."$3"."$4 }'`
    ONEOCTET=`echo $REVOLDVMIP|echo $REVOLDVMIP|awk -F"." '{ print $1 }'`
    echo "RemoveIt : $VMHOSTNAME.$DNSDOMAIN  $OLDVMIP"
    ipa dnsrecord-del $DNSDOMAIN $VMHOSTNAME --a-rec $OLDVMIP
    ipa dnsrecord-del $THREEOCTET.in-addr.arpa. $ONEOCTET --ptr-rec $VMHOSTNAME.$DNSDOMAIN
    ipa dnsrecord-add $DNSDOMAIN $VMHOSTNAME --a-rec $VMIP --a-create-reverse
    echo "AddIt : $VMHOSTNAME.$DNSDOMAIN  $VMIP"
  else
    echo "!!!!Something Broke!!!!!"
    send_mail "DNS Adds/Updates not taking place from CS to IPA."
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
#
