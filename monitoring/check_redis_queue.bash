#!/bin/bash
# 
# Check redis resque ques

QUEUES="remote_query user_analytics analytics mailer"

function check_queue {
  QUEUE=$(/usr/local/bin/redis-cli -h $1 llen resque:queue:$2 | /usr/bin/awk -F " " '{print $2}')
  THRESH=1000
  RESPONSE="$2 QUEUED = $QUEUE"

  if [ $QUEUE -lt $THRESH ]; then
    RESPONSE="$RESPONSE|$2 OK"
    echo $RESPONSE
  else
    RESPONSE="$RESPONSE|$2 > $THRESH, Restart of resque is needed to resolve. (mt-rsq)"
    echo $RESPONSE
    exit 2
  fi
}

for qname in $QUEUES
do
  check_queue $1 $qname
done
