#!/bin/bash
#
# Stuff for every server

# /etc/resolv.conf config
cat > /etc/resolv.conf << RESOLV_EOF
search <dns domainname>
nameserver <dns server ip 1>
nameserver <dns server ip 2>
RESOLV_EOF

# /etc/hosts file cleanup
echo `ifconfig |grep "inet addr"|grep -v 127.0.0.1|awk '{ print $2}'|awk -F":" '{ print $2 }'` `hostname --fqdn` `hostname|awk -F"." '{ print $1}'` >> /etc/hosts

# base NTP config
OSVER=`cat /etc/redhat-release|awk '{ print $1 $3 }'`
if [ $OSVER != "CentOS6.4" ]; then
  echo " " >> /etc/ntp.conf
  echo "server <some ntp server ip>" >> /etc/ntp.conf
else
  sed -i 's/server 0.centos.pool.ntp.org/server <some ntp server ip>/g' /etc/ntp.conf
  sed -i 's/server 1.centos.pool.ntp.org/server <some ntp server ip>/g' /etc/ntp.conf
  sed -i 's/server [2-3].centos.pool.ntp.org//g' /etc/ntp.conf
fi

# base sudoers config
echo " " >> /etc/sudoers
echo "%sysadmins     ALL=(ALL)      NOPASSWD: ALL" >>  /etc/sudoers

# Append some history to root
echo "ipa-client-install --mkhomedir" >> /root/.bash_history

# Add timestamp and history size for all users
sed -i 's/HISTSIZE=1000/\nHISTSIZE=1000\nHISTFILESIZE=10000\nHISTTIMEFORMAT="%F %T "\n/g' /etc/profile

sed -i 's/export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL/export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL HISTTIMEFORMAT HISTFILESIZE/g' /etc/profile

# postfix config
sed -i "s/\#relayhost = \$mydomain/relayhost = <mail relay server name>/g" /etc/postfix/main.cf
service postfix restart

# Required for inital puppet run to work
sed -i "s/ssldir = \$vardir\/ssl/ssldir = \$vardir\/ssl\n\n    pluginsync=true\n    factpath = \$vardir\/lib\/facter/" /etc/puppet/puppet.conf
