import os, sys
from fabric.api import *
from fabric.contrib import files

env.skip_bad_hosts=True
env.timeout=1
env.warn_only=True

#def set_hosts():
#    env.hosts = open('', 'r').readlines()

def temp():
    env.hosts = open('', 'r').readlines()

def run(pkg=None):
   env.warn_only = True
   if pkg is not None:
      env["pkg"] = pkg
   elif pkg is None and env.get("pkg") is None:
      env["pkg"] = prompt("Which package to run? ")
   sudo('%s' % env["pkg"])

#havent tested to see if works
# http://docs.fabfile.org/en/1.4.0/usage/fab.html
def scp(localfile,remotefile,fuser,fgroup,fmod):
    put('')

def cert_crt():
    put('','',use_sudo=True)


def esxirun():
   env.warn_only = True
   run('%s')

def query(pkg=None):
   if pkg is not None:
      env["pkg"] = pkg
   elif pkg is None and env.get("pkg") is None:
      env["pkg"] = prompt("Which package to query? ")
   sudo('rpm -qa | grep -i %s' % env["pkg"])

def install(pkg=None):
   if pkg is not None:
      env["pkg"] = pkg
   elif pkg is None and env.get("pkg") is None:
      env["pkg"] = prompt("Which package to install? ")
   sudo('yum install -y %s' % env["pkg"])

def updates():
   env.warn_only = True
   sudo('yum check-update')

def patch5():
   sudo('yum --disablerepo=* --enablerepo=centos-5.9-updates --exclude=postgres\* --exclude=tendril\* --exclude=glibc\* --exclude=nscd\* --exclude=openssl\*  update -y')

def patch6():
   sudo('yum --disablerepo=* --enablerepo=centos-6.3-updates --exclude=postgres\* --exclude=tendril\* --exclude=glibc\* --exclude=nscd\* --exclude=openssl\*  update -y')

def stage5():
   sudo('yum install yum-downloadonly -y ; yum --disablerepo=* --enablerepo=centos-5.9-updates --exclude=postgres\* --exclude=tendril\* --exclude=glibc\* --exclude=nscd\* --exclude=openssl\* --downloadonly update -y')

def stage6():
   sudo('yum install yum-downloadonly -y ; yum --disablerepo=* --enablerepo=centos-6.3-updates --exclude=postgres\* --exclude=tendril\* --exclude=glibc\* --exclude=nscd\* --exclude=openssl\* --downloadonly update -y')

def rmi386():
  sudo('yum remove pam.i386 mkinitrd.i386 gtk2.i386 -y')

def reboot():
  sudo('init 6')

def uname():
  sudo('uname')

def rkhunter(action):
   env.warn_only = True
   if action == 'log':
      sudo('less /var/log/rkhunter.log')
   elif action == 'update':
      sudo('rkhunter --propupd')
   elif action == 'scan':
      sudo('rkhunter -c -sk')

# http://timconrad.org/display/taci/Fabric+Recipes
def dist_keys():
  """
  Distribute SSH keys to remote hosts
  """
  SSH_KEYFILE="/home/%s/.ssh/id_dsa.pub" % env.user
  AUTH_KEYS="/home/%s/.ssh/authorized_keys" % env.user
  GROUP="sysadmins"
  print "distributing your ssh key to %s" % env.host
  if os.path.exists(SSH_KEYFILE):
    print "%s exists, reading it" % SSH_KEYFILE
    f = open(SSH_KEYFILE, "r")
    key = f.read()
    f.close()
 
    if files.exists(AUTH_KEYS):
      # possible to have 2 keys that are the same for the first 75 chars?
      if files.contains(key[:75], AUTH_KEYS):
        print "your key is already in the remote authorized_keys"
      else:
        print "%s exists, appending your key" % AUTH_KEYS
        files.append(AUTH_KEYS,key)
    else:
      run("mkdir -p /home/%s/.ssh" % env.user)
      run("chown %s:%s /home/%s/.ssh" % (env.user, GROUP, env.user))
      put(SSH_KEYFILE, AUTH_KEYS, mode=0600)
 
    run("chmod 700 /home/%s/.ssh" % env.user)
    run("chmod 600 %s" % AUTH_KEYS)
