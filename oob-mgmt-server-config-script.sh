#!/bin/bash

cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

  
auto eth0
iface eth0 inet dhcp
    post-up sysctl -w net.ipv6.conf.eth0.accept_ra=2


auto eth1
iface eth1 inet static
    address 10.22.0.1/24
  
  
auto eth1.1
iface eth1.1 inet static
    address 10.2.0.10/16
    address 10.2.0.132/16
    address 10.2.0.133/16
        
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
  option domain-name-servers 10.2.0.133;
  option domain-name "simulation";
  default-lease-time 172800;  #2 days
  max-lease-time 345600;      #4 days
  option www-server 10.22.0.1;
  option default-url = "http://10.22.0.1/onie-installer";
  option cumulus-provision-url "http://10.22.0.1/cumulus-ztp";
  option ntp-servers 10.2.0.133;
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
}
}

#include "/etc/dhcp/dhcpd.pools";
include "/etc/dhcp/dhcpd.hosts";
include "/etc/dhcp/dhcpd-SOC212.hosts";
EOT

## remove SOC212 nodes from dhcpd.hosts pool that is created automatically
sed -i '/^host SOC212-SPIN01/d' /etc/dhcp/dhcpd.hosts
sed -i '/^host SOC212-SPIN02/d' /etc/dhcp/dhcpd.hosts
sed -i '/^host SOC212-LEAF01/d' /etc/dhcp/dhcpd.hosts
sed -i '/^host SOC212-LEAF02/d' /etc/dhcp/dhcpd.hosts
#

# add a second DHCP group to match ansible inventory
# The "hardware ethernet" address must match the left_mac= setting in topology.dot for eth0
# Hand out same address that will be provisioned in automation and set in inventory/falconv2/hosts file
cat <<EOT > /etc/dhcp/dhcpd-SOC212.hosts
group2 {

  option domain-name-servers 10.2.0.10;
  option domain-name "simulation";
  option routers 10.2.0.10;
  option www-server 10.2.0.10;
  option default-url = "http://10.2.0.10/onie-installer";

host SOC212-SPIN01 {hardware ethernet 44:38:39:22:01:76; fixed-address 10.2.17.232; option host-name "SOC212-SPIN01"; option cumulus-provision-url "http://10.2.0.10/cumulus-ztp";  }

host SOC212-SPIN02 {hardware ethernet 44:38:39:22:01:72; fixed-address 10.2.17.233; option host-name "SOC212-SPIN02"; option cumulus-provision-url "http://10.2.0.10/cumulus-ztp";  }

host SOC212-LEAF01 {hardware ethernet 44:38:39:22:01:70; fixed-address 10.2.17.234; option host-name "SOC212-LEAF01"; option cumulus-provision-url "http://10.2.0.10/cumulus-ztp";  }

host SOC212-LEAF02 {hardware ethernet 44:38:39:22:01:6c; fixed-address 10.2.17.235; option host-name "SOC212-LEAF02"; option cumulus-provision-url "http://10.2.0.10/cumulus-ztp";  }

}#End of static host group

EOT

# install NTP
apt-get update -qy
apt-get install -qy ntp

# restart networking NTP and DNS/DHCP for changes
systemctl restart networking
systemctl restart dnsmasq
systemctl enable ntp
systemctl start ntp
systemctl restart apache2
