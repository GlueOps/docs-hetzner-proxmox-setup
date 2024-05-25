#!/usr/bin/env bash

# Set debconf selections for Postfix
echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
echo "postfix postfix/mailname string ''" | debconf-set-selections

# Install proxmox packages
apt install -y proxmox-ve postfix open-iscsi chrony

#Reomove the debian kernel and update grub
apt remove linux-image-amd64 'linux-image-6.1*' -y
update-grub

#remove OS Prober
apt remove os-prober -y

#If you are not using a license key remove the enterprise repository
rm /etc/apt/sources.list.d/pve-enterprise.list

#Update the system
apt update && apt dist-upgrade -y

#Setup a software defined network
apt install libpve-network-perl frr-pythontools dnsmasq -y
systemctl disable --now dnsmasq

#move the interfaces and back up the old
mv /etc/network/interfaces /etc/network/interfaces.old
mv ~/interfaces /etc/network/interfaces.new

#Reboot to finalize all the changes
sysctl -w kernel.panic=10
reboot now