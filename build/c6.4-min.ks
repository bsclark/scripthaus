# Kickstart file automatically generated by anaconda.
# ks=http://name_of_apache_server/myconfig.cfg ip=your.ip.address netmask=yournetmask gateway=yourgateway dns=nameserver1,nameserver2 hostname=yourfqdn bond=bond0:eth0,eth1:mode=802.3ad:miimon:100

#version=08MAR2013 BSC
install
text
skipx
reboot
url --url=http://<server addr>/centos/6.4/os64/
lang en_US.UTF-8
keyboard us

rootpw  --iscrypted <some encrypted password>

firewall --disabled
selinux --disabled

timezone --utc Etc/GMT

zerombr

bootloader --location=mbr --driveorder=sda --append="crashkernel=auto rhgb quiet"

clearpart --all --drives=sda

part /boot --fstype=ext4 --size=200
part pv.01 --grow --size=1

volgroup vg_root --pesize=4096 pv.01
logvol / --fstype=ext4 --name=lv_root --vgname=vg_root --grow --size=1024 --maxsize=8192
logvol /home --fstype=ext4 --name=lv_home --vgname=vg_root --grow --size=2048 --maxsize=2048
logvol /var/log --fstype=ext4 --name=lv_var_log --vgname=vg_root --grow --size=1024 --maxsize=1024
logvol /opt --fstype=ext4 --name=lv_opt --vgname=vg_root --grow --size=1024 --maxsize=1024
logvol /var/crash --fstype=ext4 --name=lv_var_crash --vgname=vg_root --grow --size=1024 --maxsize=1024
logvol swap --name=lv_swap --vgname=vg_root --grow --size=4032 --maxsize=4032

services --enabled=network,ntpd

repo --name="updates64"  --baseurl=http://<server addr>/centos/6.4/updates64/
repo --name="epel6" --baseurl=http://<server addr>/epel6/

%packages --nobase
@Core
dhclient
ipa-client
ntp
net-snmp
telnet
sysstat
yum-utils
yum-plugin-downloadonly
screen
xinetd
sudo
puppet
sssd
openldap-clients
nrpe
nagios-plugins-load
nagios-plugins-disk
nagios-plugins-swap
nagios-plugins-users
nagios-plugins-procs
nfs-utils
bind-utils
wget
rkhunter
man
openssh-clients
kexec-tools
crash
vim-enhanced
-selinux-policy-targeted
-yum-plugin-security
%end

%post --logfile /root/ks-post.log

rm -rf /etc/yum.repos.d/CentOS-*.repo

cat > /etc/yum.repos.d/base.repo << REPO_BASE_EOF
[base64]
name=base64
baseurl=http://<server addr>/centos/6.4/os64/
enabled=1
gpgcheck=0 
REPO_BASE_EOF

cat > /etc/yum.repos.d/updates.repo << REPO_UPDATES_EOF
[updates64]
name=updates64
baseurl=http://<server addr>/centos/6.4/updates64/
enabled=1
gpgcheck=0
REPO_UPDATES_EOF

cat > /etc/yum.repos.d/epel6.repo << REPO_EPEL6_EOF
[epel6]
name=epel6
baseurl=http://<server addr>/epel6/
enabled=1
gpgcheck=0
REPO_EPEL6_EOF

cat > /etc/resolv.conf << RESOLV_EOF
search <dns domainname>
nameserver <dns server ip 1>
nameserver <dns server ip 2>
RESOLV_EOF

mkdir -p /etc/selinux/targeted/logins

wget http://<server addr>/BUILD-SCRIPTS/common.bash -O - |bash
wget http://<server addr>/BUILD-SCRIPTS/puppet-rpm.bash -O - |bash
wget http://<server addr>/BUILD-SCRIPTS/vmtools6.bash -O - |bash

%end
