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

apt-get update -qy
apt-get install -qy ntp

systemctl restart networking
systemctl restart dnsmasq
systemctl enable ntp
systemctl start ntp
