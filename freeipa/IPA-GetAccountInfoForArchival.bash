#!/bin/bash
#
# Gets the uid, gid and title from FREE IPA for a list of users
# Most commonly used to create a report of user ids that are being archived or delted
# Output is delimited with tabs, should be able to cut-n-paste into a spreadsheet or table
#
# Fileds in output
# userid, uid, gid, mail, title


# ENV Vars
_DEBUG="off"        # on/off
CNSEARCH="cn=accounts,dc=<some domain>,dc=com"     # Replace <some domain> with actual domain

function usage() {
cat << EOF
Usage: ${0##*/} <options> -f /path/to/some/file

Where /path/to/some/file contains a list of userids, 1 per line

OPTIONS:
 -d Debug Messages on/off. Defaults to off
 -h Usage/Help

EOF
exit 0
}

# A ':' after an option in the getopts line say the next bit is the argument value
# and is set with 'SOMEVARIABLE="$OPTARG"'
while getopts "f:dh" OPTION_NAME; do
  case $OPTION_NAME in
    d) _DEBUG="on";;
    f) INPUTFILE=$OPTARG;;
    h|*) usage
       exit 0
       ;;
  esac
done

if [ -z "$INPUTFILE" ]; then
  usage
fi

function DEBUG() {
  [ "$_DEBUG" == "on" ] &&  $@
}

for file in `cat $INPUTFILE`
do
  ldapsearch -LL -x -b $CNSEARCH uid=$file uidNumber gidNumber mail title >> $INPUTFILE.tmp
done

awk -F'[:,=]' '/^dn/{line=$3}/^uidNumber/{line=line","$2}/^gidNumber/{line=line","$2}/^mail/{line=line","$2}/^title/{print line=line","$2;}' $INPUTFILE.tmp

rm -rf $INPUTFILE.tmp
