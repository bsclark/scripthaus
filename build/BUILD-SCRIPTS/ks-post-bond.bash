#!/bin/bash
#
# https://thornelabs.net/2013/07/05/linux-kickstart-post-script-to-bond-two-nics.html
# Linux Kickstart POST Script to Bond Two NICs

for i in $(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | grep eth)
do
STATUS=$(ethtool $i | grep 'Link detected' | awk -F: '{print $2}')

if [ $STATUS == 'yes' ]; then
                COUNTER=$((COUNTER+1))

                NIC[$COUNTER]="$i"
fi
done

cat << EOF1 >/etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
IPADDR=$IPADDRESS
NETMASK=$NETMASK
USERCTL=no
BONDING_OPTS="mode=1 miimon=100 primary=${NIC[1]}"
EOF1

cat << EOF2 >>/etc/sysconfig/network-scripts/ifcfg-${NIC[1]}
MASTER=bond0
SLAVE=yes
EOF2

cat << EOF3 >>/etc/sysconfig/network-scripts/ifcfg-${NIC[2]}
MASTER=bond0
SLAVE=yes
EOF3

echo 'alias bond0 bonding' >> /etc/modprobe.conf
