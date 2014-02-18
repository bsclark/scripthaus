#!/bin/bash
#
# Puppet NPRE config (rpm way)

# Nagios NRPE config
sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,dpu-inf-mon01/g" /etc/nagios/nrpe.cfg
sed -i "s/dont_blame_nrpe=0/dont_blame_nrpe=1/g" /etc/nagios/nrpe.cfg
sed -i "s/debug=0/debug=1/g" /etc/nagios/nrpe.cfg

sed -i '/command\[check_total_procs\]/a command[check_root]=\/usr\/lib64\/nagios\/plugins\/check_disk -w 20% -c 10% -p \/' /etc/nagios/nrpe.cfg
sed -i '/command\[check_root\]/a command[check_swap]=\/usr\/lib64\/nagios\/plugins\/check_swap -w 20 -c 10 ' /etc/nagios/nrpe.cfg

service nrpe start
chkconfig nrpe on

