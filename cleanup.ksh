#!/usr/bin/ksh
##Remove files and directories older than 30 days and owned by you in ~/tmp

#find out who is running this script
user=$(whoami)

#Get list of files to be removed
find ~/tmp/* -user $user -mtime +31 -ls | sort -r > ~/tmp.clean

#sort list of directories into something useable
cat ~/tmp.clean | awk '{print $11}' > ~/tmp.clean1

#Email list of files to be deleted, for accountability
mail -s "Files you have deleted in ~/tmp" $user < ~/tmp.clean1

#Remove files
for i in `cat ~/tmp.clean1`; do
		 rm -ri $i
done

#clean up
rm ~/tmp.clean

#Uncomment the rm line to remove the tmp file.  Uncomment the
#mv line to have a list of the files you have deleted, in case
#someone ever questions what you have remmove.  This is just
#an extra precaution as this list is already mailed to you
#rm ~/tmp.clean1
mv ~/tmp.clean1 ~/tartmp.clean.`date +"%m%d%y"`