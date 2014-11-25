#!/bin/bash
#
# Script to sanatize a vm to prep it for becoming a template

# Remove the root user’s shell history
truncate -s 0 /root/.bash_history 
unset HISTFILE

# Clean out yum
yum clean all

# Force the logs to rotate
/usr/sbin/logrotate –f /etc/logrotate.conf
/bin/rm –f /var/log/*-???????? /var/log/*.gz

# Clear the audit log & wtmp
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp

# Remove the udev persistent device rules
/bin/rm -f /etc/udev/rules.d/*persistent*.rules

# Remove the traces of the template MAC address and UUIDs
/bin/sed -i ‘/^\(HWADDR\|UUID\)=/d’ /etc/sysconfig/network-scripts/ifcfg-eth0

# Clean /tmp out
/bin/rm –rf /tmp/*
/bin/rm –rf /var/tmp/*

# Remove the SSH host keys
rm -vf \
  /etc/ssh/{ssh_host_dsa_key.pub,ssh_host_dsa_key} \
  /etc/ssh/{ssh_host_rsa_key.pub,ssh_host_rsa_key} \
  /etc/ssh/{ssh_host_key.pub,ssh_host_key} \
  /etc/ssh/{ssh_host_ecdsa_key.pub,ssh_host_ecdsa_key}

# Remove Root SSH files
rm -vf /root/.ssh/*

# set machine hostname to 'changeme'
hostname changeme
sed -i -e "s/^HOSTNAME=.*/HOSTNAME=changeme" /etc/sysconfig/network

# Clean out /etc/hosts 
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.locald" >> /etc/hosts

# Cleanup all the log files
truncate -s 0 \
  /var/log/maillog \
  /var/log/messages \
  /var/log/secure \
  /var/log/spooler \
  /var/log/dracut.log \
  /var/log/lastlog \
  /var/log/wtmp \
  /var/log/cron \

# Uninstal IPA Client
ipa-client-install --uninstall

# Remove any CentOS External Repo files so not to clash with internal repo files
rm -rf /etc/yum.repos.d/CentOS*.repo

# Shutdown
init 0

#########################################
# Sources/Cites:
#########################################
# http://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/
# http://shankerbalan.net/blog/cloudstack-centos-template-cloud-configuration/
