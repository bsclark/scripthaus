#!/bin/bash
#

HOSTNAME=`hostname`
VERSION=`cat /proc/version`
DATE=`date`
OUT="/tmp/$HOSTNAME-info.txt"

#echo -n "Customer? "; 		read CUSTOMER
#echo -n "Manufacturer? ";     read MANUFACTURER
#echo -n "Model? ";		read MODEL
#echo -n "Serial #? ";		read SERIAL

PMODEL=`cat /proc/cpuinfo | grep vendor_id | awk -F\: '{print $2}'`
PNAME=`cat /proc/cpuinfo  | grep model | awk -F\: '{print $2}'`
PSPEED=`cat /proc/cpuinfo | grep MHz | awk -F\: '{print $2}' | awk -F\. '{print $1}'`

if [ -z ${PSPEED} ]
then
	PSPEED=`cat /proc/cpuinfo | grep mips | awk -F\: '{print $2}' | awk -F\. '{print $1}'`
fi

RAM=`cat /proc/meminfo | grep MemTotal | awk -F\: '{print $2}' | awk -F\  '{print $1 " " $2}'`

echo "System Information - $HOSTNAME" 		> $OUT 
echo "$HOSTNAME" 			>> $OUT
echo "$DATE" 			>> $OUT
#echo "Hardware Manufacturer:  $MANUFACTURER" 			>> $OUT
#echo "Machine Model........:  $MODEL"           		>> $OUT
#echo "System Serial Number :  $SERIAL"				>> $OUT
echo "System Specifics.....:  $PMODEL $PNAME, $PSPEED MHz"	>> $OUT
echo "                        $RAM RAM"         		>> $OUT
echo "Operating System.....:  $VERSION"         		>> $OUT

echo "I/O Ports" 		>> $OUT
cat /proc/ioports                                     		>> $OUT

echo "Interrupts" >> $OUT
cat /proc/interrupts                                   >> $OUT

echo "PCI Devices" >> $OUT
cat /proc/pci                                           >> $OUT

echo "SCSI Devices" >> $OUT
cat /proc/scsi/scsi                                      >> $OUT

if [ -e /proc/rd ]
then
	echo "RAID controller found (how cool!)"		>> $OUT
	cat /proc/rd/c*/current_status				>> $OUT
fi
