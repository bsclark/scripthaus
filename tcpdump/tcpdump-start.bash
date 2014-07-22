#!/bin/bash
#
# generates PCAP files from tcpdump
# gets for duke

DATER=`date +%F_%R`
WRKDIR=/root/TCPDUMP
OUTFILE=$WRKDIR/tcpdump_out-$DATER.log
PCPFILE=$WRKDIR/duke_tcpdump_$DATER.pcap

ETHNO=eth2
IPTOFILERON="<some ip >"

{

/usr/sbin/tcpdump -S -w $PCPFILE -v -n -i $ETHNO src net $IPTOFILERON/24 

} >> $OUTFILE 2>&1

/usr/bin/bzip2 $OUTFILE

