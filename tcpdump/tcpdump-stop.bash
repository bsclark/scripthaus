#!/bin/bash
#
# kills all tcpdumps on the system.
# should run from cron to stop any tcpdumps started with the start script.

killall -15 tcpdump
