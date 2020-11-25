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
    address 10.22.0.1/24
    
auto eth1.1
iface eth1.1 inet static
    address 10.2.0.10/16
        
EOT

# fix dhcpd.conf for second subnet

cat <<EOT > /etc/dhcp/dhcpd.conf

ddns-update-style none;

authoritative;

log-facility local7;

option www-server code 72 = ip-address;
option cumulus-provision-url code 239 = text;

# Create an option namespace called ONIE
# See: https://github.com/opencomputeproject/onie/wiki/Quick-Start-Guide#advanced-dhcp-2-vivsoonie/onie/
option space onie code width 1 length width 1;
# Define the code names and data types within the ONIE namespace
option onie.installer_url code 1 = text;
option onie.updater_url   code 2 = text;
option onie.machine       code 3 = text;
option onie.arch          code 4 = text;
option onie.machine_rev   code 5 = text;
# Package the ONIE namespace into option 125
option space vivso code width 4 length width 1;
option vivso.onie code 42623 = encapsulate onie;
option vivso.iana code 0 = string;
option op125 code 125 = encapsulate vivso;
class "onie-vendor-classes" {
  # Limit the matching to a request we know originated from ONIE
  match if substring(option vendor-class-identifier, 0, 11) = "onie_vendor";
  # Required to use VIVSO
  option vivso.iana 01:01:01;

  ### Example how to match a specific machine type ###
  #if option onie.machine = "" {
  #  option onie.installer_url = "";
  #  option onie.updater_url = "";
  #}
}

# OOB Management subnet
shared-network LOCAL-NET{
subnet 10.22.0.0 netmask 255.255.255.0 {
  range 10.22.0.10 10.22.0.50;
  option domain-name-servers 10.22.0.1;
  option domain-name "simulation";
  default-lease-time 172800;  #2 days
  max-lease-time 345600;      #4 days
  option www-server 10.22.0.1;
  option default-url = "http://10.22.0.1/onie-installer";
  option cumulus-provision-url "http://10.22.0.1/cumulus-ztp";
  option ntp-servers 10.22.0.1;
}
subnet 10.2.0.0 netmask 255.255.0.0 {
  range 10.2.17.200 10.2.17.250;
  option domain-name-servers 10.2.0.133;
  option domain-name "simulation";
  default-lease-time 172800;  #2 days
  max-lease-time 345600;      #4 days
  option www-server 10.2.0.133;
  option default-url = "http://10.2.0.133/onie-installer";
  option cumulus-provision-url "http://10.2.0.133/cumulus-ztp";
  option ntp-servers 10.2.0.133;
  option router 10.2.0.10;
}
}

#include "/etc/dhcp/dhcpd.pools";
include "/etc/dhcp/dhcpd.hosts";
EOT

## remove SOC212 nodes from dhcpd.hosts pool

## add SOC212 nodes group into dhcpd.hosts pool

# install NTP
apt-get update -qy
apt-get install -qy ntp

# restart networking NTP and DNS/DHCP for changes
systemctl restart networking
systemctl restart dnsmasq
systemctl enable ntp
systemctl start ntp
