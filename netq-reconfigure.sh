#!/bin/bash
## run this script as root: sudo bash ./netq-reconfigure.sh

# reset NetQ server install
netq bootstrap reset

# Overwrite the netplan interface config
cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.22.0.200/16]
      gateway4: 10.22.0.1
      nameservers:
        addresses: [10.2.0.133]
        search: [simulation]
EOT

# appy netplan config changes
netplan apply

# quick netq update
apt update -qy
apt install -qy netq-apps netq-agent
netq config restart agent
netq config restar cli

# bootstrap netq k8s - takes about 5 mins
netq bootstrap master interface eth0 tarball s3://netq-archives/latest/netq-bootstrap-3.2.1.tgz

# install netq with a dummy key - this takes about 30 minutes :(
netq install opta standalone full interface eth0 bundle s3://netq-archives/latest/NetQ-3.2.1-opta.tgz config-key CMScARImZ3cuYWlyZGV2MS5uZXRxZGV2LmN1bXVsdXNuZXR3b3Jrcy5jb20YuwM=

# cleanup the install and bootstrap tarballs just to save disk space
rm /mnt/installables/*
rm /mnt/admin/installables/NetQ-*.tgz
