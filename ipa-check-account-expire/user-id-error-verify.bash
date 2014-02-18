#! /bin/bash
# 
# Script to read the latest error file
# and allows selection of users to 
# send email to asking if they 
# still need the account and/or to 
# set a password.

# User ID Log files
LOG_DIR=/root/bin/logs
ERROR_LOG_FILE=`ls -ltr $LOG_DIR/passwd-expire-error.log.*|tail -1|awk '{ print $9 }'`
REPLYEMAIL="<some email>"
DOMAINNAME="<somedomain>"

# Verify dir we expect to be there are
if [ ! -d $LOG_DIR ]; then
  echo "Creating log directory $LOG_DIR"
  mkdir -p $LOG_DIR
  if [ $? != 0 ]; then
    sendemail "Error creating directory $LOG_DIR"
    exit 1
  fi
fi

menu() {
    clear
    echo "Avaliable options:"
    for i in ${!options[@]}; do 
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
}

sendemail() {
  for sei in "${SELECTED_USER[@]}"; do
    mailx -r $REPLYEMAIL -s "Account Disabling Notice" ${sei}@$DOMAINNAME << ENDOFEMAIL
Your account currently has no password OR the password has not been
changed since the last time an administrator reset your password.

Please change your password to avoid the account being disabled.

If you no longer need the account, please let suppoty know it is no longer
needed.
ENDOFEMAIL
  done
}

# read file into array
# options=("AAA" "BBB" "CCC" "DDD")
old_IFS=$IFS				# need to keep track of this to reset it after read
IFS=$'\n'					# set new on for the read
options=($(awk -F':' '{ print $1 }' $ERROR_LOG_FILE))  	# read file into array... yeah!
IFS=$old_IFS				# set it back

# The actual menu on screen
prompt="Check a User ID (again to uncheck, ENTER when done): "
while menu && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] && (( num > 0 && num <= ${#options[@]} )) || {
        msg="Invalid option: $num"; continue
    }
    ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
done

for i in ${!options[@]}; do 
    [[ "${choices[i]}" ]] && { SELECTED_USER+=("${options[i]}"); }
done

clear

echo "You selected these User IDs:"
for user in "${SELECTED_USER[@]}"; do
  echo "${user}"
done

echo ""
echo "Do you want to send an email to each of these User IDs asking about account status? [y/n]: "

read USER_CONFIRM

case $USER_CONFIRM in
  y)
    sendemail
    ;;
  n)
    echo "Exiting w/o doing anything per user input"
    ;;
  *)
    echo "Invalid input"
    ;;
esac

