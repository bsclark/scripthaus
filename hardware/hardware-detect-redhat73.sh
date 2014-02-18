#!/bin/sh
#
#  Number of CPUs
NUM_CPU=`cat /proc/cpuinfo | grep -c '^processor'`
#
#  Speed of CPUs
CPU_SPEED=`cat /proc/cpuinfo | grep '^cpu MHz' | awk '{s+=$4} END { print s }'`
#
#  Uptime
UPTIME=`uptime|grep days|sed 's/.*up \([0-9]*\) day.*/\1/'`
#
#  Load
LOAD=`cat /proc/loadavg | cut -d " "  -f 3`
#
#  Disk Space 
DISK_SPACE=`df -P -k  | grep '^/dev/' | awk ' { s+= $2  } END { print s }'`
#
#  Disk Space Used
DISK_USED=`df -P -k  | grep '^/dev/' | awk ' { s+= $3  } END { print s }'`
#
#  Type of disk
DISK_TYPE=`df -P -k  | grep '^/dev/' | awk ' { if ($1 ~ "/dev/(ide|hd|fd|cd)") { s+=1 } else if ($1 ~ "/dev/(scsi|sd|cciss|ida|md)") { s+= 2 } else { s+= 3 } } END { print s }'`
#
#  Number of Mounts
MOUNTS=`wc -l /proc/mounts | cut -d " " -f 1`
#
#  Memory
MEMORY=`free|grep '^Mem'|awk '{print $2 }'`
#
#  Swap
SWAP=`free|grep '^Swap'|awk '{print $2 }'`
#
#  Free memory
FREE_MEMORY=`free|grep '^Mem'|awk '{print $2 }'`
#
#  Number of network interfaces
NUM_INTERFACES=`/sbin/ifconfig -a | grep -c '\baddr:'`
#
#  Bytes Transfered
TRANSFER=`cat /proc/net/dev | grep : | grep -v '^ *lo:' | sed 's/^.*://' | awk '{ printf("%s+%s-%s-%s+",$1,$9,$3,$11)  } END { printf("0\n")}' | bc`


echo NUM_CPU:        $NUM_CPU
echo CPU_SPEED:      $CPU_SPEED
echo UPTIME:         $UPTIME
echo LOAD:           $LOAD
echo DISK_SPACE:     $DISK_SPACE
echo DISK_USED:      $DISK_USED
echo DISK_TYPE:      $DISK_TYPE
echo MOUNTS:         $MOUNTS
echo MEMORY:         $MEMORY
echo SWAP:           $SWAP
echo FREE_MEMORY:    $FREE_MEMORY
echo NUM_INTERFACES: $NUM_INTERFACES
echo TRANSFER:       $TRANSFER
