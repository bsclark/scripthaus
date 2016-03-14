#!/usr/local/bin/bash
#
# Creates a skeleton dir structure and basic files 
# for a New Ansible Role

BASEPATH=$HOME/GitWork/ansible-playbooks
BASEROLEPATH=$BASEPATH/roles
ROLENAME=$1
ROLEPATH=$BASEROLEPATH/$1

if [ $BASH_VERSINFO -lt 4 ]; then
  echo "This script requires BASH 4+ as it uses advanced here-doc features."
  exit
fi

if [[ $# -eq 0 ]] ; then
    echo 'Please pass role name'
    exit 0
fi

# Determine if Role with that same name already exists
if [ "$(ls -A $ROLEPATH )" ]; then
     echo "CANCELING: Role with the name already exists!!!"
     break
else
  # Create Dir Structure
  for file in defaults files handlers tasks templates vars
  do
    mkdir -p $ROLEPATH/$file
  done

  ## Create generic files
  # Main Role yaml
  cat > $ROLEPATH/../../$ROLENAME.yml << ROLE_EOF
---
- hosts: "{{ hosts_group | default('${ROLENAME}') }}"
  remote_user: "{{ remote_user | default('centos') }}"
  sudo: yes
  roles:
  - { role: ${ROLENAME} }
ROLE_EOF

  # README.md
  cat > $ROLEPATH/README.md << README_EOF
${ROLENAME^} 
======
# Role Purpose:

## Example command:
\`\`\`bash
ansible-playbook ${ROLENAME}.yml -vvvv -i production --ask-vault-pass --ask-sudo-pass --extra-vars "ansible_ssh_user=someuser"
\`\`\`

##References:
**this is bold**
* bullet 1
* bullet 2

https://help.github.com/articles/github-flavored-markdown/

README_EOF

  # Default Main yaml
  cat > $ROLEPATH/defaults/main.yml << DEFAULTMAIN_EOF
---
# defaults file
emailAddrToSendTo: someone@somewhere.com.lost
DEFAULTMAIN_EOF

  # Files generic repo file
  cat > $ROLEPATH/files/$ROLENAME.repo << REPOFILE_EOF
# This should be moved to ../../../repofiles/
[${ROLENAME}]
name = ${ROLENAME^}
baseurl = http://clone-repo.server.local/${ROLENAME}/
enabled=1
gpgcheck=0
REPOFILE_EOF

  # Handlers Main yaml
  cat > $ROLEPATH/handlers/main.yml << HANDLERS_EOF
---
- name: restart_service
  service: name=${ROLENAME} state=restarted

- name: enable_at_boot
  service: name=${ROLENAME} enabled=yes state=started
HANDLERS_EOF

  # Role Tasks Main yaml
  cat > $ROLEPATH/tasks/main.yml << TASKSMAIN_EOF
---
- include: RedHat.yml
  when: ansible_os_family == "RedHat"
  tags: ${ROLENAME}
TASKSMAIN_EOF

  # Role RedHat yaml
  cat > $ROLEPATH/tasks/RedHat.yml << REDHAT_EOF
---
#- name: Setup ${ROLENAME} repo
#  copy: src=../../../repofiles/${ROLENAME}.repo dest=/etc/yum.repos.d/${ROLENAME}.repo owner=root group=root mode=0644
#  when: ansible_distribution_major_version >= "7"
#  tags: ${ROLENAME}

#- name: 'Installs ${ROLENAME} via yum'
#  yum: name={{ item }} state=latest
#  with_items:
#    - ${ROLENAME}
#  tags: ${ROLENAME}
  
#- name: 'Create ${ROLENAME} config files'
#  copy: src=../files/${ROLENAME}.conf dest=/somepath/${ROLENAME}.conf owner=someid group=somegrp mode=0644
#  notify: enable_at_boot
#  tags: ${ROLENAME}

#- name: 'Send Email to Team on what to do next or status, etc.'
#  local_action:
#    module: mail
#    to: "{{ email_addr_to_send_to }}"
#    from: someone@somehwere.com.lost
#    subject: "{{ ansible_hostname }} some subject"
#    body: '{{ lookup("template", "../templates/email.txt.j2") }}'
#  tags: 
#    - ${ROLENAME}
#    - email
REDHAT_EOF

  # Example DataDog API Usage
  cat > $ROLEPATH/tasks/datadog.yml << DATADOG_EOF
---  
#  - name: 'Get DataDog keys'
#    include_vars: ../../../vault/datadog-api.yml
#  - name: 'Mute host forever in Datadog'
#    uri:
#      url: "https://app.datadoghq.com/api/v1/host/{{ ansible_fqdn }}/mute?api_key={{ datadog_api_key }}&application_key={{ datadog_app_key }}"
#      method: POST
#      HEADER_Content-Type: "application/json"
#      body: "{\"message\": \"Muting host\"}"
#      return_content: yes
#    delegate_to: localhost
DATADOG_EOF  

  # Example EC2 Tags 
  cat > $ROLEPATH/tasks/ec2_tags.yml << ECTAGS_EOF
---
# Add tag after power down
#  - name: 'Gather EC2 instance info'  
#     action: ec2_facts
#  - name: 'Get AWS Creds'
#    include_vars: ./vault/AWS-Tower-Creds-{{ ec2_tag_env }}.yml    
#  - name: 'Set EC2 Tags'
#    ec2_tag:
#      resource: "{{ ansible_ec2_instance_id }}"
#      region: "{{ region | default('us-east-1') }}"
#      state: present
#      aws_access_key: "{{ AWS_ACCESS_KEY }}"
#      aws_secret_key: "{{ AWS_SECRET_KEY }}"
#      tags: 
#        ansible: false
#        powered_down_by: "{{ email_addr_to_send_to }}"
#        powered_down_date: "{{ ansible_date_time.date }}"
ECTAGS_EOF  

  # Vars Main yaml
  cat > $ROLEPATH/vars/main.yml << VARSMAIN_EOF
---
empty: true
VARSMAIN_EOF

  # Role Template email example yaml
  cat > $ROLEPATH/templates/email.txt.j2 << TEMPEMAIL_EOF
Some text for the body of the email.

Will output the body as its written in this file.

You can iclude ansbile variables thusly:
Hostname is {{ ansible_hostname }}
TEMPEMAIL_EOF

cat >> $BASEPATH/README.md << MAINREADME_EOF

${ROLENAME^}
-------------
[${ROLENAME^}](roles/${ROLENAME}/README.md)

MAINREADME_EOF

fi
