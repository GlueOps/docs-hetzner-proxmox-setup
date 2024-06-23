#!/usr/bin/env bash

#Populate variables to generate /etc/hosts and /etc/network/interfaces files
INTERFACE_PORT=$(ip -br addr | grep 'UP' | grep -v '127.0.0.1' | grep -v '::1/128' | awk '{print $1}')
echo $INTERFACE_PORT


INTERFACE_NAME=$(udevadm info -q property /sys/class/net/$INTERFACE_PORT | grep "ID_NET_NAME_PATH=" | cut -d'=' -f2)
IP_CIDR=$(ip addr show $INTERFACE_PORT | grep "inet\b" | awk '{print $2}')
GATEWAY=$(ip route | grep default | awk '{print $3}')
IP_ADDRESS=$(echo "$IP_CIDR" | cut -d'/' -f1)
CIDR=$(echo "$IP_CIDR" | cut -d'/' -f2)

read -p "Enter the new host name: " NEW_HOSTNAME
CURRENT_HOSTNAME=$(hostname)

#Configure the network /ect/network/interfaces and create backup of old one
cat > ~/interfaces << EOF
auto lo
iface lo inet loopback

iface $INTERFACE_NAME inet manual

auto vmbr0
iface vmbr0 inet static
  address $IP_ADDRESS/$CIDR
  gateway $GATEWAY
  bridge_ports $INTERFACE_NAME
  bridge_stp off
  bridge_fd 0

source /etc/network/interfaces.d/*

EOF

# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts
sed -i "s/\b$CURRENT_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts

# Set the hostname immediately without requiring a reboot
hostnamectl set-hostname "$NEW_HOSTNAME"

#Add Repository 
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

#Add repository Key
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 

#Update system
apt update && apt full-upgrade -y

#Install Proxmox kernel and reboot
apt install proxmox-default-kernel -y
sysctl -w kernel.panic=10
reboot now
