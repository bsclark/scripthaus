#!/bin/bash
#
# Brent S. Clark
# SECURE Script for running after install of OS.
#
#===============================
# Change /etc/login.defs 
#===============================
cp /etc/login.defs /etc/login.defs.orig

sed 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs | sed 's/PASS_MIN_LEN\t5/PASS_MIN_LEN\t8/' | sed 's/PASS_WARN_AGE\t7/PASS_WARN_AGE\t14/' > /etc/login.defs.build

mv -u /etc/login.defs.build /etc/login.defs

#===============================
# Delete the games user because its not needed and looks bad having it there.
#===============================
userdel -r games

#===============================
# Create some required logfiles and configure PAM
#===============================
touch /var/log/faillog
touch /etc/security/opasswd; chmod 0600 /etc/security/opasswd

cp /etc/pam.d/system-auth-ac /etc/pam.d/system-auth-ac.build

#===============================
# Change sshd config settings 
#===============================
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.build

sed 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config | sed 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' > /etc/ssh/sshd_config.2

echo "HostbasedAuthentication no" >> /etc/ssh/sshd_config.2
echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config.2
echo "# dont allow these users to login via ssh" >> /etc/ssh/sshd_config.2
echo "DenyUsers bin daemon adm lp sync shutdown halt mail news uucp operator gopher ftp nobody vcsa rpm netdump nscd ident sshd rpc rpcuser nfsnobody mailnull smmsp pcap ntp dbus avahi haldaemon gdm xfs sabayon" >> /etc/ssh/sshd_config.2

mv -u /etc/ssh/sshd_config.2 /etc/ssh/sshd_config

service sshd restart

#===============================
# Config logs to rotate every 90 days.
#===============================
cp /etc/logrotate.conf /etc/logrotate.conf.orig

sed 's/rotate 4/rotate 12/' /etc/logrotate.conf | sed 's/    rotate 1/    rotate 4/' > /etc/logrotate.conf.build

mv -u /etc/logrotate.conf.build /etc/logrotate.conf

#===============================
# Turn off unneeded services
#===============================
for file in isdn autofs nfslock cups rhnsd netfs xinetd avahi_daemon avahi_dnsconfd hidd pcscd rpcgssd rpcidmapd atd firstboot ip6tables kudzu mdmonitor portmap smartd gpm sendmail bluetooth apmd acpid cpuspeed atd hplip dhcpd named vsftpd dovecot smb squid
do
chkconfig --levels 0123456 $file off
service $file stop
done

#===============================
# Change sysctl.conf
#===============================
cp /etc/sysctl.conf /etc/sysctl.conf.orig

echo "" >> /etc/sysctl.conf
echo "#Build Settings" >> /etc/sysctl.conf
echo "#" >> /etc/sysctl.conf

#echo "# Enable TCP SYN Cookie Protection " >> /etc/sysctl.conf
#echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf

echo "# Turn off ICMP broadcasts" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf

echo "# Disable ICMP Redirect Acceptance" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf

echo "# Enable bad error message Protection" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf

echo "# Log Spoofed Packets, Source Routed Packets, Redirect Packets" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf

echo "# Disables automatic defragmentation (needed for masquerading, LVS)" >> /etc/sysctl.conf
echo "#net.ipv4.ip_always_defrag = 0" >> /etc/sysctl.conf
echo "# Enable always defragging Protection" >> /etc/sysctl.conf
echo "net.ipv4.ip_always_defrag = 1" >> /etc/sysctl.conf

echo "# Turn off redirects" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf

#===============================
# Change default runlevel to 3
#===============================
cp /etc/inittab /etc/inittab.orig

sed 's/id:5:initdefault:/id:3:initdefault:/' /etc/inittab > /etc/inittab.build

mv -f /etc/inittab.build /etc/inittab

#===============================
# Verify Premissions on certin files. These are the default permissions for these files, this just makes sure they are
#===============================
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
chmod 644 /etc/passwd /etc/group
chmod 400 /etc/shadow /etc/gshadow
chown root:root /etc/crontab
chmod 600 /etc/crontab
chown -R root:root /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d
chmod -R go-rwx /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d
chown root:root /var/spool/cron
chmod -R go-rwx /var/spool/cron
rm -rf /etc/cron.deny
rm -rf /etc/at.deny
echo "root" >> /etc/cron.allow
echo "root" >> /etc/at.allow

#===============================
# Remove services not needed
#===============================
yum erase rsh-server
yum erase rsh
yum erase ypserv
yum erase tftp-server
yum erase anacron
yum erase dhcp
yum erase bind
yum erase vsftpd
yum erase dovecot
yum erase squid
yum erase bluetooth

#===============================
# Kernel hardening
#===============================
cp /etc/modprobe.conf /etc/modprobe.conf.orig
echo "alias net-pf-31 off" >> /etc/modprobe.conf
echo "alias bluetooth off" >> /etc/modprobe.conf

#===============================
# Tweaks
#===============================
echo "#*  *  *  *  *  command to be executed" >> /etc/crontab.root 
echo "#-  -  -  -  -" >> /etc/crontab.root
echo "#|  |  |  |  |" >> /etc/crontab.root
echo "#|  |  |  |  +----- day of week (0 - 6) (Sunday=0)" >> /etc/crontab.root
echo "#|  |  |  +------- month (1 - 12)" >> /etc/crontab.root
echo "#|  |  +--------- day of month (1 - 31)" >> /etc/crontab.root
echo "#|  +----------- hour (0 - 23)" >> /etc/crontab.root
echo "#+------------- min (0 - 59)" >> /etc/crontab.root
echo "#" >> /etc/crontab.root
echo "######################" >> /etc/crontab.root
echo "#   SAR information  #" >> /etc/crontab.root
echo "######################" >> /etc/crontab.root
echo "0 * * * * /usr/lib/sa/sa1 300 20 &" >> /etc/crontab.root
 
