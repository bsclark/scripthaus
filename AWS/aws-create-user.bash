#!/bin/bash
#

# This script requires a ini formatted file, located at ~/.aws-create-user.ini
# Ex. ini file format
#
# [profile1]
# aws_profile_to_use="profile1"
# aws_profile_nice_name="Nice Looking Profile1 Name"
# aws_profile_id="numbers and more numbers :)"

# [profile2]
# aws_profile_to_use="profile2"
# aws_profile_nice_name="Nice Looking Profile2 Name"
# aws_profile_id="numbers and more numbers :)"
#
# == 
# The text between the []'s are the profile name to use with this script'
# aws_profile_to_use is the name of the profile you created in your ~/.aws/credentials file
# aws_profile_nice_name is a nice to read name for the AWS account to create the user in
# aws_profile_id is the AWS Account ID where the user will be created


# Default vars
_DEBUG="off"        # on/off
CMDS="aws openssl"  # list of commands that are required to run this script
INI_FILE=~/.aws-create-user.ini


function usage() {
cat << EOF
Usage: ${0##*/} <options>
OPTIONS:
  REQUIRED
   -f Path to bulk input file. Ensure file has onlky one email per line. Will ignore the -u option if set.
   -u Email address of new user. If -f is passed as well, this option will be ignored.
   -p Profile name in INI file to use.
  OPTIONAL
   -a Will create the user(s) as members of the administrator group.
   -d Debug Messages on/off and test run. No user(s) is/are created. Defaults to off".
   -h Usage/Help

Example:
${0##*/} -f /some/dir/path/file_of_users
or
${0##*/} -u bob@someemail.com -a
EOF
exit 0
}

# A ':' after an option in the getopts line say the next bit is the argument value
# and is set with 'SOMEVARIABLE="$OPTARG"'
while getopts "f:u:p:adh" OPTION_NAME; do
  case $OPTION_NAME in
    d) _DEBUG="on";;
    f) FILENAME="$OPTARG";;
    u) USER_NAME="$OPTARG";;
    p) PROFILE="$OPTARG";;
    a) USER_ADMIN_ANSWER="Y";;
    h|*) usage
       exit 0
       ;;
  esac
done

function DEBUG() {
  [ "$_DEBUG" == "on" ] &&  echo $@
}

# Make sure all required utils are installed
for i in $CMDS
do
  command -v $i >/dev/null && continue || { echo "ERROR: $i command not found."; exit 1; }
done

DEBUG "Username Input: ${USER_NAME}"
DEBUG "File Name Input: ${FILENAME}"

# check for vaild arguments
if [ -z "${USER_NAME}" ];then
  if [ -z "${FILENAME}" ]; then
    echo "Required arguments not found"
    usage
  fi  
fi

if [ -z "${PROFILE}" ]; then
    echo "Please specify which profile to use."
    usage
fi

# check to see if FILENAME and USER_NAME are set and if so, ignore USER_NAME
if [ ${FILENAME} ] && [ ${USER_NAME} ]; then
  unset USER_NAME
fi

cfg_parser ()
{
  IFS=$'\n' && ini=( $(<$1) ) # convert to line-array
  ini=( ${ini[*]//;*/} )      # remove comments ;
  ini=( ${ini[*]//\#*/} )     # remove comments #
  ini=( ${ini[*]/\  =/=} )  # remove tabs before =
  ini=( ${ini[*]/=\ /=} )   # remove tabs be =
  ini=( ${ini[*]/\ *=\ /=} )   # remove anything with a space around  =
  ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
  ini=( ${ini[*]/%]/ \(} )    # convert text2function (1)
  ini=( ${ini[*]/=/=\( } )    # convert item to array
  ini=( ${ini[*]/%/ \)} )     # close array parenthesis
  ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
  ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
  ini=( ${ini[*]/%\} \)/\}} ) # remove extra parenthesis
  ini[0]="" # remove first element
  ini[${#ini[*]} + 1]='}'    # add the last brace
  eval "$(echo "${ini[*]}")" # eval the result
}

function CREATE_USER() {
  UN="$1"

  # Generate random password
  USER_PASSWORD=`openssl rand -base64 14`  

  if [ "$_DEBUG" == "on" ]; then
    DEBUG "  aws iam create-user --user-name ${UN} --profile ${aws_profile_to_use}"
    DEBUG "  aws iam add-user-to-group --user-name ${UN} --group-name BasicAWSUser --profile ${aws_profile_to_use}"
    DEBUG "  aws iam create-login-profile --user-name ${UN} --password  ${user_password} --password-reset-required --profile ${aws_profile_to_use}"
    
    # Make admin
    if [[ ${USER_ADMIN_ANSWER} =~ ^[Yy]$ ]]; then
      DEBUG "  aws iam add-user-to-group --user-name ${UN} --group-name Administrators --profile ${aws_profile_to_use}"
    else
      DEBUG "  aws iam add-user-to-group --user-name ${UN} --group-name Developers --profile ${aws_profile_to_use}"
    fi
  else
    aws iam create-user --user-name ${UN} --profile ${aws_profile_to_use}
    aws iam add-user-to-group --user-name ${UN} --group-name BasicAWSUser --profile ${aws_profile_to_use}
    aws iam create-login-profile --user-name ${UN} --password  ${user_password} --password-reset-required --profile ${aws_profile_to_use}

    if [[ ${USER_ADMIN_ANSWER} =~ ^[Yy]$ ]]; then
      aws iam add-user-to-group --user-name ${UN} --group-name Administrators --profile ${aws_profile_to_use}
    else
      aws iam add-user-to-group --user-name ${UN} --group-name Developers --profile ${aws_profile_to_use}  
    fi
  fi

  echo ${USER_PASSWORD}
  echo ""
  echo ""
}

function EMAIL_TEXT() {
  echo "Email Subject: Your AWS ${aws_profile_nice_name} account"
  echo " "
  cat << EMAIL_EOF
I have created your AWS ${aws_profile_nice_name} account. Please goto https://${aws_profile_id}.signin.aws.amazon.com/console 
and login to change your password and add MFA. Once you do both, you will need to log out and back in using MFA before you 
will be able to access anything in the account.

If you prefer, there are directions on how to login, change your password and enable MFA
at <add url of walk through how to change their password and mfa in AWS>.

Your inital/temporary password will be provided by another means.

Please let me know if you have any questions.
EMAIL_EOF
}

if [ ! -f ${INI_FILE} ]; then
  echo "INI File does not exist!! Please create it and try again."
  echo ""
  exit 0

cfg_parser "${INI_FILE}"
cfg.section.${PROFILE}

DEBUG "Profile Input: ${aws_profile_nice_name}"
DEBUG ""

if [ ${FILENAME} ]; then
  if [ ! -f ${FILENAME} ]; then
    echo "File \"${FILENAME}\" does not exist!!"
    echo ""
    exit 0
  else
    for USER_NAME in `cat ${FILENAME}`
    do
      CREATE_USER ${USER_NAME} ${aws_profile_to_use}
    done
  fi  
else
  CREATE_USER ${USER_NAME} ${aws_profile_to_use}
fi

EMAIL_TEXT

# Resources
# https://docs.aws.amazon.com/cli/latest/userguide/cli-services-iam-new-user-group.html
# https://docs.ansible.com/ansible/latest/modules/iam_module.html?highlight=iam
# https://github.com/bsclark/scripthaus
# https://github.com/whereisaaron/get-aws-profile-bash/blob/master/get-aws-profile.sh
