#!/bin/bash
#
# To determine if a process is running and if not, start it.
PROCESSPID=$(pgrep $1)		# $1 = process name script argument. ex. httpd
MAILTO=email@somedomain.com	# where to send status emails to

if [[ -z "$PROCESSPID" ]]; then
  /sbin/service $1 stop
  sleep 2
  /sbin/service $1 start
  echo "$1 Restarted: Was found not running"|mailx $MAILTO
fi

unset PROCESSPID
