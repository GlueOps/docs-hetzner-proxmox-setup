#!/usr/bin/env bash
read -p "Enter your tailscale auth key: " TAILSCALE_AUTH_KEY

#Set the software defined network
pvesh create /cluster/sdn/zones -type simple -zone zone0 -dhcp dnsmasq -ipam pve
pvesh create /cluster/sdn/vnets -vnet vnet0 -zone zone0
pvesh create /cluster/sdn/vnets/vnet0/subnets --subnet 10.0.0.0/16 --type subnet --dhcp-range start-address=10.0.0.50,end-address=10.0.255.254 --gateway 10.0.0.1 --snat 1
pvesh set /cluster/sdn

#Set up tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=${TAILSCALE_AUTH_KEY}
sudo tailscale set --ssh
