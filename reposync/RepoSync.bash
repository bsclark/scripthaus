#!/bin/bash
#
# Reposync and Createrepo UPDATE script
#
# NOTES: Dont need to sync the OS cause once you have it for a 
# version, it doesnt change. In addition, creating the repo for it
# ususally breaks install groups. Lines for OS are included at the 
# bottom, for inclusiveness

# CentOS 6
# [cr] repo isnt on the mirrors anymore
reposync -n -p /opt/repo --config=/etc/reposync.6.conf --repoid=cloudstack
reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=updates
reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=extras
reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=contrib
reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=centosplus
reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=fasttrack
reposync -n -p /opt/repo/ --config=/etc/reposync.6.conf --repoid=epel6
reposync -n -p /opt/repo/ --config=/etc/reposync.6.conf --repoid=theforeman
reposync -n -p /opt/repo/vmtools/esxi5.1/ --config=/etc/reposync.6.conf --repoid=vmtools6

createrepo --update /opt/repo/cloudstack/
createrepo --update /opt/repo/epel6/
createrepo --update /opt/repo/centos/6/updates/
createrepo --update /opt/repo/centos/6/extras/
createrepo --update /opt/repo/centos/6/contrib/
createrepo --update /opt/repo/centos/6/centosplus/
createrepo --update /opt/repo/centos/6/fasttrack/
createrepo --update /opt/repo/theforeman/
createrepo --update /opt/repo/vmtools/esxi5.1/vmtools6/

# CentOS 5
# [fasttrack], [cr] and [contrib] have nothing in them so not bothering
reposync -n -p /opt/repo/centos/5/ --config=/etc/reposync.5.conf --repoid=os
reposync -n -p /opt/repo/centos/5/ --config=/etc/reposync.5.conf --repoid=updates
reposync -n -p /opt/repo/centos/5/ --config=/etc/reposync.5.conf --repoid=extras
reposync -n -p /opt/repo/centos/5/ --config=/etc/reposync.5.conf --repoid=centosplus
reposync -n -p /opt/repo/ --config=/etc/reposync.5.conf --repoid=epel5
reposync -n -p /opt/repo/vmtools/esxi5.1/ --config=/etc/reposync.5.conf --repoid=vmtools5

createrepo -d -s sha1 --update /opt/repo/centos/5/os
createrepo -d -s sha1 --update /opt/repo/centos/5/updates
createrepo -d -s sha1 --update /opt/repo/centos/5/extras
createrepo -d -s sha1 --update /opt/repo/centos/5/centosplus
createrepo -d -s sha1 --update /opt/repo/epel5
createrepo -d -s sha1 --update /opt/repo/vmtools/esxi5.1/vmtools5/


# OS
#reposync -n -p /opt/repo/centos/6/ --config=/etc/reposync.6.conf --repoid=os
#createrepo -g /opt/repo/centos/6/os/repodata/c6-x86_64-comps.xml --update /opt/repo/centos/6/os/

#reposync -n -p /opt/repo/centos/5/ --config=/etc/reposync.5.conf --repoid=os
#createrepo -d -s sha1 --update -g /opt/repo/centos/5/os/repodata/comps.xml /opt/repo/centos/5/os
