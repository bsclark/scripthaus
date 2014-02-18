#!/bin/bash
#
# Script to determine if an accounts password will expire
# in 15 days or less and send notification of status
# also provides report to NOC for account to focus on

DATE=`date "+%Y-%m-%d"`
DATE_15_EPOCH=`date -d "now" +%s`
DATE_REPORT=`date +%F_%H%M`
DATE_DAY=`date +%d`

LOG_DIR=/root/bin/logs
LOG=$LOG_DIR/passwd-expire.log.$DATE_REPORT
ERROR_LOG=$LOG_DIR/passwd-expire-error.log.$DATE_REPORT

# IPA search string 'cn=accounts,dc=<IPA domain>,dc=com'
LDAPSEARCH='cn=accounts,dc=<IPA domain>,dc=com'

REPLYEMAIL="<some email>"     # email that sent emails reply-to is set to
EMAIL_USERS="<some email>"    # email to send report to & who gets error reports 
DOMAINNAME="<some domain name>"		# email domain name of users

# Basic email function
send_mail ()
{
  for USER in $EMAIL_USERS
  do
    echo $1 | mailx -s "ERROR:" $USER
  done
}


# Verify dir we expect to be there are
if [ ! -d $LOG_DIR ]; then
  echo "Creating log directory $LOG_DIR"
  mkdir -p $LOG_DIR
  if [ $? != 0 ]; then
    send_mail "Error creating directory $LOG_DIR"
    exit 1
  fi
fi

ALL_UIDS=`ldapsearch -LL -x -b $LDAPSEARCH|grep "uid: "|grep -v admin|awk -F": " '{ print $2 }'`

for file in $ALL_UIDS
do
  PASS_EXP_DATE=`ldapsearch -LL -x -b $LDAPSEARCH uid=$file|grep krbPasswordExpiration|awk -F": " '{ print $2 }'|cut -c1-8`

  PASS_EXP_EPOCH=`date -d $PASS_EXP_DATE +%s`

  DAYS_TILL_EXPIRE_DIFF=$((PASS_EXP_EPOCH - DATE_15_EPOCH))
  DAYS_TILL_EXPIRE=$((DAYS_TILL_EXPIRE_DIFF/86400))

  if [ $DAYS_TILL_EXPIRE -le 15 ]; then
    if [ $DAYS_TILL_EXPIRE -lt -60 ]; then
      echo "$file: No Expiration Date EXISTS" >> $ERROR_LOG
    elif [ $DAYS_TILL_EXPIRE -lt 0 ]; then
      TEXT_EMAIL=`echo "$file: Password has not been changed since ID creation or Admin reset"`
      echo $TEXT_EMAIL >> $ERROR_LOG
#      echo $TEXT_EMAIL|mailx -r $REPLYEMAIL -s "Password Expiration Notice" $file@$DOMAINNAME
    else
      DIS_PASS_EXP_DATE=`date -d $PASS_EXP_DATE "+%Y-%m-%d"`
      TEXT_EMAIL=`echo "$file: Password expires on $DIS_PASS_EXP_DATE, which is $DAYS_TILL_EXPIRE days from today ($DATE). \n\nThe easiest way to change your password is to log into a server and run the 'passwd' command. \n\nIf you cannot change your password from a server command line, you can change your password from the web site https://dpu-inf-ldap01.tni01.com. Be sure to click the link \"form-based authentication\". \n\nIf you have any issues, please contact the NOC for further assistance."`
      echo $TEXT_EMAIL >> $LOG
      echo -e $TEXT_EMAIL|mailx -r $REPLYEMAIL -s "Password Expiration Notice" $file@$DOMAINNAME
    fi
  fi
done

if [ -f $ERROR_LOG ]; then
  if [ $DATE_DAY == 1 ] || [ $DATE_DAY == 15 ]; then
    cat $ERROR_LOG|mailx -r $REPLYEMAIL -s "User ID Issue Report" $EMAIL_USERS
  fi
fi

