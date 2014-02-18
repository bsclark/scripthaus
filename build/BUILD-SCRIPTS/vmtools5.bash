#!/bin/bash
#
# To detect if kicksarted server is a virtual running on ESXi or not.
# If so, install vmtools, if not then dont.

SCAN_OUTPUT=`lspci|grep -i vmware|wc -l`

if [ $SCAN_OUTPUT -eq 0 ]; then
  echo "no vmware here"
else
  echo "vmware found"
  cd /etc/yum.repos.d/
  wget http://<server addr>/YUM-REPO-FILES/5/vmtools.repo
  cd /root
  yum -y install vmware-tools-esx-kmods vmware-tools-esx-nox
fi

