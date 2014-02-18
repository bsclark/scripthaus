#!/bin/sh
#
# Startup script for XYZZY
#
# chkconfig: 345 STARTORDER STOPORDER
# description: 
# processname: XYZZY
# pidfile: /var/run/XYZZY.pid


# Source function library.
. /etc/rc.d/init.d/functions

# See how we were called.
case "$1" in
  start)
	echo -n "Starting XYZZY: "
        ##### Commands to start the process running
	echo
	touch /var/lock/subsys/XYZZY
	;;
  stop)
	echo -n "Shutting down XYZZY: "
	killproc XYZZY
	echo
	rm -f /var/lock/subsys/XYZZY
	rm -f /var/run/XYZZY.pid
	;;
  status)
	status XYZZY
	;;
  restart)
	$0 stop
	$0 start
	;;
  *)
	echo "Usage: $0 {start|stop|restart|status}"
	exit 1
esac

exit 0
