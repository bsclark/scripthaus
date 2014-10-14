#!/bin/bash
#
# collecd config

yum -y install collectd

mv /etc/collectd.conf /etc/collectd.conf.orig

HOSTNAME=`hostname -f`
STATSERVER=<some hostname of graphite server>

cat > /etc/collectd.conf << COLLECTD_EOF
# Config file for collectd(1).
#
# Some plugins need additional configuration and are disabled by default.
# Please read collectd.conf(5) for details.

Hostname "$HOSTNAME"
FQDNLookup true
#BaseDir "/var/lib/collectd"
#PluginDir "/usr/lib/collectd"
#TypesDB "/usr/share/collectd/types.db" "/etc/collectd/my_types.db"
Interval 60
#ReadThreads 5

#LoadPlugin logfile
LoadPlugin syslog
LoadPlugin network

<Plugin "syslog">
  LogLevel "info"
</Plugin>

<Plugin "network">
  Server "$STATSERVER""25826"
</Plugin>

Include "/etc/collectd.d/*.conf"

LoadPlugin cpu
LoadPlugin df
LoadPlugin disk
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
LoadPlugin processes
LoadPlugin swap
LoadPlugin uptime
LoadPlugin vmem

<Plugin vmem>
        Verbose false
</Plugin>
COLLECTD_EOF

chkconfig collectd on
service collectd start
