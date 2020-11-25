#!/bin/bash

netq bootstrap reset

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

netplan apply

netq bootstrap master interface eth0 tarball s3://netq-archives/latest/netq-bootstrap-3.2.1.tgz > /dev/null 2>&1

netq install opta standalone full interface eth0 bundle s3://netq-archives/latest/NetQ-3.2.1-opta.tgz config-key CMScARImZ3cuYWlyZGV2MS5uZXRxZGV2LmN1bXVsdXNuZXR3b3Jrcy5jb20YuwM=
