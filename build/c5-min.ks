# Kickstart file automatically generated by anaconda.

#version=08MAR2013 BSC
install
text
skipx
reboot
url --url=http://<server addr>/centos/5/os/
lang en_US.UTF-8
keyboard us

rootpw  --iscrypted <some encrypted password>

firewall --disabled
selinux --disabled

timezone --utc Etc/GMT

zerombr

bootloader --location=mbr --driveorder=sda --append="crashkernel=auto rhgb quiet"

clearpart --all --drives=sda

part /boot --fstype=ext3 --size=200
part pv.01 --grow --size=1

volgroup vg_root --pesize=4096 pv.01
logvol / --fstype=ext3 --name=lv_root --vgname=vg_root --grow --size=1024 --maxsize=8192
logvol /home --fstype=ext3 --name=lv_home --vgname=vg_root --grow --size=2048 --maxsize=2048
logvol /opt --fstype=ext3 --name=lv_opt --vgname=vg_root --grow --size=1024 --maxsize=1024
logvol /var/crash --fstype=ext3 --name=lv_var_crash --vgname=vg_root --grow --size=1024 --maxsize=1024
logvol swap --name=lv_swap --vgname=vg_root --grow --size=4032 --maxsize=4032

services --enabled=network,ntpd

repo --name="updates"  --baseurl=http://<server addr>/centos/5/updates/
repo --name="epel5" --baseurl=http://<server addr>/epel5/

%packages --nobase
@Core
dhclient
ipa-client
ntp
net-snmp
telnet
sysstat
yum-utils
yum-downloadonly
screen
sudo
puppet
sssd
openldap-clients
nrpe
nagios-plugins-nrpe
bind-utils
xinetd
nfs-utils
wget
rkhunter
man
openssh
openssh-clients
openssh-server
kexec-tools
crash
vim-enhanced
pyOpenSSL
postfix
-sendmail
-selinux-policy-targeted
-yum-plugin-security
-iscsi-initiator-utils
-device-mapper-multipath

%post --logfile /root/ks-post.log

chkconfig gpm off

rm -rf /etc/yum.repos.d/CentOS-*.repo

cat > /etc/yum.repos.d/base.repo << REPO_BASE_EOF
[base]
name=base
baseurl=http://<server addr>/centos/5/os/
enabled=1
gpgcheck=0 
REPO_BASE_EOF

cat > /etc/yum.repos.d/updates.repo << REPO_UPDATES_EOF
[updates]
name=updates
baseurl=http://<server addr>/centos/5/updates/
enabled=1
gpgcheck=0
REPO_UPDATES_EOF

cat > /etc/yum.repos.d/epel5.repo << REPO_EPEL5_EOF
[epel5]
name=epel5
baseurl=http://<server addr>/epel5/
enabled=1
gpgcheck=0
REPO_EPEL5_EOF

cat > /etc/resolv.conf << RESOLV_EOF
search <dns domainname>
nameserver <dns server ip 1>
nameserver <dns server ip 2>
RESOLV_EOF

wget http://<server addr>/BUILD-SCRIPTS/common.bash -O - |bash
wget http://<server addr>/BUILD-SCRIPTS/puppet-xinetd.bash -O - |bash
wget http://<server addr>/BUILD-SCRIPTS/vmtools5.bash -O - |bash
