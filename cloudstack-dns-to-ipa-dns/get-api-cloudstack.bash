#!/usr/bin/env bash
#
# From https://gist.github.com/keithseahus/6201354
# Expanded on
#
# ln get-api-cloudstack.bash ./get-api-cloudstack-i.bash
 
ADDRESS="http://cloudstack.manager.yourdomain.com:8069"
API_KEY="<CS API Key for user>"
SECRET_KEY=`cat .cloudkey`

# you can set up a link called get-api-cloudstack-i.bash to this script to invloke different options
if [ `basename $0` == get-api-cloudstack-i.bash ]; then
  USE_XMLLINT=1 # true => 1, false => 0
else
  USE_XMLLINT=0
fi
 
if [ x$ADDRESS == x ] || [ x$API_KEY == x ] || [ x$SECRET_KEY == x ] || [ x$USE_XMLLINT == x ]; then
  echo 'ERROR: Set all required valiables.'
  exit 1
fi
 
api_path="/client/api?"
if [ $# -lt 1 ]; then
echo "usage: $0 command=... paramter=... parameter=..."; exit;
elif [[ $1 != "command="* ]]; then
echo "usage: $0 command=... paramter=... parameter=..."; exit;
elif [ $1 == "command=" ]; then
echo "usage: $0 command=... paramter=... parameter=..."; exit;
fi
data_array=("$@" "apikey=${API_KEY}")
temp1=$(echo -n ${data_array[@]} | \
tr " " "\n" | \
sort -fd -t'=' | \
perl -pe's/([^-_.~A-Za-z0-9=\s])/sprintf("%%%02X", ord($1))/seg'| \
tr "A-Z" "a-z" | \
tr "\n" "&" )
signature=$(echo -n ${temp1[@]})
signature=${signature%&}
signature=$(echo -n $signature | \
openssl sha1 -binary -hmac $SECRET_KEY | \
openssl base64 )
signature=$(echo -n $signature | \
perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
url=${ADDRESS}${api_path}$(echo -n $@ | tr " " "&")"&"apikey=$API_KEY"&"signature=$signature
 
if [ $USE_XMLLINT -eq 1 ] && [ `type xmllint > /dev/null; echo $?` -eq 0 ]; then
  curl -k ${url} | xmllint --format -
else
  curl -k ${url}
fi
 
exit $?
