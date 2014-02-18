#!/usr/bin/ksh
#script to check count and then perform a check on process IDs to verify they are not hung

echo "Count #1 for http processes"
ps -ef |grep -c httpd |grep -v grep
ps -ef |grep httpd |awk '{print $2}' > ~/count.1

sleep 50

echo "Count #2 for http processes"
ps -ef |grep -c httpd |grep -v grep
ps -ef |grep httpd |awk '{print $2}' > ~/count.2

diff ~/count.1 ~/count.2 > ~/proc_diff.txt

echo "Difference between count #1 and count #2.  If you see output then processes are dying and regening.  If you
 see no output processes may be hung"
cat ~/proc_diff.txt