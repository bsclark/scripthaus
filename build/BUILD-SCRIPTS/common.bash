#!/bin/bash
#
# Stuff for every server

BUILDMAILLIST=<some email to get notified of build status>
REPOSREVER=<some hostname for local repo server>
NTPSERVER1=<some ntp hostname>
NTPSERVER2=<some ntp hostname>

# Ensure some useful utils are installed
yum -y install cdpr lshw sysstat vim-enhanced wget screen telnet unzip

# /etc/resolv.conf config
cat > /etc/resolv.conf << RESOLV_EOF
search <dns domainname>
nameserver <dns server ip 1>
nameserver <dns server ip 2>
RESOLV_EOF

# /etc/hosts file cleanup
if grep -q -i "release 7" /etc/redhat-release; then
  echo "`ifconfig |grep "inet "|grep -v 127.0.0.1|awk '{ print $2}'`" "`hostname --fqdn`" "`hostname|awk -F"." '{ print $1}'`" >> /etc/hosts
else
  echo `ifconfig |grep "inet addr"|grep -v 127.0.0.1|awk '{ print $2}'|awk -F":" '{ print $2 }'` `hostname --fqdn` `hostname|awk -F"." '{ print $1}'` >> /etc/hosts
fi

# base NTP config
if grep -q -i "release 7" /etc/redhat-release || grep -q -i "release 6" /etc/redhat-release || grep -q -i "release 5" /etc/redhat-release; then
  sed -i "s/server 0.centos.pool.ntp.org/server $NTPSERVER1/g" /etc/ntp.conf
  sed -i "s/server 1.centos.pool.ntp.org/server $NTPSERVER2/g" /etc/ntp.conf
  sed -i 's/server [2-3].centos.pool.ntp.org//g' /etc/ntp.conf
else
  echo " " >> /etc/ntp.conf
  echo "server $NTPSERVER1" >> /etc/ntp.conf
fi

# base sudoers config
echo " " >> /etc/sudoers
echo "%sysadmins     ALL=(ALL)      NOPASSWD: ALL" >>  /etc/sudoers

# Append some history to root
echo "ipa-client-install --mkhomedir" >> /root/.bash_history

# Add timestamp and history size for all users
sed -i 's/HISTSIZE=1000/\nHISTSIZE=1000\nHISTFILESIZE=10000\nHISTTIMEFORMAT="%F %T "\nHISTIGNORE="history:exit"\n/g' /etc/profile

sed -i 's/export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL/export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL HISTTIMEFORMAT HISTFILESIZE HISTIGNORE/g' /etc/profile

# postfix config
sed -i "s/\#relayhost = \$mydomain/relayhost = <mail relay server name>/g" /etc/postfix/main.cf
service postfix restart

# collectd config
wget http://$REPOSREVER/BUILD-SCRIPTS/collectd.bash -O - |bash

# Email Team on New Server and Next Steps
HOSTNAME=`hostname -s`

if grep -q -i "release 7" /etc/redhat-release; then
  HOSTIP=`ifconfig |grep "inet "|grep -v 127.0.0.1|awk '{ print $2}'`
else
  HOSTIP=`ifconfig |grep "inet "|grep -v 127.0.0.1|awk '{ print $2}'|awk -F":" '{ print $2 }'`
fi

HOSTFILE=/usr/local/nagios/etc/objects/hosts/$HOSTNAME.cfg
mailx -s "New Server $HOSTNAME Work Needed" $BUILDMAILLIST  << MAILMSGDOC
Run the following on the Nagios server.

HOSTNAME=$HOSTNAME
HOSTIP=$HOSTIP
HOSTFILE=$HOSTFILE

cp /root/REPLACE-ME.cfg $HOSTFILE

sed -i 's/REPLACE-ME/$HOSTNAME/g' $HOSTFILE
sed -i 's/REPLACE-IP/$HOSTIP/g' $HOSTFILE

service nagios restart

MAILMSGDOC

# Required for inital puppet run to work
sed -i "s/ssldir = \$vardir\/ssl/ssldir = \$vardir\/ssl\n\n    pluginsync=true\n    factpath = \$vardir\/lib\/facter/" /etc/puppet/puppet.conf

# Physical boxes should have cdpr installed automatically via kickstart. cisco discovery protocol

