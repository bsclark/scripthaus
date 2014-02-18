#!/bin/bash
#
# SECURE Script
# Also default post install scrip
# Written by: Brent S. Clark
#
#===============================
# Add /etc/motd
#===============================
echo "**************************************************************************" > /etc/motd
echo " Authorized Use Only" >> /etc/motd
echo " This system is for the use of authorized users only. Users may also be" >> /etc/motd
echo " monitored. Users of this system expressly consent to such monitoring and" >> /etc/motd
echo " are advised that if such monitoring reveals possible criminal activity," >> /etc/motd
echo " security staff may provide the evidence of such monitoring to law" >> /etc/motd
echo " enforcement officials." >> /etc/motd
echo "**************************************************************************" >> /etc/motd

#===============================
# Change /etc/login.defs 
#===============================
cp /etc/login.defs /etc/login.defs.orig

sed 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs | sed 's/PASS_MIN_LEN\t5/PASS_MIN_LEN\t8/' | sed 's/PASS_WARN_AGE\t7/PASS_WARN_AGE\t14/' > /etc/login.defs.build

mv -f /etc/login.defs.build /etc/login.defs

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

echo "" >> /etc/pam.d/system-auth-ac
echo "auth        required      /lib/security/pam_tally.so onerr=fail no_magic_root" >> /etc/pam.d/system-auth-ac
echo "account     required      /lib/security/pam_tally.so deny=3 reset no_magic_root" >> /etc/pam.d/system-auth-ac

sed 's/password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok/password    required      pam_passwdqc.so min=disabled,8,8,8,8 passphrase=0 enforce=users\npassword    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=5/' /etc/pam.d/system-auth-ac > /etc/pam.d/system-auth-ac2

mv -f /etc/pam.d/system-auth-ac2 /etc/pam.d/system-auth-ac

sed -e '/pam_cracklib.so try_first_pass retry=3/d' /etc/pam.d/system-auth-ac > /etc/pam.d/system-auth-ac2

mv -f /etc/pam.d/system-auth-ac2 /etc/pam.d/system-auth-ac

#===============================
# Sleepy time to let folks view the output thus far
#===============================
sleep 5

#===============================
# Change sshd config settings 
#===============================
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.build

sed 's/#PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config | sed 's/#PermitUserEnvironment no/PermitUserEnvironment yes/' > /etc/ssh/sshd_config.2

echo "# dont allow these users to login via ssh" >> /etc/ssh/sshd_config.2
echo "DenyUsers bin daemon adm lp sync shutdown halt mail news uucp operator gopher ftp nobody vcsa rpm netdump nscd ident sshd rpc rpcuser nfsnobody mailnull smmsp pcap ntp dbus avahi haldaemon gdm xfs sabayon" >> /etc/ssh/sshd_config.2

mv -f /etc/ssh/sshd_config.2 /etc/ssh/sshd_config

service sshd restart

#===============================
# Config logs to rotate every 90 days.
#===============================
cp /etc/logrotate.conf /etc/logrotate.conf.orig

sed 's/rotate 4/rotate 12/' /etc/logrotate.conf | sed 's/    rotate 1/    rotate 4/' > /etc/logrotate.conf.build

mv -f /etc/logrotate.conf.build /etc/logrotate.conf

#===============================
# Sleepy time to let folks view the output thus far
#===============================
sleep 5

#===============================
# Turn off unneeded services
#===============================
#isdn xinetd avahi-dnsconfd are not part of the RHEL5 Kickstart so I took them out.
for file in autofs nfslock cups rhnsd avahi-daemon netfs hidd pcscd rpcgssd rpcidmapd atd firstboot ip6tables kudzu mdmonitor portmap smartd gpm sendmail
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
# Add sysadmin group to system
#===============================
groupadd -g 600 sysadmin

#===============================
# Add sysadmin group and some logging to sudoers file
#===============================
cp /etc/sudoers /etc/sudoers.orig

echo "%sysadmin    ALL=(ALL)       ALL" >> /etc/sudoers

sed 's/## Host Aliases/Defaults       syslog=auth\n\n## Host Aliases/' /etc/sudoers| sed 's/Defaults       syslog=auth/Defaults       syslog=auth\nDefaults       log_year, logfile=\/var\/log\/sudo.log/' > /etc/sudoers.build

mv -f /etc/sudoers.build /etc/sudoers

touch /var/log/sudo.log

chmod 0440 /etc/sudoers

#===============================
# NTPD config
#===============================
cp /etc/ntp.conf /etc/ntp.conf.orig

sed 's/server [012].rhel.pool.ntp.org//' /etc/ntp.conf > /etc/ntp.conf.build

mv -f /etc/ntp.conf.build /etc/ntp.conf

echo "server <some ip>" >> /etc/ntp.conf
echo "restrict <some ip> mask 255.255.255.255 nomodify notrap noquery" >> /etc/ntp.conf

service ntpd start

chkconfig --levels 12345 ntpd on

#===============================
# Update default userid owners
#===============================
for file in root bin daemon adm lp sync shutdown halt mail news uucp operator gopher ftp nobody vcsa rpm netdump nscd ident sshd rpc rpcuser nfsnobody mailnull smmsp pcap ntp dbus avahi haldaemon gdm xfs sabayon
do
usermod -c "<purpose of account-responsbile person name-email address>,NOAUTHREQ" $file
done

#===============================
# Sleepy time to let folks view the output thus far
#===============================
sleep 5

#===============================
# Install Nagios Client and Config files
#===============================
yum -y install nagios-nrpe nagios-plugins

mv /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg.orig

iptables -A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 5666 -j ACCEPT

service iptables save

service iptables restart

service nrpe start

chkconfig --levels 2345 nrpe on

#===============================
# Install rootkit hunter and schdule it.
#===============================
yum -y install rkhunter

wget <web server where is lives>/rkh.cron -O /etc/cron.daily/rkh.cron

chmod 755 /etc/cron.daily/rkh.cron

/usr/bin/rkhunter --update

#===============================
# Install ssmtp to replace sendmail and remove sendmaia/procmaill.
#===============================
#yum install sstmp


#===============================
# Stuff to do manually once script is run
#===============================
echo " "
echo " "
echo "=================================================="
echo "Add at least one user to the sysadmin group to allow remote login"
echo "use cmd= adduser -g sysadmin -c '<company name>,<user full name>,<user email>,AUTHREQ' <username>"
echo " "
echo "Change system name and IP if needed"
echo "Add Nagios Server ent