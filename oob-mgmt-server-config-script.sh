#!/bin/bash

cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback
  address 10.2.0.132/32
  address 10.2.0.133/32
  
auto eth0
iface eth0 inet dhcp
    post-up sysctl -w net.ipv6.conf.eth0.accept_ra=2

auto eth1
iface eth1 inet static
    address 192.168.200.1/24
EOT

cat <<EOT > /etc/ansible/ansible.cfg
[defaults]
roles_path = ./roles
host_key_checking = False
pipelining = True
forks = 50
deprecation_warnings = False
jinja2_extensions = jinja2.ext.do
force_handlers = True
retry_files_enabled = False
transport = paramiko
ansible_managed = # Ansible Managed File
# Time the task execution
callback_whitelist = profile_tasks
# Use the YAML callback plugin.
stdout_callback = yaml
# Use the stdout_callback when running ad-hoc commands.
# bin_ansible_callbacks = True
interpreter_python = auto_silent

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOT

apt-get update
apt-get install -qy ntp

systemctl restart networking
systemctl restart dnsmasq
systemctl enable ntp
systemctl start ntp
